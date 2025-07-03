from fastapi import Request, Response
from fastapi.responses import JSONResponse
import traceback
import logging

logger = logging.getLogger(__name__)

class ErrorHandlerMiddleware:
    """错误处理中间件"""
    
    def __init__(self, app):
        self.app = app
    
    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        try:
            await self.app(scope, receive, send)
        except Exception as exc:
            logger.error(f"Unhandled exception: {exc}\n{traceback.format_exc()}")
            
            response = JSONResponse(
                status_code=500,
                content={
                    "error": "内部服务器错误",
                    "message": "服务器发生了未预期的错误，请稍后重试",
                    "detail": str(exc) if logger.level == logging.DEBUG else None
                }
            )
            
            await response(scope, receive, send)
