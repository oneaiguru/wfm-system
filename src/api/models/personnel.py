"""
Personnel Management Models
SQLAlchemy models for comprehensive personnel management including employees, skills, groups, and organizational structure
"""

from sqlalchemy import Column, String, Boolean, DateTime, Text, ForeignKey, Table, Integer, Date, Float, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime, date
import uuid

from ..core.database import Base


# Association tables for many-to-many relationships
employee_skills = Table(
    'personnel_employee_skills',
    Base.metadata,
    Column('employee_id', UUID(as_uuid=True), ForeignKey('personnel_employees.id'), primary_key=True),
    Column('skill_id', UUID(as_uuid=True), ForeignKey('skills.id'), primary_key=True),
    Column('proficiency_level', Integer, nullable=False, default=1),  # 1-5 scale
    Column('certified', Boolean, default=False),
    Column('certification_date', Date, nullable=True),
    Column('created_at', DateTime, default=datetime.utcnow),
    Column('updated_at', DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
)

employee_groups = Table(
    'personnel_employee_groups',
    Base.metadata,
    Column('employee_id', UUID(as_uuid=True), ForeignKey('personnel_employees.id'), primary_key=True),
    Column('group_id', UUID(as_uuid=True), ForeignKey('personnel_groups.id'), primary_key=True),
    Column('joined_at', DateTime, default=datetime.utcnow),
    Column('role', String(50), nullable=True),  # role within the group
    Column('is_active', Boolean, default=True)
)

group_skills = Table(
    'personnel_group_skills',
    Base.metadata,
    Column('group_id', UUID(as_uuid=True), ForeignKey('personnel_groups.id'), primary_key=True),
    Column('skill_id', UUID(as_uuid=True), ForeignKey('personnel_skills.id'), primary_key=True),
    Column('required_level', Integer, nullable=False, default=1),  # minimum required level
    Column('priority', Integer, nullable=False, default=1)  # skill priority for the group
)


class Employee(Base):
    """Employee model with comprehensive information"""
    __tablename__ = "personnel_employees"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    employee_number = Column(String(50), unique=True, nullable=False, index=True)
    
    # Basic information
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, nullable=False, index=True)
    phone = Column(String(20), nullable=True)
    
    # Employment details
    hire_date = Column(Date, nullable=False)
    employment_type = Column(String(50), nullable=False)  # full-time, part-time, contract
    status = Column(String(20), default="active", index=True)  # active, inactive, terminated
    
    # Work details
    position = Column(String(100), nullable=True)
    work_location = Column(String(100), nullable=True)
    work_schedule = Column(String(50), nullable=True)  # standard, flexible, remote
    
    # Compensation
    hourly_rate = Column(Float, nullable=True)
    salary = Column(Float, nullable=True)
    cost_center = Column(String(50), nullable=True)
    
    # Organizational relationships
    department_id = Column(UUID(as_uuid=True), ForeignKey("personnel_departments.id"), nullable=True)
    manager_id = Column(UUID(as_uuid=True), ForeignKey("personnel_employees.id"), nullable=True)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("personnel_organizations.id"), nullable=True)
    
    # Performance metrics
    performance_score = Column(Float, nullable=True)
    availability_score = Column(Float, nullable=True)
    utilization_rate = Column(Float, nullable=True)
    
    # Additional information
    notes = Column(Text, nullable=True)
    metadata = Column(JSON, nullable=True)  # flexible additional data
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    skills = relationship("Skill", secondary=employee_skills, back_populates="employees")
    groups = relationship("Group", secondary=employee_groups, back_populates="members")
    department = relationship("Department", back_populates="employees")
    manager = relationship("Employee", remote_side=[id], backref="direct_reports")
    organization = relationship("Organization", back_populates="employees")
    
    def __repr__(self):
        return f"<Employee(number='{self.employee_number}', name='{self.first_name} {self.last_name}', status='{self.status}')>"
    
    @property
    def full_name(self):
        return f"{self.first_name} {self.last_name}"
    
    def get_skill_level(self, skill_id):
        """Get employee's proficiency level for a specific skill"""
        # This would typically be a database query
        return 1  # Placeholder


class Skill(Base):
    """Skill model for employee competencies"""
    __tablename__ = "personnel_skills"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    category = Column(String(50), nullable=False, index=True)  # technical, soft, language, domain
    
    # Skill metadata
    is_active = Column(Boolean, default=True)
    is_certifiable = Column(Boolean, default=False)
    certification_body = Column(String(100), nullable=True)
    
    # Skill hierarchy
    parent_skill_id = Column(UUID(as_uuid=True), ForeignKey("skills.id"), nullable=True)
    parent_skill = relationship("Skill", remote_side=[id], backref="sub_skills")
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    employees = relationship("Employee", secondary=employee_skills, back_populates="skills")
    groups = relationship("Group", secondary=group_skills, back_populates="required_skills")
    
    def __repr__(self):
        return f"<Skill(name='{self.name}', category='{self.category}')>"


class Group(Base):
    """Group model for teams, departments, and other organizational units"""
    __tablename__ = "personnel_groups"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, index=True)
    description = Column(Text, nullable=True)
    group_type = Column(String(50), nullable=False, index=True)  # team, department, project, skill_group
    
    # Group metadata
    is_active = Column(Boolean, default=True)
    max_members = Column(Integer, nullable=True)
    location = Column(String(100), nullable=True)
    
    # Group hierarchy
    parent_id = Column(UUID(as_uuid=True), ForeignKey("groups.id"), nullable=True)
    parent = relationship("Group", remote_side=[id], backref="children")
    
    # Organizational relationships
    department_id = Column(UUID(as_uuid=True), ForeignKey("departments.id"), nullable=True)
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=True)
    
    # Group leader
    leader_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=True)
    leader = relationship("Employee", foreign_keys=[leader_id], backref="led_groups")
    
    # Additional information
    metadata = Column(JSON, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    members = relationship("Employee", secondary=employee_groups, back_populates="groups")
    required_skills = relationship("Skill", secondary=group_skills, back_populates="groups")
    department = relationship("Department", back_populates="groups")
    organization = relationship("Organization", back_populates="groups")
    
    def __repr__(self):
        return f"<Group(name='{self.name}', type='{self.group_type}', active={self.is_active})>"
    
    @property
    def member_count(self):
        """Get current number of active members"""
        return len([m for m in self.members if m.status == "active"])


class Department(Base):
    """Department model for organizational structure"""
    __tablename__ = "personnel_departments"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, index=True)
    description = Column(Text, nullable=True)
    code = Column(String(20), unique=True, nullable=False, index=True)
    
    # Department metadata
    is_active = Column(Boolean, default=True)
    cost_center = Column(String(50), nullable=True)
    location = Column(String(100), nullable=True)
    
    # Department hierarchy
    parent_id = Column(UUID(as_uuid=True), ForeignKey("departments.id"), nullable=True)
    parent = relationship("Department", remote_side=[id], backref="children")
    
    # Organizational relationships
    organization_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=False)
    
    # Department head
    head_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=True)
    head = relationship("Employee", foreign_keys=[head_id], backref="headed_departments")
    
    # Additional information
    metadata = Column(JSON, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    employees = relationship("Employee", back_populates="department")
    groups = relationship("Group", back_populates="department")
    organization = relationship("Organization", back_populates="departments")
    
    def __repr__(self):
        return f"<Department(name='{self.name}', code='{self.code}')>"


class Organization(Base):
    """Organization model for multi-tenant support"""
    __tablename__ = "personnel_organizations"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), nullable=False, index=True)
    description = Column(Text, nullable=True)
    
    # Organization metadata
    is_active = Column(Boolean, default=True)
    organization_type = Column(String(50), nullable=True)  # company, division, subsidiary
    
    # Contact information
    address = Column(Text, nullable=True)
    phone = Column(String(20), nullable=True)
    email = Column(String(255), nullable=True)
    website = Column(String(255), nullable=True)
    
    # Organization hierarchy
    parent_id = Column(UUID(as_uuid=True), ForeignKey("organizations.id"), nullable=True)
    parent = relationship("Organization", remote_side=[id], backref="children")
    
    # Additional information
    metadata = Column(JSON, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    employees = relationship("Employee", back_populates="organization")
    departments = relationship("Department", back_populates="organization")
    groups = relationship("Group", back_populates="organization")
    
    def __repr__(self):
        return f"<Organization(name='{self.name}', active={self.is_active})>"


class EmployeeSkillAssignment(Base):
    """Employee skill assignment with additional metadata"""
    __tablename__ = "employee_skill_assignments"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=False)
    skill_id = Column(UUID(as_uuid=True), ForeignKey("skills.id"), nullable=False)
    
    # Skill proficiency
    proficiency_level = Column(Integer, nullable=False, default=1)  # 1-5 scale
    certified = Column(Boolean, default=False)
    certification_date = Column(Date, nullable=True)
    certification_expiry = Column(Date, nullable=True)
    
    # Assignment metadata
    assigned_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=True)
    verified_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=True)
    verified_date = Column(Date, nullable=True)
    
    # Performance tracking
    last_used = Column(Date, nullable=True)
    usage_frequency = Column(String(20), nullable=True)  # daily, weekly, monthly, rarely
    
    # Additional information
    notes = Column(Text, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    employee = relationship("Employee", foreign_keys=[employee_id], backref="skill_assignments")
    skill = relationship("Skill", backref="employee_assignments")
    assigner = relationship("Employee", foreign_keys=[assigned_by], backref="assigned_skills")
    verifier = relationship("Employee", foreign_keys=[verified_by], backref="verified_skills")
    
    def __repr__(self):
        return f"<EmployeeSkillAssignment(employee_id={self.employee_id}, skill_id={self.skill_id}, level={self.proficiency_level})>"


class GroupMembership(Base):
    """Group membership with additional metadata"""
    __tablename__ = "group_memberships"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=False)
    group_id = Column(UUID(as_uuid=True), ForeignKey("groups.id"), nullable=False)
    
    # Membership details
    role = Column(String(50), nullable=True)  # role within the group
    is_active = Column(Boolean, default=True)
    is_primary = Column(Boolean, default=False)  # primary group membership
    
    # Membership period
    start_date = Column(Date, nullable=False, default=date.today)
    end_date = Column(Date, nullable=True)
    
    # Assignment metadata
    assigned_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=True)
    
    # Additional information
    notes = Column(Text, nullable=True)
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    employee = relationship("Employee", foreign_keys=[employee_id], backref="group_memberships")
    group = relationship("Group", foreign_keys=[group_id], backref="memberships")
    assigner = relationship("Employee", foreign_keys=[assigned_by], backref="assigned_memberships")
    
    def __repr__(self):
        return f"<GroupMembership(employee_id={self.employee_id}, group_id={self.group_id}, role='{self.role}')>"


class SkillCategory(Base):
    """Skill category for better organization"""
    __tablename__ = "skill_categories"
    
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    
    # Category metadata
    is_active = Column(Boolean, default=True)
    color_code = Column(String(7), nullable=True)  # hex color code
    icon = Column(String(50), nullable=True)
    
    # Category hierarchy
    parent_id = Column(UUID(as_uuid=True), ForeignKey("skill_categories.id"), nullable=True)
    parent = relationship("SkillCategory", remote_side=[id], backref="children")
    
    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    def __repr__(self):
        return f"<SkillCategory(name='{self.name}', active={self.is_active})>"


# Update Skill model to reference SkillCategory
# This would be done via a migration in production
Skill.category_id = Column(UUID(as_uuid=True), ForeignKey("skill_categories.id"), nullable=True)
Skill.skill_category = relationship("SkillCategory", backref="skills")