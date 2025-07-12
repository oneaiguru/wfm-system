"""
User Models for Authentication and Authorization
SQLAlchemy models for user management and organization structure
"""

from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey, Integer
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

from ..core.database import Base
from .permissions import user_roles, user_permissions


class Organization(Base):
    """Organization model for multi-tenant support"""
    __tablename__ = "organizations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    code = Column(String(50), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    
    # Organization settings
    settings = Column(Text, nullable=True)  # JSON string
    timezone = Column(String(50), default="UTC")
    locale = Column(String(10), default="en_US")
    
    # Status and metadata
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    users = relationship("User", back_populates="organization")
    departments = relationship("Department", back_populates="organization")
    
    def __repr__(self):
        return f"<Organization(name='{self.name}', code='{self.code}')>"


class Department(Base):
    """Department model for organizational structure"""
    __tablename__ = "departments"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    code = Column(String(50), nullable=False)
    description = Column(Text, nullable=True)
    
    # Hierarchy
    parent_id = Column(UUID(as_uuid=True), ForeignKey('departments.id'), nullable=True)
    parent = relationship("Department", remote_side=[id], backref="children")
    
    # Organization link
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'), nullable=False)
    organization = relationship("Organization", back_populates="departments")
    
    # Department settings
    manager_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=True)
    cost_center = Column(String(50), nullable=True)
    
    # Status and metadata
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    users = relationship("User", back_populates="department", foreign_keys="User.department_id")
    manager = relationship("User", foreign_keys=[manager_id], post_update=True)
    
    def __repr__(self):
        return f"<Department(name='{self.name}', code='{self.code}')>"


class User(Base):
    """User model for authentication and authorization"""
    __tablename__ = "users"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Basic information
    email = Column(String(255), unique=True, nullable=False, index=True)
    username = Column(String(100), unique=True, nullable=True, index=True)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    
    # Authentication
    hashed_password = Column(String(255), nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    
    # Authorization
    is_admin = Column(Boolean, default=False)
    is_superuser = Column(Boolean, default=False)
    
    # Organization and department
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'), nullable=False)
    department_id = Column(UUID(as_uuid=True), ForeignKey('departments.id'), nullable=True)
    
    # Profile information
    phone = Column(String(20), nullable=True)
    avatar_url = Column(String(255), nullable=True)
    language = Column(String(10), default="en")
    timezone = Column(String(50), default="UTC")
    
    # Employment information
    employee_id = Column(String(50), nullable=True, unique=True)
    job_title = Column(String(100), nullable=True)
    hire_date = Column(DateTime, nullable=True)
    manager_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=True)
    
    # Security
    failed_login_attempts = Column(Integer, default=0)
    locked_until = Column(DateTime, nullable=True)
    last_login = Column(DateTime, nullable=True)
    password_changed_at = Column(DateTime, default=datetime.utcnow)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    organization = relationship("Organization", back_populates="users")
    department = relationship("Department", back_populates="users", foreign_keys=[department_id])
    manager = relationship("User", remote_side=[id], backref="direct_reports")
    
    # Many-to-many relationships with roles and permissions
    roles = relationship("Role", secondary=user_roles, back_populates="users")
    permissions = relationship("Permission", secondary=user_permissions, back_populates="users")
    
    def __repr__(self):
        return f"<User(email='{self.email}', name='{self.first_name} {self.last_name}')>"
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"
    
    def has_permission(self, permission_name: str) -> bool:
        """Check if user has a specific permission"""
        # Direct permissions
        for permission in self.permissions:
            if permission.name == permission_name:
                return True
        
        # Role-based permissions
        for role in self.roles:
            for permission in role.permissions:
                if permission.name == permission_name:
                    return True
        
        return False
    
    def has_role(self, role_name: str) -> bool:
        """Check if user has a specific role"""
        for role in self.roles:
            if role.name == role_name:
                return True
        return False
    
    def get_all_permissions(self) -> list:
        """Get all permissions for this user"""
        all_permissions = set()
        
        # Direct permissions
        for permission in self.permissions:
            all_permissions.add(permission.name)
        
        # Role-based permissions
        for role in self.roles:
            for permission in role.permissions:
                all_permissions.add(permission.name)
        
        return list(all_permissions)


class UserSession(Base):
    """User session tracking"""
    __tablename__ = "user_sessions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=False)
    session_token = Column(String(255), unique=True, nullable=False)
    
    # Session metadata
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    device_info = Column(Text, nullable=True)
    
    # Session timing
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)
    last_activity = Column(DateTime, default=datetime.utcnow)
    
    # Status
    is_active = Column(Boolean, default=True)
    
    # Relationships
    user = relationship("User", backref="sessions")
    
    def __repr__(self):
        return f"<UserSession(user_id='{self.user_id}', active={self.is_active})>"


class LoginAttempt(Base):
    """Login attempt tracking for security"""
    __tablename__ = "login_attempts"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String(255), nullable=False, index=True)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=True)
    
    # Attempt details
    ip_address = Column(String(45), nullable=True)
    user_agent = Column(Text, nullable=True)
    success = Column(Boolean, default=False)
    failure_reason = Column(String(100), nullable=True)
    
    # Timing
    attempted_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", backref="login_attempts")
    
    def __repr__(self):
        return f"<LoginAttempt(email='{self.email}', success={self.success})>"


class APIKey(Base):
    """API key management"""
    __tablename__ = "api_keys"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=False)
    
    # Key information
    name = Column(String(100), nullable=False)
    key_hash = Column(String(255), unique=True, nullable=False)
    prefix = Column(String(10), nullable=False)  # First few characters for identification
    
    # Permissions and scope
    scopes = Column(Text, nullable=True)  # JSON array of scopes
    allowed_ips = Column(Text, nullable=True)  # JSON array of allowed IPs
    
    # Status and timing
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)
    last_used = Column(DateTime, nullable=True)
    
    # Usage tracking
    usage_count = Column(Integer, default=0)
    usage_limit = Column(Integer, nullable=True)
    
    # Relationships
    user = relationship("User", backref="api_keys")
    
    def __repr__(self):
        return f"<APIKey(name='{self.name}', prefix='{self.prefix}')>"


# Employee model for schedule management
class Employee(Base):
    """Employee model for schedule management"""
    __tablename__ = "employees"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    
    # Link to user account (optional)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=True)
    
    # Employee information
    employee_number = Column(String(50), unique=True, nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(255), nullable=True)
    phone = Column(String(20), nullable=True)
    
    # Employment details
    job_title = Column(String(100), nullable=True)
    hire_date = Column(DateTime, nullable=True)
    employment_type = Column(String(50), default="full_time")  # full_time, part_time, contract
    
    # Organization and department
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'), nullable=False)
    department_id = Column(UUID(as_uuid=True), ForeignKey('departments.id'), nullable=True)
    
    # Skills and qualifications
    skills = Column(Text, nullable=True)  # JSON array of skills
    certifications = Column(Text, nullable=True)  # JSON array of certifications
    
    # Scheduling preferences
    availability_pattern = Column(Text, nullable=True)  # JSON scheduling preferences
    max_hours_per_week = Column(Integer, default=40)
    min_hours_per_week = Column(Integer, default=20)
    preferred_shifts = Column(Text, nullable=True)  # JSON array of preferred shift types
    
    # Status
    is_active = Column(Boolean, default=True)
    is_available_for_scheduling = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", backref="employee_profile")
    organization = relationship("Organization")
    department = relationship("Department")
    
    def __repr__(self):
        return f"<Employee(number='{self.employee_number}', name='{self.first_name} {self.last_name}')>"
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"