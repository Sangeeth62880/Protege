"""
YouTube Data API Service
Searches for educational videos and retrieves video details.
"""
import os
import httpx
from typing import Optional
from datetime import datetime, timedelta

class YouTubeService:
    """Service for searching YouTube videos."""
    
    BASE_URL = "https://www.googleapis.com/youtube/v3"
    
    def __init__(self, api_key: str, cache_service=None):
        """
        Initialize YouTube service.
        
        Args:
            api_key: YouTube Data API key
            cache_service: Optional cache service for storing results
        """
        if not api_key:
            raise ValueError("YouTube API key is required")
        self.api_key = api_key
        self.cache = cache_service
        print(f"[YOUTUBE] Service initialized")
    
    async def search_videos(
        self,
        query: str,
        max_results: int = 5,
        duration: str = "medium",  # short (<4min), medium (4-20min), long (>20min)
        order: str = "relevance",  # relevance, viewCount, date
        published_after_days: int = 730  # Last 2 years
    ) -> list[dict]:
        """
        Search for videos matching the query.
        
        Args:
            query: Search query
            max_results: Maximum number of results (1-50)
            duration: Video duration filter
            order: Sort order
            published_after_days: Only videos published within this many days
            
        Returns:
            List of video objects with id, title, channel, thumbnail, etc.
        """
        print(f"[YOUTUBE] Searching for: {query}")
        
        # Calculate published_after date
        published_after = (datetime.utcnow() - timedelta(days=published_after_days)).isoformat() + "Z"
        
        params = {
            "key": self.api_key,
            "q": query,
            "part": "snippet",
            "type": "video",
            "maxResults": min(max_results, 50),
            "order": order,
            "videoDuration": duration,
            "publishedAfter": published_after,
            "relevanceLanguage": "en",
            "safeSearch": "strict"
        }
        
        timeout = httpx.Timeout(30.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                response = await client.get(f"{self.BASE_URL}/search", params=params)
                
                if response.status_code != 200:
                    print(f"[YOUTUBE] API error: {response.status_code} - {response.text}")
                    return []
                
                data = response.json()
                videos = []
                
                for item in data.get("items", []):
                    video = {
                        "video_id": item["id"]["videoId"],
                        "title": item["snippet"]["title"],
                        "description": item["snippet"]["description"][:200],
                        "channel_name": item["snippet"]["channelTitle"],
                        "channel_id": item["snippet"]["channelId"],
                        "thumbnail_url": item["snippet"]["thumbnails"]["medium"]["url"],
                        "published_at": item["snippet"]["publishedAt"],
                        "url": f"https://www.youtube.com/watch?v={item['id']['videoId']}"
                    }
                    videos.append(video)
                
                print(f"[YOUTUBE] Found {len(videos)} videos")
                
                # Get video details (duration, views, likes)
                if videos:
                    video_ids = [v["video_id"] for v in videos]
                    details = await self.get_video_details(video_ids)
                    
                    # Merge details into videos
                    details_map = {d["video_id"]: d for d in details}
                    for video in videos:
                        if video["video_id"] in details_map:
                            video.update(details_map[video["video_id"]])
                
                return videos
                
            except httpx.TimeoutException:
                print("[YOUTUBE] Request timed out")
                return []
            except Exception as e:
                print(f"[YOUTUBE] Error: {e}")
                return []
    
    async def get_video_details(self, video_ids: list[str]) -> list[dict]:
        """
        Get detailed information for videos (duration, views, likes).
        
        Args:
            video_ids: List of video IDs (max 50)
            
        Returns:
            List of video details
        """
        if not video_ids:
            return []
        
        params = {
            "key": self.api_key,
            "id": ",".join(video_ids[:50]),
            "part": "contentDetails,statistics"
        }
        
        timeout = httpx.Timeout(30.0)
        
        async with httpx.AsyncClient(timeout=timeout) as client:
            try:
                response = await client.get(f"{self.BASE_URL}/videos", params=params)
                
                if response.status_code != 200:
                    print(f"[YOUTUBE] Details API error: {response.status_code}")
                    return []
                
                data = response.json()
                details = []
                
                for item in data.get("items", []):
                    duration_iso = item["contentDetails"]["duration"]
                    duration_minutes = self._parse_duration(duration_iso)
                    
                    stats = item.get("statistics", {})
                    
                    detail = {
                        "video_id": item["id"],
                        "duration_minutes": duration_minutes,
                        "duration_formatted": self._format_duration(duration_minutes),
                        "view_count": int(stats.get("viewCount", 0)),
                        "like_count": int(stats.get("likeCount", 0)),
                        "comment_count": int(stats.get("commentCount", 0))
                    }
                    details.append(detail)
                
                return details
                
            except Exception as e:
                print(f"[YOUTUBE] Error getting details: {e}")
                return []
    
    def _parse_duration(self, iso_duration: str) -> int:
        """
        Parse ISO 8601 duration (PT1H2M3S) to minutes.
        """
        import re
        
        hours = 0
        minutes = 0
        seconds = 0
        
        hours_match = re.search(r'(\d+)H', iso_duration)
        minutes_match = re.search(r'(\d+)M', iso_duration)
        seconds_match = re.search(r'(\d+)S', iso_duration)
        
        if hours_match:
            hours = int(hours_match.group(1))
        if minutes_match:
            minutes = int(minutes_match.group(1))
        if seconds_match:
            seconds = int(seconds_match.group(1))
        
        total_minutes = hours * 60 + minutes + (1 if seconds >= 30 else 0)
        return max(1, total_minutes)  # At least 1 minute
    
    def _format_duration(self, minutes: int) -> str:
        """Format minutes as human-readable duration."""
        if minutes < 60:
            return f"{minutes} min"
        hours = minutes // 60
        mins = minutes % 60
        if mins == 0:
            return f"{hours} hr"
        return f"{hours} hr {mins} min"
