"""
Personnel Management Schemas
Pydantic models for personnel API request/response validation
"""

from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, EmailStr, validator
from datetime import datetime, date
from uuid import UUID
from enum import Enum


class EmploymentType(str, Enum):
    """Employment type enumeration"""
    FULL_TIME = "full-time"
    PART_TIME = "part-time"
    CONTRACT = "contract"
    INTERN = "intern"
    CONSULTANT = "consultant"


class EmployeeStatus(str, Enum):
    """Employee status enumeration"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    TERMINATED = "terminated"
    ON_LEAVE = "on_leave"
    SUSPENDED = "suspended"


class WorkSchedule(str, Enum):
    """Work schedule enumeration"""
    STANDARD = "standard"
    FLEXIBLE = "flexible"
    REMOTE = "remote"
    HYBRID = "hybrid"


class SkillCategory(str, Enum):
    """Skill category enumeration"""
    TECHNICAL = "technical"
    SOFT = "soft"
    LANGUAGE = "language"
    DOMAIN = "domain"
    CERTIFICATION = "certification"


class GroupType(str, Enum):
    """Group type enumeration"""
    TEAM = "team"
    DEPARTMENT = "department"
    PROJECT = "project"
    SKILL_GROUP = "skill_group"
    COMMITTEE = "committee"


class UsageFrequency(str, Enum):
    """Skill usage frequency enumeration"""
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    RARELY = "rarely"
    NEVER = "never"


# Base schemas
class EmployeeBase(BaseModel):
    """Base employee schema"""
    employee_number: str = Field(..., min_length=1, max_length=50, description="Unique employee identifier")
    first_name: str = Field(..., min_length=1, max_length=100, description="Employee first name")
    last_name: str = Field(..., min_length=1, max_length=100, description="Employee last name")
    email: EmailStr = Field(..., description="Employee email address")
    phone: Optional[str] = Field(None, max_length=20, description="Employee phone number")
    employment_type: EmploymentType = Field(..., description="Type of employment")
    hire_date: date = Field(..., description="Employee hire date")
    position: Optional[str] = Field(None, max_length=100, description="Job position/title")
    work_location: Optional[str] = Field(None, max_length=100, description="Work location")
    work_schedule: Optional[WorkSchedule] = Field(None, description="Work schedule type")
    department_id: Optional[UUID] = Field(None, description="Department ID")
    manager_id: Optional[UUID] = Field(None, description="Manager employee ID")
    organization_id: Optional[UUID] = Field(None, description="Organization ID")
    hourly_rate: Optional[float] = Field(None, ge=0, description="Hourly rate")
    salary: Optional[float] = Field(None, ge=0, description="Annual salary")
    cost_center: Optional[str] = Field(None, max_length=50, description="Cost center code")
    notes: Optional[str] = Field(None, description="Additional notes")
    
    @validator('phone')
    def validate_phone(cls, v):
        if v and not v.replace('+', '').replace('-', '').replace(' ', '').replace('(', '').replace(')', '').isdigit():
            raise ValueError('Phone number must contain only digits, spaces, +, -, (, )')
        return v


class EmployeeCreate(EmployeeBase):
    """Schema for creating an employee"""
    pass


class EmployeeUpdate(BaseModel):
    """Schema for updating an employee"""
    first_name: Optional[str] = Field(None, min_length=1, max_length=100)
    last_name: Optional[str] = Field(None, min_length=1, max_length=100)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, max_length=20)
    employment_type: Optional[EmploymentType] = None
    position: Optional[str] = Field(None, max_length=100)
    work_location: Optional[str] = Field(None, max_length=100)
    work_schedule: Optional[WorkSchedule] = None
    department_id: Optional[UUID] = None
    manager_id: Optional[UUID] = None
    status: Optional[EmployeeStatus] = None
    hourly_rate: Optional[float] = Field(None, ge=0)
    salary: Optional[float] = Field(None, ge=0)
    cost_center: Optional[str] = Field(None, max_length=50)
    notes: Optional[str] = None


class EmployeeResponse(EmployeeBase):
    """Schema for employee response"""
    id: UUID
    status: EmployeeStatus
    performance_score: Optional[float] = None
    availability_score: Optional[float] = None
    utilization_rate: Optional[float] = None
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


class EmployeeListResponse(BaseModel):
    """Schema for employee list response"""
    employees: List[EmployeeResponse]
    total: int
    page: int
    per_page: int
    pages: int


# Skill schemas
class SkillBase(BaseModel):
    """Base skill schema"""
    name: str = Field(..., min_length=1, max_length=100, description="Skill name")
    description: Optional[str] = Field(None, description="Skill description")
    category: SkillCategory = Field(..., description="Skill category")
    is_certifiable: bool = Field(False, description="Whether skill can be certified")
    certification_body: Optional[str] = Field(None, max_length=100, description="Certification body")
    parent_skill_id: Optional[UUID] = Field(None, description="Parent skill ID for hierarchy")


class SkillCreate(SkillBase):
    """Schema for creating a skill"""
    pass


class SkillUpdate(BaseModel):
    """Schema for updating a skill"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    category: Optional[SkillCategory] = None
    is_active: Optional[bool] = None
    is_certifiable: Optional[bool] = None
    certification_body: Optional[str] = Field(None, max_length=100)
    parent_skill_id: Optional[UUID] = None


class SkillResponse(SkillBase):
    """Schema for skill response"""
    id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# Employee skill schemas
class EmployeeSkillBase(BaseModel):
    """Base employee skill schema"""
    skill_id: UUID = Field(..., description="Skill ID")
    proficiency_level: int = Field(..., ge=1, le=5, description="Proficiency level (1-5)")
    certified: bool = Field(False, description="Whether employee is certified")
    certification_date: Optional[date] = Field(None, description="Certification date")
    certification_expiry: Optional[date] = Field(None, description="Certification expiry date")
    last_used: Optional[date] = Field(None, description="Last time skill was used")
    usage_frequency: Optional[UsageFrequency] = Field(None, description="How often skill is used")
    notes: Optional[str] = Field(None, description="Additional notes")


class EmployeeSkillCreate(EmployeeSkillBase):
    """Schema for creating employee skill"""
    pass


class EmployeeSkillUpdate(BaseModel):
    """Schema for updating employee skill"""
    proficiency_level: Optional[int] = Field(None, ge=1, le=5)
    certified: Optional[bool] = None
    certification_date: Optional[date] = None
    certification_expiry: Optional[date] = None
    last_used: Optional[date] = None
    usage_frequency: Optional[UsageFrequency] = None
    notes: Optional[str] = None


class EmployeeSkillResponse(EmployeeSkillBase):
    """Schema for employee skill response"""
    id: UUID
    employee_id: UUID
    skill: SkillResponse
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# Group schemas
class GroupBase(BaseModel):
    """Base group schema"""
    name: str = Field(..., min_length=1, max_length=100, description="Group name")
    description: Optional[str] = Field(None, description="Group description")
    group_type: GroupType = Field(..., description="Type of group")
    max_members: Optional[int] = Field(None, ge=1, description="Maximum number of members")
    location: Optional[str] = Field(None, max_length=100, description="Group location")
    parent_id: Optional[UUID] = Field(None, description="Parent group ID")
    department_id: Optional[UUID] = Field(None, description="Department ID")
    organization_id: Optional[UUID] = Field(None, description="Organization ID")
    leader_id: Optional[UUID] = Field(None, description="Group leader employee ID")


class GroupCreate(GroupBase):
    """Schema for creating a group"""
    pass


class GroupUpdate(BaseModel):
    """Schema for updating a group"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    group_type: Optional[GroupType] = None
    is_active: Optional[bool] = None
    max_members: Optional[int] = Field(None, ge=1)
    location: Optional[str] = Field(None, max_length=100)
    parent_id: Optional[UUID] = None
    department_id: Optional[UUID] = None
    leader_id: Optional[UUID] = None


class GroupResponse(GroupBase):
    """Schema for group response"""
    id: UUID
    is_active: bool
    member_count: int = Field(0, description="Current number of members")
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# Group membership schemas
class GroupMembershipBase(BaseModel):
    """Base group membership schema"""
    employee_id: UUID = Field(..., description="Employee ID")
    group_id: UUID = Field(..., description="Group ID")
    role: Optional[str] = Field(None, max_length=50, description="Role within group")
    is_primary: bool = Field(False, description="Whether this is primary group")
    start_date: date = Field(..., description="Membership start date")
    end_date: Optional[date] = Field(None, description="Membership end date")
    notes: Optional[str] = Field(None, description="Additional notes")


class GroupMembershipCreate(GroupMembershipBase):
    """Schema for creating group membership"""
    pass


class GroupMembershipUpdate(BaseModel):
    """Schema for updating group membership"""
    role: Optional[str] = Field(None, max_length=50)
    is_active: Optional[bool] = None
    is_primary: Optional[bool] = None
    end_date: Optional[date] = None
    notes: Optional[str] = None


class GroupMembershipResponse(GroupMembershipBase):
    """Schema for group membership response"""
    id: UUID
    is_active: bool
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# Organization schemas
class OrganizationBase(BaseModel):
    """Base organization schema"""
    name: str = Field(..., min_length=1, max_length=100, description="Organization name")
    description: Optional[str] = Field(None, description="Organization description")
    organization_type: Optional[str] = Field(None, max_length=50, description="Type of organization")
    address: Optional[str] = Field(None, description="Organization address")
    phone: Optional[str] = Field(None, max_length=20, description="Organization phone")
    email: Optional[EmailStr] = Field(None, description="Organization email")
    website: Optional[str] = Field(None, max_length=255, description="Organization website")
    parent_id: Optional[UUID] = Field(None, description="Parent organization ID")


class OrganizationCreate(OrganizationBase):
    """Schema for creating an organization"""
    pass


class OrganizationUpdate(BaseModel):
    """Schema for updating an organization"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    organization_type: Optional[str] = Field(None, max_length=50)
    is_active: Optional[bool] = None
    address: Optional[str] = None
    phone: Optional[str] = Field(None, max_length=20)
    email: Optional[EmailStr] = None
    website: Optional[str] = Field(None, max_length=255)
    parent_id: Optional[UUID] = None


class OrganizationResponse(OrganizationBase):
    """Schema for organization response"""
    id: UUID
    is_active: bool
    employee_count: int = Field(0, description="Number of employees")
    department_count: int = Field(0, description="Number of departments")
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# Department schemas
class DepartmentBase(BaseModel):
    """Base department schema"""
    name: str = Field(..., min_length=1, max_length=100, description="Department name")
    description: Optional[str] = Field(None, description="Department description")
    code: str = Field(..., min_length=1, max_length=20, description="Department code")
    cost_center: Optional[str] = Field(None, max_length=50, description="Cost center")
    location: Optional[str] = Field(None, max_length=100, description="Department location")
    parent_id: Optional[UUID] = Field(None, description="Parent department ID")
    organization_id: UUID = Field(..., description="Organization ID")
    head_id: Optional[UUID] = Field(None, description="Department head employee ID")


class DepartmentCreate(DepartmentBase):
    """Schema for creating a department"""
    pass


class DepartmentUpdate(BaseModel):
    """Schema for updating a department"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    description: Optional[str] = None
    code: Optional[str] = Field(None, min_length=1, max_length=20)
    is_active: Optional[bool] = None
    cost_center: Optional[str] = Field(None, max_length=50)
    location: Optional[str] = Field(None, max_length=100)
    parent_id: Optional[UUID] = None
    head_id: Optional[UUID] = None


class DepartmentResponse(DepartmentBase):
    """Schema for department response"""
    id: UUID
    is_active: bool
    employee_count: int = Field(0, description="Number of employees")
    group_count: int = Field(0, description="Number of groups")
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True


# Bulk operation schemas
class BulkEmployeeCreate(BaseModel):
    """Schema for bulk employee creation"""
    employees: List[EmployeeCreate] = Field(..., min_items=1, max_items=100, description="List of employees to create")
    validate_unique: bool = Field(True, description="Whether to validate unique constraints")
    continue_on_error: bool = Field(False, description="Whether to continue on individual errors")


class BulkEmployeeUpdate(BaseModel):
    """Schema for bulk employee update"""
    employee_ids: List[UUID] = Field(..., min_items=1, max_items=100, description="List of employee IDs")
    updates: EmployeeUpdate = Field(..., description="Updates to apply")
    

class BulkSkillAssignment(BaseModel):
    """Schema for bulk skill assignment"""
    employee_ids: List[UUID] = Field(..., min_items=1, max_items=100, description="List of employee IDs")
    skills: List[EmployeeSkillCreate] = Field(..., min_items=1, description="List of skills to assign")
    replace_existing: bool = Field(False, description="Whether to replace existing skill assignments")


class BulkGroupAssignment(BaseModel):
    """Schema for bulk group assignment"""
    employee_ids: List[UUID] = Field(..., min_items=1, max_items=100, description="List of employee IDs")
    group_id: UUID = Field(..., description="Group ID to assign to")
    role: Optional[str] = Field(None, max_length=50, description="Role within group")
    replace_existing: bool = Field(False, description="Whether to replace existing group memberships")


class BulkOperationResult(BaseModel):
    """Schema for bulk operation result"""
    success_count: int = Field(0, description="Number of successful operations")
    error_count: int = Field(0, description="Number of failed operations")
    errors: List[Dict[str, Any]] = Field([], description="List of errors")
    warnings: List[str] = Field([], description="List of warnings")
    total_processed: int = Field(0, description="Total number of items processed")


# Search and filter schemas
class EmployeeFilter(BaseModel):
    """Schema for employee search/filter"""
    department_id: Optional[UUID] = None
    manager_id: Optional[UUID] = None
    organization_id: Optional[UUID] = None
    status: Optional[EmployeeStatus] = None
    employment_type: Optional[EmploymentType] = None
    skill_ids: Optional[List[UUID]] = None
    group_ids: Optional[List[UUID]] = None
    hire_date_from: Optional[date] = None
    hire_date_to: Optional[date] = None
    search_text: Optional[str] = Field(None, max_length=100, description="Search in name, email, position")


class SkillFilter(BaseModel):
    """Schema for skill search/filter"""
    category: Optional[SkillCategory] = None
    is_active: Optional[bool] = None
    is_certifiable: Optional[bool] = None
    parent_skill_id: Optional[UUID] = None
    search_text: Optional[str] = Field(None, max_length=100, description="Search in name, description")


class GroupFilter(BaseModel):
    """Schema for group search/filter"""
    group_type: Optional[GroupType] = None
    department_id: Optional[UUID] = None
    organization_id: Optional[UUID] = None
    leader_id: Optional[UUID] = None
    is_active: Optional[bool] = None
    parent_id: Optional[UUID] = None
    search_text: Optional[str] = Field(None, max_length=100, description="Search in name, description")


# Organizational structure schemas
class OrganizationalStructureNode(BaseModel):
    """Schema for organizational structure node"""
    id: UUID
    name: str
    type: str  # organization, department, group, employee
    parent_id: Optional[UUID] = None
    children: List['OrganizationalStructureNode'] = []
    metadata: Dict[str, Any] = {}
    
    class Config:
        from_attributes = True


class OrganizationalStructureResponse(BaseModel):
    """Schema for organizational structure response"""
    organization: OrganizationalStructureNode
    total_nodes: int
    depth: int
    

# Update forward references
OrganizationalStructureNode.model_rebuild()


# Statistics schemas
class EmployeeStatistics(BaseModel):
    """Schema for employee statistics"""
    total_employees: int
    active_employees: int
    inactive_employees: int
    by_department: Dict[str, int]
    by_employment_type: Dict[str, int]
    by_status: Dict[str, int]
    average_tenure_months: float
    

class SkillStatistics(BaseModel):
    """Schema for skill statistics"""
    total_skills: int
    active_skills: int
    by_category: Dict[str, int]
    certifiable_skills: int
    most_common_skills: List[Dict[str, Any]]
    

class GroupStatistics(BaseModel):
    """Schema for group statistics"""
    total_groups: int
    active_groups: int
    by_type: Dict[str, int]
    average_group_size: float
    largest_groups: List[Dict[str, Any]]


# Legacy schemas for backward compatibility
class ServiceBase(BaseModel):
    """Legacy service schema for backward compatibility"""
    id: str = Field(..., description="Service identifier")
    name: str = Field(..., description="Service name")
    status: str = Field(default="ACTIVE", description="Service status")
    is_static: bool = Field(False, description="Static service flag")


class Service(ServiceBase):
    """Legacy service schema with timestamps"""
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")


class AgentBase(BaseModel):
    """Legacy agent schema for backward compatibility"""
    id: str = Field(..., description="Agent identifier")
    name: str = Field(..., description="Agent name")
    surname: Optional[str] = Field(None, description="Agent surname")
    second_name: Optional[str] = Field(None, description="Agent second name")
    agent_number: Optional[str] = Field(None, description="Agent number")
    login_sso: Optional[str] = Field(None, description="SSO login")
    email: Optional[str] = Field(None, description="Agent email")


class Agent(AgentBase):
    """Legacy agent schema with timestamps and relationships"""
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    groups: List[GroupResponse] = Field(default=[], description="Agent groups")


class PersonnelResponse(BaseModel):
    """Legacy personnel response schema for backward compatibility"""
    services: List[Service] = Field(..., description="All services")
    agents: List[Agent] = Field(..., description="All agents with their groups")