"""
OAuth2 Implementation for WFM Enterprise API
Supports multiple OAuth2 flows and providers
"""

from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List
from uuid import uuid4
import secrets
import hashlib
import base64
from urllib.parse import urlencode

from fastapi import HTTPException, status, Request
from fastapi.security import OAuth2PasswordBearer, OAuth2AuthorizationCodeBearer
from pydantic import BaseModel, Field
import httpx

from .jwt_handler import jwt_handler


# OAuth2 schemes
oauth2_password_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")
oauth2_code_scheme = OAuth2AuthorizationCodeBearer(
    authorizationUrl="/api/v1/auth/authorize",
    tokenUrl="/api/v1/auth/token"
)


class OAuth2Client(BaseModel):
    """OAuth2 client registration"""
    client_id: str
    client_secret: str
    redirect_uris: List[str]
    grant_types: List[str] = ["authorization_code", "refresh_token"]
    response_types: List[str] = ["code"]
    scopes: List[str] = []
    client_name: str
    client_uri: Optional[str] = None
    logo_uri: Optional[str] = None
    contacts: List[str] = []
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)


class AuthorizationCode(BaseModel):
    """OAuth2 authorization code"""
    code: str
    client_id: str
    user_id: str
    redirect_uri: str
    scopes: List[str]
    code_challenge: Optional[str] = None
    code_challenge_method: Optional[str] = None
    expires_at: datetime
    used: bool = False


class OAuth2Token(BaseModel):
    """OAuth2 token response"""
    access_token: str
    token_type: str = "Bearer"
    expires_in: int
    refresh_token: Optional[str] = None
    scope: Optional[str] = None
    id_token: Optional[str] = None


class OAuth2Handler:
    """OAuth2 authentication handler with support for multiple providers"""
    
    def __init__(self):
        self.clients: Dict[str, OAuth2Client] = {}
        self.authorization_codes: Dict[str, AuthorizationCode] = {}
        self.providers = {
            "google": {
                "authorize_url": "https://accounts.google.com/o/oauth2/v2/auth",
                "token_url": "https://oauth2.googleapis.com/token",
                "userinfo_url": "https://www.googleapis.com/oauth2/v2/userinfo",
                "scopes": ["openid", "email", "profile"]
            },
            "microsoft": {
                "authorize_url": "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
                "token_url": "https://login.microsoftonline.com/common/oauth2/v2.0/token",
                "userinfo_url": "https://graph.microsoft.com/v1.0/me",
                "scopes": ["openid", "email", "profile", "User.Read"]
            },
            "okta": {
                "authorize_url": "{domain}/oauth2/v1/authorize",
                "token_url": "{domain}/oauth2/v1/token",
                "userinfo_url": "{domain}/oauth2/v1/userinfo",
                "scopes": ["openid", "email", "profile"]
            }
        }
    
    def register_client(self, client_data: Dict[str, Any]) -> OAuth2Client:
        """Register new OAuth2 client"""
        client = OAuth2Client(
            client_id=str(uuid4()),
            client_secret=secrets.token_urlsafe(32),
            **client_data
        )
        
        self.clients[client.client_id] = client
        return client
    
    def validate_client(
        self,
        client_id: str,
        client_secret: Optional[str] = None,
        grant_type: Optional[str] = None
    ) -> OAuth2Client:
        """Validate OAuth2 client credentials"""
        client = self.clients.get(client_id)
        if not client:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid client"
            )
        
        if client_secret and client.client_secret != client_secret:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid client credentials"
            )
        
        if grant_type and grant_type not in client.grant_types:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Unsupported grant type"
            )
        
        return client
    
    def validate_redirect_uri(self, client: OAuth2Client, redirect_uri: str) -> bool:
        """Validate redirect URI against registered URIs"""
        return redirect_uri in client.redirect_uris
    
    def generate_authorization_code(
        self,
        client_id: str,
        user_id: str,
        redirect_uri: str,
        scopes: List[str],
        code_challenge: Optional[str] = None,
        code_challenge_method: Optional[str] = None
    ) -> str:
        """Generate authorization code for code flow"""
        code = secrets.token_urlsafe(32)
        
        authorization_code = AuthorizationCode(
            code=code,
            client_id=client_id,
            user_id=user_id,
            redirect_uri=redirect_uri,
            scopes=scopes,
            code_challenge=code_challenge,
            code_challenge_method=code_challenge_method,
            expires_at=datetime.utcnow() + timedelta(minutes=10)
        )
        
        self.authorization_codes[code] = authorization_code
        return code
    
    def validate_authorization_code(
        self,
        code: str,
        client_id: str,
        redirect_uri: str,
        code_verifier: Optional[str] = None
    ) -> AuthorizationCode:
        """Validate authorization code"""
        auth_code = self.authorization_codes.get(code)
        
        if not auth_code:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid authorization code"
            )
        
        if auth_code.used:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Authorization code already used"
            )
        
        if auth_code.expires_at < datetime.utcnow():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Authorization code expired"
            )
        
        if auth_code.client_id != client_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid client for authorization code"
            )
        
        if auth_code.redirect_uri != redirect_uri:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid redirect URI"
            )
        
        # Validate PKCE if used
        if auth_code.code_challenge:
            if not code_verifier:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Code verifier required"
                )
            
            if auth_code.code_challenge_method == "S256":
                # SHA256 hash
                verifier_hash = base64.urlsafe_b64encode(
                    hashlib.sha256(code_verifier.encode()).digest()
                ).decode().rstrip("=")
                
                if verifier_hash != auth_code.code_challenge:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="Invalid code verifier"
                    )
            elif auth_code.code_challenge != code_verifier:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid code verifier"
                )
        
        # Mark as used
        auth_code.used = True
        
        return auth_code
    
    async def exchange_code_for_token(
        self,
        code: str,
        client_id: str,
        client_secret: str,
        redirect_uri: str,
        code_verifier: Optional[str] = None
    ) -> OAuth2Token:
        """Exchange authorization code for access token"""
        # Validate client
        client = self.validate_client(client_id, client_secret, "authorization_code")
        
        # Validate code
        auth_code = self.validate_authorization_code(
            code, client_id, redirect_uri, code_verifier
        )
        
        # Create tokens
        user_data = {
            "sub": auth_code.user_id,
            "scopes": auth_code.scopes,
            "client_id": client_id
        }
        
        access_token = jwt_handler.create_access_token(user_data)
        refresh_token = jwt_handler.create_refresh_token(user_data)
        
        return OAuth2Token(
            access_token=access_token,
            expires_in=1800,  # 30 minutes
            refresh_token=refresh_token,
            scope=" ".join(auth_code.scopes)
        )
    
    async def password_grant(
        self,
        username: str,
        password: str,
        scopes: List[str] = None
    ) -> OAuth2Token:
        """Resource Owner Password Credentials Grant"""
        # TODO: Validate username/password against user database
        # This is a placeholder - integrate with your user service
        
        user_data = {
            "sub": username,
            "scopes": scopes or ["read", "write"]
        }
        
        access_token = jwt_handler.create_access_token(user_data)
        refresh_token = jwt_handler.create_refresh_token(user_data)
        
        return OAuth2Token(
            access_token=access_token,
            expires_in=1800,
            refresh_token=refresh_token,
            scope=" ".join(scopes) if scopes else ""
        )
    
    async def refresh_token_grant(
        self,
        refresh_token: str,
        client_id: Optional[str] = None,
        client_secret: Optional[str] = None
    ) -> OAuth2Token:
        """Refresh Token Grant"""
        if client_id:
            self.validate_client(client_id, client_secret, "refresh_token")
        
        # Use JWT handler to refresh
        token_response = await jwt_handler.refresh_access_token(refresh_token)
        
        return OAuth2Token(
            access_token=token_response.access_token,
            expires_in=token_response.expires_in,
            refresh_token=token_response.refresh_token,
            scope=token_response.scope
        )
    
    async def client_credentials_grant(
        self,
        client_id: str,
        client_secret: str,
        scopes: List[str] = None
    ) -> OAuth2Token:
        """Client Credentials Grant for service-to-service auth"""
        client = self.validate_client(client_id, client_secret, "client_credentials")
        
        # Validate requested scopes
        if scopes:
            for scope in scopes:
                if scope not in client.scopes:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail=f"Invalid scope: {scope}"
                    )
        else:
            scopes = client.scopes
        
        # Create service account token
        service_data = {
            "sub": client_id,
            "type": "service",
            "scopes": scopes
        }
        
        access_token = jwt_handler.create_access_token(
            service_data,
            expires_delta=timedelta(hours=1)  # Longer lived for services
        )
        
        return OAuth2Token(
            access_token=access_token,
            expires_in=3600,
            scope=" ".join(scopes)
        )
    
    def get_provider_auth_url(
        self,
        provider: str,
        client_id: str,
        redirect_uri: str,
        state: str,
        scopes: Optional[List[str]] = None,
        **kwargs
    ) -> str:
        """Get authorization URL for external provider"""
        if provider not in self.providers:
            raise ValueError(f"Unknown provider: {provider}")
        
        provider_config = self.providers[provider]
        auth_url = provider_config["authorize_url"]
        
        # Handle template URLs (e.g., Okta)
        if "{domain}" in auth_url:
            domain = kwargs.get("domain")
            if not domain:
                raise ValueError(f"Domain required for {provider}")
            auth_url = auth_url.format(domain=domain)
        
        # Build authorization URL
        params = {
            "client_id": client_id,
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "state": state,
            "scope": " ".join(scopes or provider_config["scopes"])
        }
        
        # Add provider-specific parameters
        if provider == "google":
            params["access_type"] = "offline"  # Get refresh token
            params["prompt"] = "consent"
        elif provider == "microsoft":
            params["response_mode"] = "query"
        
        return f"{auth_url}?{urlencode(params)}"
    
    async def exchange_provider_code(
        self,
        provider: str,
        code: str,
        client_id: str,
        client_secret: str,
        redirect_uri: str,
        **kwargs
    ) -> Dict[str, Any]:
        """Exchange provider authorization code for tokens"""
        if provider not in self.providers:
            raise ValueError(f"Unknown provider: {provider}")
        
        provider_config = self.providers[provider]
        token_url = provider_config["token_url"]
        
        # Handle template URLs
        if "{domain}" in token_url:
            domain = kwargs.get("domain")
            if not domain:
                raise ValueError(f"Domain required for {provider}")
            token_url = token_url.format(domain=domain)
        
        # Exchange code for token
        async with httpx.AsyncClient() as client:
            response = await client.post(
                token_url,
                data={
                    "grant_type": "authorization_code",
                    "code": code,
                    "client_id": client_id,
                    "client_secret": client_secret,
                    "redirect_uri": redirect_uri
                }
            )
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Provider token exchange failed: {response.text}"
                )
            
            return response.json()
    
    async def get_provider_userinfo(
        self,
        provider: str,
        access_token: str,
        **kwargs
    ) -> Dict[str, Any]:
        """Get user info from provider"""
        if provider not in self.providers:
            raise ValueError(f"Unknown provider: {provider}")
        
        provider_config = self.providers[provider]
        userinfo_url = provider_config["userinfo_url"]
        
        # Handle template URLs
        if "{domain}" in userinfo_url:
            domain = kwargs.get("domain")
            if not domain:
                raise ValueError(f"Domain required for {provider}")
            userinfo_url = userinfo_url.format(domain=domain)
        
        # Get user info
        async with httpx.AsyncClient() as client:
            headers = {"Authorization": f"Bearer {access_token}"}
            response = await client.get(userinfo_url, headers=headers)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Failed to get user info: {response.text}"
                )
            
            return response.json()


# Global instance
oauth2_handler = OAuth2Handler()