# Third-Party Servers Specification

## Overview

The "Third-Party Servers" feature allows the application to support RSS feeds for websites that do not natively provide them (e.g., social media platforms, video sharing sites). It achieves this by routing feed requests through configured proxy servers that scrape or convert the target website's content into a standard RSS format.

From the user's perspective, this process is entirely abstracted. They input standard URLs (e.g., `https://example.com/user`), and the app automatically handles the routing if a matching third-party server is configured.

## Server Requirements

To create a compatible third-party server for this application, the server must expose the following three endpoints:

### 1. The Supported Domains List (`/links.txt`)
**Method:** `GET`
**Endpoint:** `/links.txt`
**Response Format:** `text/plain`

This endpoint must return a newline-separated list of root domains that the server is capable of proxying/converting into RSS feeds.

**Example Response:**
```text
youtube.com
twitter.com
x.com
instagram.com
```

*Note: The app will match exact domains as well as subdomains (e.g., `m.youtube.com` will match `youtube.com`).*

### 2. The Feed Proxy Endpoint (`/feed`)
**Method:** `GET`
**Endpoint:** `/feed`
**Query Parameters:**
*   `url` (string): The URL-encoded original link provided by the user.

**Response Format:** `application/rss+xml` (Standard RSS/Atom XML)

When the application detects that a user's requested feed URL matches a domain in the `/links.txt` list, it will silently rewrite the network request to this endpoint.

**Example Request:**
`GET https://your-proxy-server.com/feed?url=https%3A%2F%2Ftwitter.com%2Fsomeuser`

### 3. The Search Endpoint (`/search`)
**Method:** `GET`
**Endpoint:** `/search`
**Query Parameters:**
*   `q` (string): The URL-encoded search query entered by the user.

**Response Format:** `application/rss+xml` (Standard RSS/Atom XML)

This endpoint allows users to search for content directly through the third-party server from within the app. The server should return the search results formatted as a standard RSS feed.

**Example Request:**
`GET https://your-proxy-server.com/search?q=open%20source%20news`

---

## How It Works in the App

### Adding a Server
1. The user navigates to "Third-Party Servers" in the left sidebar and adds a new server URL.
2. The app immediately sends a `GET` request to `<server-url>/links.txt`.
3. The app parses the response and saves the server URL and its supported domains to the local database.

### Abstracted Feed Fetching
1. The user adds a new feed to their library using a standard URL (e.g., `https://youtube.com/channel/123`).
2. Before making the HTTP request to fetch the RSS XML, the app parses the domain (`youtube.com`).
3. The app checks all registered third-party servers to see if `youtube.com` is in their supported domains list.
4. If a match is found, the app constructs a new proxy URL: `<matched-server-url>/feed?url=<original-url>`.
5. The app fetches the feed from the proxy URL but retains the **original URL** in the UI and database. The user never sees the proxy URL.

### Transient Searching
1. The user clicks the Search icon in the main Feeds page.
2. The user selects a specific third-party server from a dropdown and enters a search term.
3. The app fetches `<selected-server-url>/search?q=<term>`.
4. The results are displayed temporarily in the main feed view. These results are not saved to the sidebar database, acting as a transient search interface.