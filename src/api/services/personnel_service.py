from sqlalchemy.orm import Session
from sqlalchemy import and_, func
from datetime import datetime
from typing import List, Optional, Dict, Any
import logging

from ..db.models import Agent, Service, Group, agent_group_table
from ..utils.cache import cache_with_timeout
from ..utils.validators import validate_service_id

logger = logging.getLogger(__name__)


class PersonnelService:
    """
    PHASE 1: Core Argus-Compatible Personnel Service
    
    Provides exact Argus endpoint behavior for personnel data.
    Ensures all agents have group assignments and handles static service configuration.
    """
    
    def __init__(self, db: Session):
        self.db = db
    
    @cache_with_timeout(timeout=300)  # 5 minutes cache
    async def get_personnel_data(self, service_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Get personnel data with exact Argus endpoint behavior.
        
        Args:
            service_id: Optional service filter (for static service configuration)
            
        Returns:
            Dict containing personnel data in Argus format
        """
        try:
            # Validate service ID if provided
            if service_id and not validate_service_id(service_id):
                raise ValueError(f"Invalid service_id: {service_id}")
            
            # Build query
            query = self.db.query(Agent).join(
                agent_group_table, Agent.id == agent_group_table.c.agent_id
            ).join(
                Group, agent_group_table.c.group_id == Group.id
            )
            
            # Apply service filter if provided
            if service_id:
                query = query.join(Service, Group.service_id == Service.id).filter(
                    Service.id == service_id
                )
            
            # Execute query
            agents = query.all()
            
            # Format response in Argus format
            personnel_data = []
            for agent in agents:
                agent_data = {
                    "id": agent.id,
                    "name": agent.name,
                    "surname": agent.surname or "",
                    "second_name": agent.second_name or "",
                    "agent_number": agent.agent_number or "",
                    "login_sso": agent.login_sso or "",
                    "email": agent.email or "",
                    "groups": [
                        {
                            "id": group.id,
                            "name": group.name,
                            "service_id": group.service_id,
                            "channel_type": group.channel_type or "",
                            "status": group.status
                        }
                        for group in agent.groups
                    ]
                }
                personnel_data.append(agent_data)
            
            # Ensure all agents have group assignments
            unassigned_agents = [agent for agent in personnel_data if not agent["groups"]]
            if unassigned_agents:
                logger.warning(f"Found {len(unassigned_agents)} agents without group assignments")
                # For Argus compatibility, we'll flag these but not fail
                for agent in unassigned_agents:
                    agent["groups"] = [{"id": "UNASSIGNED", "name": "Unassigned", "service_id": "", "channel_type": "", "status": "INACTIVE"}]
            
            return {
                "status": "success",
                "data": personnel_data,
                "total_count": len(personnel_data),
                "unassigned_count": len(unassigned_agents),
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error getting personnel data: {str(e)}")
            return {
                "status": "error",
                "message": str(e),
                "data": [],
                "timestamp": datetime.utcnow().isoformat()
            }
    
    async def get_agent_by_id(self, agent_id: str) -> Optional[Dict[str, Any]]:
        """
        Get specific agent data by ID.
        
        Args:
            agent_id: Agent identifier
            
        Returns:
            Agent data or None if not found
        """
        try:
            agent = self.db.query(Agent).filter(Agent.id == agent_id).first()
            if not agent:
                return None
            
            return {
                "id": agent.id,
                "name": agent.name,
                "surname": agent.surname or "",
                "second_name": agent.second_name or "",
                "agent_number": agent.agent_number or "",
                "login_sso": agent.login_sso or "",
                "email": agent.email or "",
                "groups": [
                    {
                        "id": group.id,
                        "name": group.name,
                        "service_id": group.service_id,
                        "channel_type": group.channel_type or "",
                        "status": group.status
                    }
                    for group in agent.groups
                ]
            }
            
        except Exception as e:
            logger.error(f"Error getting agent {agent_id}: {str(e)}")
            return None
    
    async def get_service_agents(self, service_id: str) -> List[Dict[str, Any]]:
        """
        Get all agents assigned to a specific service.
        
        Args:
            service_id: Service identifier
            
        Returns:
            List of agents assigned to the service
        """
        try:
            agents = self.db.query(Agent).join(
                agent_group_table, Agent.id == agent_group_table.c.agent_id
            ).join(
                Group, agent_group_table.c.group_id == Group.id
            ).join(
                Service, Group.service_id == Service.id
            ).filter(
                Service.id == service_id
            ).distinct().all()
            
            return [
                {
                    "id": agent.id,
                    "name": agent.name,
                    "surname": agent.surname or "",
                    "second_name": agent.second_name or "",
                    "agent_number": agent.agent_number or "",
                    "login_sso": agent.login_sso or "",
                    "email": agent.email or "",
                    "active_groups": [
                        group.id for group in agent.groups 
                        if group.service_id == service_id and group.status == "ACTIVE"
                    ]
                }
                for agent in agents
            ]
            
        except Exception as e:
            logger.error(f"Error getting service agents for {service_id}: {str(e)}")
            return []
    
    async def validate_agent_assignments(self) -> Dict[str, Any]:
        """
        Validate that all agents have proper group assignments.
        
        Returns:
            Validation report
        """
        try:
            # Get all agents
            total_agents = self.db.query(Agent).count()
            
            # Get agents with group assignments
            agents_with_groups = self.db.query(Agent).join(
                agent_group_table, Agent.id == agent_group_table.c.agent_id
            ).distinct().count()
            
            # Get agents without group assignments
            unassigned_agents = self.db.query(Agent).filter(
                ~Agent.id.in_(
                    self.db.query(agent_group_table.c.agent_id).distinct()
                )
            ).all()
            
            return {
                "total_agents": total_agents,
                "agents_with_groups": agents_with_groups,
                "unassigned_agents": len(unassigned_agents),
                "unassigned_agent_ids": [agent.id for agent in unassigned_agents],
                "assignment_rate": (agents_with_groups / total_agents * 100) if total_agents > 0 else 0,
                "timestamp": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Error validating agent assignments: {str(e)}")
            return {
                "error": str(e),
                "timestamp": datetime.utcnow().isoformat()
            }