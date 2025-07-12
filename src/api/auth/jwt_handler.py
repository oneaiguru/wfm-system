"""
JWT Token Handler for WFM Enterprise API
High-performance JWT implementation with Redis caching
"""

import os
import time
from datetime import datetime, timedelta, timezone
from typing import Dict, Any, Optional, Union, List
from uuid import uuid4

import jwt
from passlib.context import CryptContext
from pydantic import BaseModel, Field
import redis.asyncio as redis
from fastapi import HTTPException, status
import orjson

# Security configuration
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7
PASSWORD_RESET_TOKEN_EXPIRE_HOURS = 24

# Redis configuration for token blacklisting and caching
REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


class TokenData(BaseModel):
    """Token payload structure"""
    sub: str  # Subject (user ID)
    email: Optional[str] = None
    scopes: List[str] = Field(default_factory=list)
    organization_id: Optional[str] = None
    department_id: Optional[str] = None
    exp: Optional[datetime] = None
    iat: Optional[datetime] = None
    jti: Optional[str] = None  # JWT ID for revocation


class TokenResponse(BaseModel):
    """Token response structure"""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    scope: str = ""


class JWTHandler:
    """High-performance JWT token handler with Redis caching"""
    
    def __init__(self):
        self.redis_client: Optional[redis.Redis] = None
        self.secret_key = SECRET_KEY
        self.algorithm = ALGORITHM
        
    async def init_redis(self):
        """Initialize Redis connection"""
        if not self.redis_client:
            self.redis_client = await redis.from_url(
                REDIS_URL,
                encoding="utf-8",
                decode_responses=True
            )
    
    async def close_redis(self):
        """Close Redis connection"""
        if self.redis_client:
            await self.redis_client.close()
    
    def verify_password(self, plain_password: str, hashed_password: str) -> bool:
        """Verify password against hash"""
        return pwd_context.verify(plain_password, hashed_password)
    
    def get_password_hash(self, password: str) -> str:
        """Hash password"""
        return pwd_context.hash(password)
    
    def create_access_token(
        self,
        data: Dict[str, Any],
        expires_delta: Optional[timedelta] = None
    ) -> str:
        """Create JWT access token"""
        to_encode = data.copy()
        
        # Set expiration
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        
        # Add standard claims
        to_encode.update({
            "exp": expire,
            "iat": datetime.utcnow(),
            "jti": str(uuid4()),  # Unique token ID
            "type": "access"
        })
        
        # Encode token
        encoded_jwt = jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)
        return encoded_jwt
    
    def create_refresh_token(
        self,
        data: Dict[str, Any],
        expires_delta: Optional[timedelta] = None
    ) -> str:
        """Create JWT refresh token"""
        to_encode = data.copy()
        
        # Set expiration
        if expires_delta:
            expire = datetime.utcnow() + expires_delta
        else:
            expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
        
        # Add standard claims
        to_encode.update({
            "exp": expire,
            "iat": datetime.utcnow(),
            "jti": str(uuid4()),  # Unique token ID
            "type": "refresh"
        })
        
        # Encode token
        encoded_jwt = jwt.encode(to_encode, self.secret_key, algorithm=self.algorithm)
        return encoded_jwt
    
    def create_password_reset_token(self, email: str) -> str:
        """Create password reset token"""
        data = {
            "sub": email,
            "type": "password_reset",
            "exp": datetime.utcnow() + timedelta(hours=PASSWORD_RESET_TOKEN_EXPIRE_HOURS),
            "iat": datetime.utcnow(),
            "jti": str(uuid4())
        }
        
        encoded_jwt = jwt.encode(data, self.secret_key, algorithm=self.algorithm)
        return encoded_jwt
    
    async def decode_token(self, token: str) -> Dict[str, Any]:
        """Decode and validate JWT token"""
        try:
            # Check if token is blacklisted
            if await self.is_token_blacklisted(token):
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Token has been revoked"
                )
            
            # Decode token
            payload = jwt.decode(
                token,
                self.secret_key,
                algorithms=[self.algorithm]
            )
            
            return payload
            
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired"
            )
        except jwt.JWTError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
    
    async def refresh_access_token(self, refresh_token: str) -> TokenResponse:
        """Refresh access token using refresh token"""
        payload = await self.decode_token(refresh_token)
        
        # Verify it's a refresh token
        if payload.get("type") != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        
        # Create new access token
        user_data = {
            "sub": payload["sub"],
            "email": payload.get("email"),
            "scopes": payload.get("scopes", []),
            "organization_id": payload.get("organization_id"),
            "department_id": payload.get("department_id")
        }
        
        access_token = self.create_access_token(user_data)
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )
    
    async def revoke_token(self, token: str) -> bool:
        """Revoke token by adding to blacklist"""
        try:
            payload = jwt.decode(
                token,
                self.secret_key,
                algorithms=[self.algorithm],
                options={"verify_exp": False}  # Allow expired tokens to be revoked
            )
            
            jti = payload.get("jti")
            if not jti:
                return False
            
            # Calculate TTL based on expiration
            exp = payload.get("exp")
            if exp:
                ttl = exp - int(time.time())
                if ttl > 0:
                    # Add to blacklist with TTL
                    await self.redis_client.setex(
                        f"blacklist:{jti}",
                        ttl,
                        "1"
                    )
            
            return True
            
        except jwt.JWTError:
            return False
    
    async def is_token_blacklisted(self, token: str) -> bool:
        """Check if token is blacklisted"""
        if not self.redis_client:
            return False
        
        try:
            payload = jwt.decode(
                token,
                self.secret_key,
                algorithms=[self.algorithm],
                options={"verify_exp": False}
            )
            
            jti = payload.get("jti")
            if not jti:
                return False
            
            # Check blacklist
            result = await self.redis_client.get(f"blacklist:{jti}")
            return result is not None
            
        except jwt.JWTError:
            return False
    
    async def validate_scopes(
        self,
        required_scopes: List[str],
        token_scopes: List[str]
    ) -> bool:
        """Validate token has required scopes"""
        return all(scope in token_scopes for scope in required_scopes)
    
    async def cache_user_permissions(
        self,
        user_id: str,
        permissions: Dict[str, Any],
        ttl: int = 300  # 5 minutes
    ):
        """Cache user permissions in Redis"""
        if self.redis_client:
            await self.redis_client.setex(
                f"permissions:{user_id}",
                ttl,
                orjson.dumps(permissions).decode()
            )
    
    async def get_cached_permissions(
        self,
        user_id: str
    ) -> Optional[Dict[str, Any]]:
        """Get cached user permissions"""
        if not self.redis_client:
            return None
        
        data = await self.redis_client.get(f"permissions:{user_id}")
        if data:
            return orjson.loads(data)
        return None
    
    def create_api_key(self, user_id: str, name: str) -> str:
        """Create long-lived API key for service accounts"""
        data = {
            "sub": user_id,
            "type": "api_key",
            "name": name,
            "iat": datetime.utcnow(),
            "jti": str(uuid4())
        }
        
        # API keys don't expire by default
        encoded_jwt = jwt.encode(data, self.secret_key, algorithm=self.algorithm)
        return encoded_jwt


# Global instance
jwt_handler = JWTHandler()