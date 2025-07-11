from motor.motor_asyncio import AsyncIOMotorClient
import redis.asyncio as redis
from app.core.config import settings

# MongoDB连接
mongodb_client = AsyncIOMotorClient(settings.MONGODB_URL)
mongodb = mongodb_client.get_default_database()

# Redis连接
redis_client = redis.from_url(settings.REDIS_URL)

# 集合引用
users_collection = mongodb.users
novels_collection = mongodb.novels
chapters_collection = mongodb.chapters
characters_collection = mongodb.characters
worldviews_collection = mongodb.worldviews
plots_collection = mongodb.plots
foreshadows_collection = mongodb.foreshadows
ai_conversations_collection = mongodb.ai_conversations
md_files_collection = mongodb.md_files
