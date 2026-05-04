---
name: database-nosql-skill
description: >
  NoSQL database patterns: MongoDB, Redis, document models, caching.
  Trigger: "MongoDB", "Redis", "NoSQL", "document database", "caching", "cache".
---

## When to Use

- MongoDB document storage
- Redis caching
- Flexible schema requirements
- High-speed caching
- Session storage

## MongoDB Setup

```python
from pymongo import MongoClient
from bson import ObjectId

MONGO_URL = "mongodb://localhost:27017"
client = MongoClient(MONGO_URL)
db = client["myapp"]

def get_collection(name: str):
    return db[name]
```

## Document Models (Motor/Async)

```python
from motor.motor_asyncio import AsyncIOMotorClient
from typing import Optional
from datetime import datetime

class AsyncMongoDB:
    def __init__(self):
        self.client: Optional[AsyncIOMotorClient] = None
        self.db = None
    
    async def connect(self):
        self.client = AsyncIOMotorClient(MONGO_URL)
        self.db = self.client.myapp
    
    async def close(self):
        if self.client:
            self.client.close()
    
    @property
    def users(self):
        return self.db.users
    
    @property
    def posts(self):
        return self.db.posts

mongodb = AsyncMongoDB()
```

## CRUD Operations

```python
# Create
async def create_user(user_data: dict):
    result = await mongodb.users.insert_one(user_data)
    return str(result.inserted_id)

# Read
async def get_user(user_id: str):
    return await mongodb.users.find_one({"_id": ObjectId(user_id)})

async def get_user_by_email(email: str):
    return await mongodb.users.find_one({"email": email})

# Update
async def update_user(user_id: str, update_data: dict):
    result = await mongodb.users.update_one(
        {"_id": ObjectId(user_id)},
        {"$set": update_data}
    )
    return result.modified_count > 0

# Delete
async def delete_user(user_id: str):
    result = await mongodb.users.delete_one({"_id": ObjectId(user_id)})
    return result.deleted_count > 0
```

## Queries

```python
# Find multiple
async def get_active_users():
    cursor = mongodb.users.find({"is_active": True})
    return await cursor.to_list(length=100)

# Find with projection
async def get_user_names():
    cursor = mongodb.users.find({}, {"username": 1, "email": 1})
    return await cursor.to_list(length=None)

# Pagination
async def get_paginated_posts(page: int = 1, per_page: int = 20):
    skip = (page - 1) * per_page
    cursor = mongodb.posts.find({}).skip(skip).limit(per_page).sort("created_at", -1)
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

| Pattern | Code |
|---------|------|
| MongoDB connect | `pymongo.MongoClient()`, `motor.AsyncIOMotorClient()` |
| Insert | `db.collection.insert_one(doc)` |
| Find | `db.collection.find_one({filter})` |
| Update | `db.collection.update_one({filter}, {"$set": data})` |
| Delete | `db.collection.delete_one({filter})` |
| Redis cache | `cache.set(key, value, expire)` |
| Session | `cache.set(f"session:{id}", data)` |

