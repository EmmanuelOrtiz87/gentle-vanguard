---
name: database-nosql-skill
description: >
  NoSQL database patterns: MongoDB, Redis, document models, caching. Trigger: "MongoDB", "Redis",
  "NoSQL", "document database", "caching", "cache".
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

---

> **Referencia detallada**: [eferences/detail.md](references/detail.md)