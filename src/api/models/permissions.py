"""
Permission and Role Models for RBAC System
SQLAlchemy models for role-based access control
"""

from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey, Table
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

from ..core.database import Base


# Association tables for many-to-many relationships
user_roles = Table(
    'user_roles',
    Base.metadata,
    Column('user_id', UUID(as_uuid=True), ForeignKey('users.id'), primary_key=True),
    Column('role_id', UUID(as_uuid=True), ForeignKey('roles.id'), primary_key=True)
)

user_permissions = Table(
    'user_permissions',
    Base.metadata,
    Column('user_id', UUID(as_uuid=True), ForeignKey('users.id'), primary_key=True),
    Column('permission_id', UUID(as_uuid=True), ForeignKey('permissions.id'), primary_key=True)
)

role_permissions = Table(
    'role_permissions',
    Base.metadata,
    Column('role_id', UUID(as_uuid=True), ForeignKey('roles.id'), primary_key=True),
    Column('permission_id', UUID(as_uuid=True), ForeignKey('permissions.id'), primary_key=True)
)


class Permission(Base):
    """Permission model for fine-grained access control"""
    __tablename__ = "permissions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    resource = Column(String(50), nullable=False)  # e.g., "users", "schedules"
    action = Column(String(50), nullable=False)    # e.g., "read", "write", "delete"
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    roles = relationship("Role", secondary=role_permissions, back_populates="permissions")
    users = relationship("User", secondary=user_permissions, back_populates="permissions")
    
    def __repr__(self):
        return f"<Permission(name='{self.name}', resource='{self.resource}', action='{self.action}')>"


class Role(Base):
    """Role model for grouping permissions"""
    __tablename__ = "roles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    
    # Hierarchy support
    parent_id = Column(UUID(as_uuid=True), ForeignKey('roles.id'), nullable=True)
    parent = relationship("Role", remote_side=[id], backref="children")
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    permissions = relationship("Permission", secondary=role_permissions, back_populates="roles")
    users = relationship("User", secondary=user_roles, back_populates="roles")
    
    def __repr__(self):
        return f"<Role(name='{self.name}', active={self.is_active})>"
    
    def get_all_permissions(self):
        """Get all permissions including inherited from parent roles"""
        all_permissions = set(self.permissions)
        
        # Add parent permissions
        current_role = self.parent
        while current_role:
            all_permissions.update(current_role.permissions)
            current_role = current_role.parent
        
        return list(all_permissions)


class OrganizationRole(Base):
    """Organization-specific role assignments"""
    __tablename__ = "organization_roles"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=False)
    organization_id = Column(UUID(as_uuid=True), ForeignKey('organizations.id'), nullable=False)
    role_id = Column(UUID(as_uuid=True), ForeignKey('roles.id'), nullable=False)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", backref="organization_roles")
    organization = relationship("Organization", backref="organization_roles")
    role = relationship("Role", backref="organization_roles")


class ResourcePermission(Base):
    """Resource-specific permission assignments"""
    __tablename__ = "resource_permissions"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=False)
    resource_type = Column(String(50), nullable=False)  # e.g., "schedule", "employee"
    resource_id = Column(String(100), nullable=False)   # Specific resource ID
    permission_id = Column(UUID(as_uuid=True), ForeignKey('permissions.id'), nullable=False)
    
    # Optional constraints
    granted_by = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=True)
    expires_at = Column(DateTime, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    user = relationship("User", foreign_keys=[user_id], backref="resource_permissions")
    permission = relationship("Permission", backref="resource_permissions")
    grantor = relationship("User", foreign_keys=[granted_by], backref="granted_permissions")


class PermissionGroup(Base):
    """Permission groups for easier management"""
    __tablename__ = "permission_groups"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(50), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


# Permission group associations
permission_group_permissions = Table(
    'permission_group_permissions',
    Base.metadata,
    Column('group_id', UUID(as_uuid=True), ForeignKey('permission_groups.id'), primary_key=True),
    Column('permission_id', UUID(as_uuid=True), ForeignKey('permissions.id'), primary_key=True)
)


class PermissionCache(Base):
    """Cache for computed user permissions"""
    __tablename__ = "permission_cache"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey('users.id'), nullable=False)
    permissions_json = Column(Text, nullable=False)  # JSON array of permission names
    
    # Cache metadata
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=False)
    
    # Relationships
    user = relationship("User", backref="permission_cache")


# Default permissions for WFM system
DEFAULT_PERMISSIONS = [
    # User management
    ("users.read", "Read user information", "users", "read"),
    ("users.write", "Create and update users", "users", "write"),
    ("users.delete", "Delete users", "users", "delete"),
    ("users.admin", "Full user administration", "users", "admin"),
    
    # Schedule management
    ("schedules.read", "Read schedules", "schedules", "read"),
    ("schedules.write", "Create and update schedules", "schedules", "write"),
    ("schedules.delete", "Delete schedules", "schedules", "delete"),
    ("schedules.publish", "Publish schedules", "schedules", "publish"),
    ("schedules.optimize", "Optimize schedules", "schedules", "optimize"),
    
    # Employee management
    ("employees.read", "Read employee information", "employees", "read"),
    ("employees.write", "Create and update employees", "employees", "write"),
    ("employees.delete", "Delete employees", "employees", "delete"),
    ("employees.skills", "Manage employee skills", "employees", "skills"),
    
    # Forecasting - Basic
    ("forecasts.read", "Read forecasts", "forecasts", "read"),
    ("forecasts.write", "Create and update forecasts", "forecasts", "write"),
    ("forecasts.delete", "Delete forecasts", "forecasts", "delete"),
    ("forecasts.generate", "Generate forecasts", "forecasts", "generate"),
    
    # Forecasting - Advanced
    ("forecasts.import", "Import forecast data", "forecasts", "import"),
    ("forecasts.export", "Export forecast data", "forecasts", "export"),
    ("forecasts.accuracy", "Calculate forecast accuracy", "forecasts", "accuracy"),
    ("forecasts.compare", "Compare forecasts", "forecasts", "compare"),
    
    # Planning
    ("planning.read", "Read planning data", "planning", "read"),
    ("planning.calculate", "Calculate staffing plans", "planning", "calculate"),
    ("planning.validate", "Validate planning data", "planning", "validate"),
    ("planning.optimize", "Optimize staffing plans", "planning", "optimize"),
    
    # ML Integration
    ("ml.read", "Read ML models", "ml", "read"),
    ("ml.train", "Train ML models", "ml", "train"),
    ("ml.predict", "Make ML predictions", "ml", "predict"),
    ("ml.delete", "Delete ML models", "ml", "delete"),
    
    # Scenarios
    ("scenarios.read", "Read scenarios", "scenarios", "read"),
    ("scenarios.create", "Create scenarios", "scenarios", "create"),
    ("scenarios.write", "Update scenarios", "scenarios", "write"),
    ("scenarios.delete", "Delete scenarios", "scenarios", "delete"),
    
    # Reporting
    ("reports.read", "Read reports", "reports", "read"),
    ("reports.generate", "Generate reports", "reports", "generate"),
    ("reports.schedule", "Schedule reports", "reports", "schedule"),
    
    # Time & Attendance
    ("attendance.read", "Read attendance data", "attendance", "read"),
    ("attendance.write", "Record attendance", "attendance", "write"),
    ("attendance.correct", "Correct attendance", "attendance", "correct"),
    ("attendance.approve", "Approve attendance", "attendance", "approve"),
    
    # Requests
    ("requests.read", "Read requests", "requests", "read"),
    ("requests.write", "Create requests", "requests", "write"),
    ("requests.approve", "Approve requests", "requests", "approve"),
    ("requests.reject", "Reject requests", "requests", "reject"),
    
    # Integration
    ("integrations.read", "Read integration data", "integrations", "read"),
    ("integrations.write", "Configure integrations", "integrations", "write"),
    ("integrations.sync", "Sync with external systems", "integrations", "sync"),
    
    # System administration
    ("system.read", "Read system information", "system", "read"),
    ("system.config", "Configure system settings", "system", "config"),
    ("system.logs", "Access system logs", "system", "logs"),
    ("system.backup", "Backup system", "system", "backup"),
    
    # API access
    ("api.read", "Read API access", "api", "read"),
    ("api.write", "Write API access", "api", "write"),
    ("api.admin", "Full API administration", "api", "admin"),
]

# Default roles
DEFAULT_ROLES = [
    ("employee", "Regular employee", [
        "schedules.read", "employees.read", "requests.write", "attendance.write"
    ]),
    ("supervisor", "Team supervisor", [
        "schedules.read", "schedules.write", "employees.read", "employees.write",
        "requests.read", "requests.approve", "attendance.read", "attendance.approve",
        "reports.read"
    ]),
    ("manager", "Department manager", [
        "schedules.read", "schedules.write", "schedules.publish", "employees.read",
        "employees.write", "employees.skills", "forecasts.read", "forecasts.write",
        "requests.read", "requests.approve", "attendance.read", "attendance.approve",
        "reports.read", "reports.generate"
    ]),
    ("planner", "Workforce planner", [
        "schedules.read", "schedules.write", "schedules.optimize", "employees.read",
        "forecasts.read", "forecasts.write", "forecasts.generate", "forecasts.import",
        "forecasts.export", "forecasts.accuracy", "forecasts.compare", "planning.read",
        "planning.calculate", "planning.validate", "planning.optimize", "scenarios.read",
        "scenarios.create", "scenarios.write", "reports.read", "reports.generate"
    ]),
    ("ml_engineer", "ML Engineer", [
        "ml.read", "ml.train", "ml.predict", "ml.delete", "forecasts.read",
        "forecasts.write", "forecasts.generate", "forecasts.accuracy", "forecasts.compare",
        "scenarios.read", "scenarios.create", "scenarios.write", "reports.read"
    ]),
    ("admin", "System administrator", [
        "users.read", "users.write", "users.delete", "system.read", "system.config",
        "system.logs", "integrations.read", "integrations.write", "integrations.sync",
        "api.read", "api.write"
    ]),
    ("superuser", "Super administrator", [
        "users.admin", "system.config", "system.logs", "system.backup", "api.admin"
    ])
]