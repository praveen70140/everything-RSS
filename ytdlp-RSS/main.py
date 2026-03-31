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
    """Helper to run yt-dlp and return JSON output with a 30s timeout."""
    user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    cmd = [
        "yt-dlp",
        "--no-warnings",
        "--no-check-certificates",
        "--user-agent", user_agent,
        "--geo-bypass",
        "--no-playlist"
    ] + args
    
    start_time = time.perf_counter()
    try:
        logger.info(f"Executing yt-dlp: {args}")
        # Added timeout to prevent hanging processes
        result = subprocess.run(cmd, capture_output=True, text=True, check=True, timeout=30)
        elapsed = time.perf_counter() - start_time
        logger.info(f"yt-dlp execution took {elapsed:.2f} seconds")
        return json.loads(result.stdout)
    except subprocess.TimeoutExpired:
        logger.error("yt-dlp timed out after 30s")
        raise HTTPException(status_code=504, detail="yt-dlp timed out")
    except subprocess.CalledProcessError as e:
        logger.error(f"yt-dlp failed: {e.stderr}")
        raise HTTPException(status_code=500, detail=f"yt-dlp failed: {e.stderr}")
    except json.JSONDecodeError:
        logger.error("Failed to parse yt-dlp JSON output")
        raise HTTPException(status_code=500, detail="Failed to parse yt-dlp output")

@app.get("/links.txt")
async def get_links():
    """
    Returns a newline-separated list of supported domains for the Third-Party Servers Spec.
    This list includes major platforms supported by yt-dlp.
    """
    domains = [
        "youtube.com",
        "youtu.be"
    ]
    return Response(content="\n".join(domains), media_type="text/plain")

@app.get("/feed")
async def generate_feed(url: str, request: Request):
    if not url:
        raise HTTPException(status_code=400, detail="URL query parameter is required")
    
    # Pre-process URL
    if "x.com" in url:
        url = url.replace("x.com", "twitter.com")
        logger.info(f"Mapped x.com to {url} for better compatibility")
    
    # YouTube optimization: Target /videos to avoid Shorts/Live playlists
    if "youtube.com" in url and "@" in url and not url.endswith("/videos"):
        # Remove trailing slash and add /videos
        url = url.rstrip("/") + "/videos"
        logger.info(f"Appended /videos to YouTube channel URL: {url}")
    
    # 1. Fetch metadata using --flat-playlist for speed
    logger.info(f"Generating feed for: {url}")
    data = run_yt_dlp(["-J", "--flat-playlist", "--playlist-end", "15", url])
    
    # 2. Setup Feed Generator
    fg = FeedGenerator()
    fg.id(url)
    title = data.get("title") or data.get("uploader") or data.get("extractor_key") or "yt-dlp Feed"
    fg.title(title)
    fg.link(href=url, rel="alternate")
    fg.description(data.get("description") or f"RSS feed for {url}")
    
    # Load Media RSS extension for images
    fg.load_extension('media', atom=False, rss=True)

    # 3. Process items
    entries = data.get("entries", [])
    if not entries and "id" in data:
        entries = [data]
    
    logger.info(f"Processing {len(entries)} items for feed")
    for entry in entries:
        if not entry: continue
        
        fe = fg.add_entry()
        
        # ID and Title
        video_id = entry.get("id") or entry.get("url") or "unknown"
        fe.id(video_id)
        fe.title(entry.get("title") or "Untitled Post")
        
        # Handle webpage URL in flat-playlist mode
        webpage_url = entry.get("webpage_url") or entry.get("url")
        if webpage_url and not webpage_url.startswith("http"):
            # Construct standard URLs if only ID is provided
            if "youtube" in (data.get("extractor") or ""):
                webpage_url = f"https://www.youtube.com/watch?v={video_id}"
            elif "twitter" in (data.get("extractor") or ""):
                webpage_url = f"https://twitter.com/i/status/{video_id}"
        
        if not webpage_url:
            webpage_url = url
            
        fe.link(href=webpage_url)
        
        # pubDate
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
            
        # Description
        desc = entry.get("description") or entry.get("title") or "No description."
        fe.description(desc)
        
        # Thumbnails
        thumbnails = entry.get("thumbnails", [])
        if not thumbnails and entry.get("thumbnail"):
            thumbnails = [{"url": entry.get("thumbnail")}]
        
        for thumb in thumbnails:
            if isinstance(thumb, dict) and thumb.get("url"):
                fe.media.content({'url': thumb['url'], 'type': 'image/jpeg', 'medium': 'image'})
        
        # Enclosure (Stream Redirect)
        encoded_src = urllib.parse.quote(webpage_url)
        base_url = str(request.base_url).rstrip('/')
        stream_url = f"{base_url}/stream/{video_id}?src={encoded_src}"
        
        # Default to video/mp4 as we can't check formats in flat mode
        fe.enclosure(stream_url, '0', "video/mp4")

    rss_content = fg.rss_str(pretty=True)
    return Response(content=rss_content, media_type="application/rss+xml")

@app.get("/stream/{video_id}")
async def stream_redirect(video_id: str, src: str):
    if not src:
        raise HTTPException(status_code=400, detail="src query parameter is required")
        
    # Check in-memory cache
    now = time.time()
    if src in stream_cache:
        cached_url, expiry = stream_cache[src]
        if now < expiry:
            logger.info(f"Cache hit for stream: {src}")
            return RedirectResponse(url=cached_url)

    # Resolve direct media URL
    # IMPORTANT: We only fetch the URL. The video is NOT streamed through this server.
    logger.info(f"Resolving direct URL for: {src}")
    cmd = [
        "yt-dlp", 
        "-g", 
        "-f", "best[ext=mp4]/best", 
        "--no-warnings",
        "--user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        src
    ]
    try:
        # 30s timeout to resolve the link
        result = subprocess.run(cmd, capture_output=True, text=True, check=True, timeout=30)
        direct_url = result.stdout.strip().split('\n')[0]
        
        if not direct_url:
             raise HTTPException(status_code=500, detail="Failed to resolve direct URL")
             
        # Cache for 30 minutes
        stream_cache[src] = (direct_url, now + CACHE_DURATION)
        
        logger.info(f"Redirecting client to direct media provider: {direct_url[:50]}...")
        return RedirectResponse(url=direct_url)
    except subprocess.TimeoutExpired:
        logger.error("Link resolution timed out")
        raise HTTPException(status_code=504, detail="Link resolution timed out")
    except subprocess.CalledProcessError as e:
        logger.error(f"yt-dlp stream fetch failed: {e.stderr}")
        raise HTTPException(status_code=500, detail="Failed to resolve media link")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
