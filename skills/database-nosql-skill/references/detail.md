    return await cursor.to_list(length=per_page)

# Count
async def count_posts():
    return await mongodb.posts.count_documents({"published": True})

# Distinct
async def get_all_tags():
    return await mongodb.posts.distinct("tags")
```

## Complex Queries

```python
# Regex search
async def search_posts(query: str):
    cursor = mongodb.posts.find({
        "$or": [
            {"title": {"$regex": query, "$options": "i"}},
            {"content": {"$regex": query, "$options": "i"}}
        ]
    })
    return await cursor.to_list(length=50)

# Array contains
async def get_posts_by_tag(tag: str):
    return await mongodb.posts.find({"tags": tag}).to_list(length=100)

# Nested field
async def get_users_by_country(country: str):
    return await mongodb.users.find({"address.country": country}).to_list(length=None)
```

## Aggregation

```python
async def get_posts_stats():
    pipeline = [
        {"$match": {"published": True}},
        {"$group": {
            "_id": None,
            "total_posts": {"$sum": 1},
            "avg_views": {"$avg": "$views"}
        }},
        {"$project": {"_id": 0, "total_posts": 1, "avg_views": 1}}
    ]
    result = await mongodb.posts.aggregate(pipeline).to_list(length=1)
    return result[0] if result else None
```

## Redis Setup

```python
import redis
from typing import Optional
import json

class RedisCache:
    def __init__(self):
        self.client = redis.Redis(host='localhost', port=6379, db=0)

    def get(self, key: str) -> Optional[dict]:
        data = self.client.get(key)
        return json.loads(data) if data else None

    def set(self, key: str, value: dict, expire: int = 300):
        self.client.setex(key, expire, json.dumps(value))

    def delete(self, key: str):
        self.client.delete(key)

    def exists(self, key: str) -> bool:
        return self.client.exists(key) > 0

cache = RedisCache()
```

## Redis Patterns

```python
# Cache user
def get_cached_user(user_id: str):
    key = f"user:{user_id}"
    cached = cache.get(key)
    if cached:
        return cached

    user = db.users.find_one({"_id": ObjectId(user_id)})
    if user:
        user["_id"] = str(user["_id"])
        cache.set(key, user, expire=300)
    return user

# Invalidate cache
def invalidate_user_cache(user_id: str):
    cache.delete(f"user:{user_id}")

# Session storage
def store_session(session_id: str, data: dict):
    cache.set(f"session:{session_id}", data, expire=3600)

def get_session(session_id: str):
    return cache.get(f"session:{session_id}")
```

## Quick Reference

| Pattern         | Code                                                  |
| --------------- | ----------------------------------------------------- |
| MongoDB connect | `pymongo.MongoClient()`, `motor.AsyncIOMotorClient()` |
| Insert          | `db.collection.insert_one(doc)`                       |
| Find            | `db.collection.find_one({filter})`                    |
| Update          | `db.collection.update_one({filter}, {"$set": data})`  |
| Delete          | `db.collection.delete_one({filter})`                  |
| Redis cache     | `cache.set(key, value, expire)`                       |
| Session         | `cache.set(f"session:{id}", data)`                    |