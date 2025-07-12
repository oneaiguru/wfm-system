"""
Algorithm Adapter for standardizing interfaces between API and algorithm modules
"""
from typing import Dict, Any


class AlgorithmAdapter:
    """Adapter to standardize algorithm interfaces"""
    
    @staticmethod
    def erlang_c_calculate(calculator, lambda_rate: float, mu_rate: float, 
                          num_agents: int, target_service_level: float = 0.8) -> Dict[str, Any]:
        """
        Standardized interface for Erlang C calculations
        
        Args:
            calculator: ErlangCEnhanced instance
            lambda_rate: Arrival rate (calls/hour)
            mu_rate: Service rate (calls/hour/agent)
            num_agents: Number of agents
            target_service_level: Target service level (0-1)
            
        Returns:
            Dict with calculation results
        """
        # Calculate offered load
        offered_load = calculator.calculate_offered_load(lambda_rate, mu_rate)
        
        # Calculate utilization
        utilization = calculator.calculate_utilization(lambda_rate, num_agents, mu_rate)
        
        # Calculate wait probability using erlang_c_probability
        wait_prob = calculator.erlang_c_probability(offered_load, num_agents)
        
        # Calculate service level
        # Assuming 20 second target wait time (standard for call centers)
        target_wait_seconds = 20
        avg_service_time = 3600 / mu_rate  # Convert to seconds
        
        # P(Wait <= t) = 1 - P(Wait > 0) * exp(-s * mu * t / 3600)
        service_level = 1 - wait_prob * math.exp(-num_agents * mu_rate * target_wait_seconds / 3600)
        
        # Calculate average wait time for those who wait
        if wait_prob > 0 and utilization < 1:
            avg_wait_time = wait_prob * avg_service_time / (num_agents * (1 - utilization))
        else:
            avg_wait_time = 0
            
        return {
            "offered_load": offered_load,
            "utilization": utilization,
            "probability_wait": wait_prob,
            "service_level": service_level,
            "average_wait_time": avg_wait_time,
            "num_agents": num_agents,
            "arrival_rate": lambda_rate,
            "service_rate": mu_rate
        }


import math  # Add at module level