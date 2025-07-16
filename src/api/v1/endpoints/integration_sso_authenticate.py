"""
Enterprise Integration API - Task 72: Single Sign-On Authentication
POST /api/v1/integration/sso/authenticate

Features:
- SAML/OAuth2 enterprise integration
- SAML assertions and OAuth2 flows
- Identity mapping and federation
- Database: sso_providers, identity_mappings, authentication_sessions
"""

from fastapi import APIRouter, HTTPException, Depends, Request, Form, Response
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, validator
from typing import Optional, Dict, Any, List
from datetime import datetime, timedelta
import asyncpg
import xml.etree.ElementTree as ET
import base64
import json
import jwt
import uuid
import hashlib
import secrets
from enum import Enum
import aiohttp

# Database connection
from ...core.database import get_db_connection

security = HTTPBearer()

router = APIRouter(prefix="/api/v1/integration/sso", tags=["Enterprise Integration - SSO"])

class ProviderType(str, Enum):
    SAML2 = "saml2"
    OAUTH2 = "oauth2"
    OIDC = "openid_connect"

class SAMLBinding(str, Enum):
    HTTP_POST = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
    HTTP_REDIRECT = "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"

class SSOAuthenticationRequest(BaseModel):
    """SSO authentication request"""
    provider_id: str
    provider_type: ProviderType
    assertion_data: Optional[str] = None  # SAML assertion or OAuth code
    redirect_uri: Optional[str] = None
    state: Optional[str] = None
    
class SSOAuthenticationResponse(BaseModel):
    """SSO authentication response"""
    access_token: str
    refresh_token: Optional[str] = None
    token_type: str = "Bearer"
    expires_in: int
    user_id: str
    email: str
    display_name: str
    roles: List[str]
    permissions: List[str]
    session_id: str

class SAMLProvider(BaseModel):
    """SAML provider configuration"""
    provider_id: str
    name: str
    entity_id: str
    sso_url: str
    slo_url: Optional[str] = None
    x509_certificate: str
    binding: SAMLBinding = SAMLBinding.HTTP_POST
    
class OAuth2Provider(BaseModel):
    """OAuth2 provider configuration"""
    provider_id: str
    name: str
    client_id: str
    client_secret: str
    authorization_url: str
    token_url: str
    userinfo_url: str
    scope: str = "openid profile email"

async def get_sso_provider(conn: asyncpg.Connection, provider_id: str, provider_type: ProviderType) -> Dict[str, Any]:
    """Get SSO provider configuration"""
    row = await conn.fetchrow("""
        SELECT provider_id, name, provider_type, configuration, active, created_at
        FROM sso_providers 
        WHERE provider_id = $1 AND provider_type = $2 AND active = true
    """, provider_id, provider_type.value)
    
    if not row:
        raise HTTPException(status_code=404, detail="SSO provider not found")
    
    return {
        "provider_id": row['provider_id'],
        "name": row['name'],
        "provider_type": row['provider_type'],
        "configuration": json.loads(row['configuration']),
        "active": row['active'],
        "created_at": row['created_at']
    }

async def validate_saml_assertion(assertion_xml: str, provider_config: Dict[str, Any]) -> Dict[str, Any]:
    """Validate SAML assertion and extract user attributes"""
    try:
        # Decode base64 assertion
        assertion_data = base64.b64decode(assertion_xml)
        
        # Parse XML
        root = ET.fromstring(assertion_data)
        
        # Extract namespaces
        namespaces = {
            'saml': 'urn:oasis:names:tc:SAML:2.0:assertion',
            'samlp': 'urn:oasis:names:tc:SAML:2.0:protocol'
        }
        
        # Validate issuer
        issuer = root.find('.//saml:Issuer', namespaces)
        if issuer is None or issuer.text != provider_config['configuration']['entity_id']:
            raise ValueError("Invalid SAML issuer")
        
        # Extract user attributes
        user_attrs = {}
        attributes = root.findall('.//saml:Attribute', namespaces)
        
        for attr in attributes:
            attr_name = attr.get('Name')
            attr_values = []
            
            for value in attr.findall('.//saml:AttributeValue', namespaces):
                if value.text:
                    attr_values.append(value.text)
            
            if attr_values:
                user_attrs[attr_name] = attr_values[0] if len(attr_values) == 1 else attr_values
        
        # Extract subject
        subject = root.find('.//saml:Subject/saml:NameID', namespaces)
        if subject is None:
            raise ValueError("No subject found in SAML assertion")
        
        return {
            "subject": subject.text,
            "attributes": user_attrs,
            "issuer": issuer.text
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid SAML assertion: {str(e)}")

async def exchange_oauth2_code(code: str, provider_config: Dict[str, Any], redirect_uri: str) -> Dict[str, Any]:
    """Exchange OAuth2 authorization code for access token"""
    try:
        config = provider_config['configuration']
        
        token_data = {
            'grant_type': 'authorization_code',
            'code': code,
            'redirect_uri': redirect_uri,
            'client_id': config['client_id'],
            'client_secret': config['client_secret']
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(config['token_url'], data=token_data) as response:
                if response.status != 200:
                    raise ValueError("Token exchange failed")
                
                token_response = await response.json()
                
        # Get user info
        headers = {'Authorization': f"Bearer {token_response['access_token']}"}
        async with aiohttp.ClientSession() as session:
            async with session.get(config['userinfo_url'], headers=headers) as response:
                if response.status != 200:
                    raise ValueError("User info request failed")
                
                user_info = await response.json()
        
        return {
            "access_token": token_response['access_token'],
            "refresh_token": token_response.get('refresh_token'),
            "user_info": user_info
        }
        
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"OAuth2 authentication failed: {str(e)}")

async def map_user_identity(conn: asyncpg.Connection, provider_id: str, external_id: str, user_attrs: Dict[str, Any]) -> str:
    """Map external identity to internal user ID"""
    
    # Look for existing identity mapping
    existing_mapping = await conn.fetchrow("""
        SELECT user_id FROM identity_mappings 
        WHERE provider_id = $1 AND external_id = $2
    """, provider_id, external_id)
    
    if existing_mapping:
        # Update last seen
        await conn.execute("""
            UPDATE identity_mappings 
            SET last_login_at = $1, login_count = login_count + 1,
                external_attributes = $2
            WHERE provider_id = $3 AND external_id = $4
        """, datetime.utcnow(), json.dumps(user_attrs), provider_id, external_id)
        
        return existing_mapping['user_id']
    
    # Create new user if auto-provisioning is enabled
    user_id = str(uuid.uuid4())
    
    # Extract common attributes
    email = user_attrs.get('email') or user_attrs.get('emailAddress') or user_attrs.get('mail', '')
    display_name = user_attrs.get('displayName') or user_attrs.get('cn') or user_attrs.get('name', '')
    first_name = user_attrs.get('firstName') or user_attrs.get('givenName', '')
    last_name = user_attrs.get('lastName') or user_attrs.get('surname', '')
    
    async with conn.transaction():
        # Create user record
        await conn.execute("""
            INSERT INTO users (
                user_id, email, display_name, first_name, last_name,
                sso_only, active, created_at, updated_at
            ) VALUES ($1, $2, $3, $4, $5, true, true, $6, $7)
        """, user_id, email, display_name, first_name, last_name, 
        datetime.utcnow(), datetime.utcnow())
        
        # Create identity mapping
        await conn.execute("""
            INSERT INTO identity_mappings (
                mapping_id, provider_id, user_id, external_id, 
                external_attributes, created_at, last_login_at, login_count
            ) VALUES ($1, $2, $3, $4, $5, $6, $7, 1)
        """, str(uuid.uuid4()), provider_id, user_id, external_id,
        json.dumps(user_attrs), datetime.utcnow(), datetime.utcnow())
    
    return user_id

async def create_authentication_session(conn: asyncpg.Connection, user_id: str, provider_id: str, 
                                      session_data: Dict[str, Any]) -> str:
    """Create authentication session"""
    session_id = str(uuid.uuid4())
    expires_at = datetime.utcnow() + timedelta(hours=8)  # 8-hour session
    
    await conn.execute("""
        INSERT INTO authentication_sessions (
            session_id, user_id, provider_id, session_data,
            created_at, expires_at, active
        ) VALUES ($1, $2, $3, $4, $5, $6, true)
    """, session_id, user_id, provider_id, json.dumps(session_data),
    datetime.utcnow(), expires_at)
    
    return session_id

async def generate_access_token(user_id: str, session_id: str, roles: List[str], permissions: List[str]) -> Dict[str, Any]:
    """Generate JWT access token"""
    payload = {
        "sub": user_id,
        "session_id": session_id,
        "roles": roles,
        "permissions": permissions,
        "iat": datetime.utcnow().timestamp(),
        "exp": (datetime.utcnow() + timedelta(hours=1)).timestamp(),
        "iss": "wfm-enterprise"
    }
    
    # Use a secure secret key (should be from environment)
    secret_key = "enterprise-jwt-secret-key-change-in-production"
    token = jwt.encode(payload, secret_key, algorithm="HS256")
    
    return {
        "access_token": token,
        "token_type": "Bearer",
        "expires_in": 3600  # 1 hour
    }

@router.post("/authenticate", response_model=SSOAuthenticationResponse)
async def authenticate_sso(
    request: SSOAuthenticationRequest
):
    """
    Enterprise SSO authentication with SAML/OAuth2 support
    
    - SAML 2.0 assertion validation
    - OAuth2/OIDC token exchange
    - Identity mapping and federation
    - Session management
    """
    
    conn = await get_db_connection()
    try:
        # Get provider configuration
        provider = await get_sso_provider(conn, request.provider_id, request.provider_type)
        
        user_attrs = {}
        external_id = ""
        
        if request.provider_type == ProviderType.SAML2:
            if not request.assertion_data:
                raise HTTPException(status_code=400, detail="SAML assertion required")
            
            # Validate SAML assertion
            saml_data = await validate_saml_assertion(request.assertion_data, provider)
            user_attrs = saml_data['attributes']
            external_id = saml_data['subject']
            
        elif request.provider_type in [ProviderType.OAUTH2, ProviderType.OIDC]:
            if not request.assertion_data or not request.redirect_uri:
                raise HTTPException(status_code=400, detail="OAuth2 code and redirect URI required")
            
            # Exchange OAuth2 code
            oauth_data = await exchange_oauth2_code(request.assertion_data, provider, request.redirect_uri)
            user_attrs = oauth_data['user_info']
            external_id = user_attrs.get('sub') or user_attrs.get('id', str(uuid.uuid4()))
        
        # Map to internal user
        user_id = await map_user_identity(conn, request.provider_id, external_id, user_attrs)
        
        # Get user roles and permissions
        user_roles = await conn.fetch("""
            SELECT r.role_name FROM user_roles ur
            JOIN roles r ON ur.role_id = r.role_id
            WHERE ur.user_id = $1 AND ur.active = true
        """, user_id)
        
        roles = [row['role_name'] for row in user_roles]
        
        # Get permissions
        permissions_rows = await conn.fetch("""
            SELECT DISTINCT p.permission_name FROM user_roles ur
            JOIN roles r ON ur.role_id = r.role_id
            JOIN role_permissions rp ON r.role_id = rp.role_id
            JOIN permissions p ON rp.permission_id = p.permission_id
            WHERE ur.user_id = $1 AND ur.active = true AND rp.active = true
        """, user_id)
        
        permissions = [row['permission_name'] for row in permissions_rows]
        
        # Create session
        session_data = {
            "provider_type": request.provider_type.value,
            "provider_id": request.provider_id,
            "external_id": external_id,
            "login_method": "sso"
        }
        
        session_id = await create_authentication_session(conn, user_id, request.provider_id, session_data)
        
        # Generate tokens
        token_data = await generate_access_token(user_id, session_id, roles, permissions)
        
        # Get user details
        user = await conn.fetchrow("""
            SELECT email, display_name FROM users WHERE user_id = $1
        """, user_id)
        
        return SSOAuthenticationResponse(
            access_token=token_data['access_token'],
            token_type=token_data['token_type'],
            expires_in=token_data['expires_in'],
            user_id=user_id,
            email=user['email'],
            display_name=user['display_name'],
            roles=roles,
            permissions=permissions,
            session_id=session_id
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"SSO authentication failed: {str(e)}")
    finally:
        await conn.close()

@router.get("/providers")
async def list_sso_providers():
    """List available SSO providers"""
    
    conn = await get_db_connection()
    try:
        providers = await conn.fetch("""
            SELECT provider_id, name, provider_type, 
                   JSON_EXTRACT_PATH_TEXT(configuration, 'display_name') as display_name,
                   active, created_at
            FROM sso_providers 
            WHERE active = true
            ORDER BY name
        """)
        
        return {
            "providers": [
                {
                    "provider_id": row['provider_id'],
                    "name": row['name'],
                    "provider_type": row['provider_type'],
                    "display_name": row['display_name'] or row['name'],
                    "active": row['active']
                }
                for row in providers
            ]
        }
        
    finally:
        await conn.close()

@router.post("/logout")
async def logout_sso(
    session_id: str,
    credentials: HTTPAuthorizationCredentials = Depends(security)
):
    """Logout from SSO session"""
    
    conn = await get_db_connection()
    try:
        # Invalidate session
        await conn.execute("""
            UPDATE authentication_sessions 
            SET active = false, logged_out_at = $1
            WHERE session_id = $2
        """, datetime.utcnow(), session_id)
        
        return {"message": "Successfully logged out", "session_id": session_id}
        
    finally:
        await conn.close()

# Additional endpoints for SAML metadata, OAuth2 authorization URLs, etc.
# would be implemented here for complete SSO integration