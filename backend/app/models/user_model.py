"""
MongoDB 用户文档模型
"""

from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from bson import ObjectId

class UserResponse(BaseModel):
    """用户响应模型"""
    id: str
    username: str
    email: str
    created_at: datetime

    @classmethod
    def from_mongo(cls, user_doc: Dict[str, Any]) -> "UserResponse":
        """从MongoDB文档创建响应对象"""
        return cls(
            id=str(user_doc["_id"]),
            username=user_doc["username"],
            email=user_doc["email"],
            created_at=user_doc["created_at"]
        )
