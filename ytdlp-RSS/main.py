import json
import subprocess
import time
import urllib.parse
import logging
from datetime import datetime, timezone
from typing import Dict, Tuple

from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import RedirectResponse, Response
from feedgen.feed import FeedGenerator

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger("ytdlp-rss")

app = FastAPI(title="yt-dlp RSS Bridge")

# In-memory cache for stream URLs: {src_url: (direct_url, expiry_timestamp)}
stream_cache: Dict[str, Tuple[str, float]] = {}
CACHE_DURATION = 1800  # 30 minutes

def run_yt_dlp(args: list) -> dict:
    """Helper to run yt-dlp and return JSON output."""
    cmd = ["yt-dlp", "--no-warnings", "--no-check-certificates"] + args
    start_time = time.perf_counter()
    try:
        logger.info(f"Executing yt-dlp with args: {args}")
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        elapsed = time.perf_counter() - start_time
        logger.info(f"yt-dlp execution took {elapsed:.2f} seconds")
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        elapsed = time.perf_counter() - start_time
        logger.error(f"yt-dlp failed after {elapsed:.2f}s: {e.stderr}")
        raise HTTPException(status_code=500, detail=f"yt-dlp failed: {e.stderr}")
    except json.JSONDecodeError:
        logger.error("Failed to parse yt-dlp JSON output")
        raise HTTPException(status_code=500, detail="Failed to parse yt-dlp output")

@app.get("/feed")
async def generate_feed(url: str, request: Request):
    if not url:
        raise HTTPException(status_code=400, detail="URL query parameter is required")
    
    # 1. Fetch metadata. 
    # Reducing limit to 15 as requested to improve speed.
    logger.info(f"Generating feed for: {url}")
    data = run_yt_dlp(["-J", "--playlist-end", "15", url])
    
    # 2. Setup Feed Generator
    fg = FeedGenerator()
    fg.id(url)
    title = data.get("title") or data.get("uploader") or data.get("extractor_key") or "yt-dlp Feed"
    fg.title(title)
    fg.link(href=url, rel="alternate")
    fg.description(data.get("description") or f"RSS feed for {url}")
    
    # Load Media RSS extension for images and extra media info
    fg.load_extension('media', atom=False, rss=True)

    # 3. Process items
    entries = data.get("entries", [])
    if not entries and "id" in data:
        # Handle single video URL
        entries = [data]
    
    logger.info(f"Processing {len(entries)} items for feed")
    for entry in entries:
        if not entry: continue
        
        fe = fg.add_entry()
        
        # Core RSS tags
        video_id = entry.get("id") or "unknown"
        fe.id(video_id)
        fe.title(entry.get("title") or "Untitled")
        
        webpage_url = entry.get("webpage_url") or entry.get("url") or url
        fe.link(href=webpage_url)
        
        # pubDate handling
        ts = entry.get("timestamp") or entry.get("release_timestamp")
        if ts:
            fe.pubDate(datetime.fromtimestamp(ts, tz=timezone.utc))
        elif entry.get("upload_date"):
            try:
                fe.pubDate(datetime.strptime(entry.get("upload_date"), "%Y%m%d").replace(tzinfo=timezone.utc))
            except:
                fe.pubDate(datetime.now(timezone.utc))
        else:
            fe.pubDate(datetime.now(timezone.utc))
            
        # Description (HTML allowed)
        desc = entry.get("description") or "No description."
        fe.description(desc)
        
        # Images (Media RSS)
        thumbnails = entry.get("thumbnails", [])
        if not thumbnails and entry.get("thumbnail"):
            thumbnails = [{"url": entry.get("thumbnail")}]
        
        for thumb in thumbnails:
            if isinstance(thumb, dict) and thumb.get("url"):
                fe.media.content({'url': thumb['url'], 'type': 'image/jpeg', 'medium': 'image'})
        
        # Video/Audio Enclosure
        # Point to the redirect endpoint
        encoded_src = urllib.parse.quote(webpage_url)
        # Use request.base_url to ensure absolute URLs
        base_url = str(request.base_url).rstrip('/')
        stream_url = f"{base_url}/stream/{video_id}?src={encoded_src}"
        
        # Check if it's likely audio or video
        mime_type = "video/mp4"
        if entry.get("vcodec") == "none":
            mime_type = "audio/mpeg"
        
        fe.enclosure(stream_url, '0', mime_type)

    rss_content = fg.rss_str(pretty=True)
    return Response(content=rss_content, media_type="application/rss+xml")

@app.get("/stream/{video_id}")
async def stream_redirect(video_id: str, src: str):
    if not src:
        raise HTTPException(status_code=400, detail="src query parameter is required")
        
    # Check cache
    now = time.time()
    if src in stream_cache:
        cached_url, expiry = stream_cache[src]
        if now < expiry:
            return RedirectResponse(url=cached_url)

    # Resolve direct media URL
    # -g: get direct URL
    # -f: best mp4 or best overall single file
    logger.info(f"Resolving direct URL for: {src}")
    cmd = ["yt-dlp", "-g", "-f", "best[ext=mp4]/best", src]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        direct_url = result.stdout.strip().split('\n')[0]
        
        if not direct_url:
             raise HTTPException(status_code=500, detail="Could not resolve direct media URL")
             
        # Cache for 30 minutes
        stream_cache[src] = (direct_url, now + CACHE_DURATION)
        
        return RedirectResponse(url=direct_url)
    except subprocess.CalledProcessError as e:
        logger.error(f"yt-dlp resolve failed: {e.stderr}")
        raise HTTPException(status_code=500, detail=f"Failed to resolve media URL: {e.stderr}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
