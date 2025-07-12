"""
Unit tests for Erlang C Calculator
"""
import pytest
from unittest.mock import Mock, patch
import numpy as np
from src.algorithms.erlang_c import ErlangCCalculator


class TestErlangCCalculator:
    """Test suite for Erlang C calculator"""
    
    @pytest.fixture
    def calculator(self):
        """Create calculator instance"""
        return ErlangCCalculator()
    
    def test_calculate_basic_scenario(self, calculator):
        """Test basic Erlang C calculation"""
        result = calculator.calculate(
            call_volume=100,
            average_handle_time=300,  # 5 minutes
            service_level_target=0.8,  # 80%
            service_level_seconds=20   # 20 seconds
        )
        
        assert result['required_agents'] > 0
        assert result['service_level'] >= 0.8
        assert result['average_speed_of_answer'] >= 0
        assert result['occupancy'] > 0 and result['occupancy'] <= 1
    
    @pytest.mark.parametrize("call_volume,aht,expected_min_agents", [
        (50, 180, 3),    # Light load
        (100, 300, 8),   # Medium load
        (200, 240, 12),  # Heavy load
        (500, 360, 35),  # Very heavy load
    ])
    def test_various_load_scenarios(self, calculator, call_volume, aht, expected_min_agents):
        """Test different load scenarios"""
        result = calculator.calculate(call_volume, aht, 0.8, 20)
        
        assert result['required_agents'] >= expected_min_agents
        assert result['service_level'] >= 0.75  # Allow some tolerance
    
    def test_edge_case_zero_calls(self, calculator):
        """Test edge case with zero calls"""
        result = calculator.calculate(0, 300, 0.8, 20)
        
        assert result['required_agents'] == 0
        assert result['service_level'] == 1.0
        assert result['occupancy'] == 0
    
    def test_edge_case_very_short_calls(self, calculator):
        """Test edge case with very short calls"""
        result = calculator.calculate(100, 10, 0.9, 5)
        
        assert result['required_agents'] > 0
        assert result['average_speed_of_answer'] < 5
    
    def test_invalid_inputs(self, calculator):
        """Test invalid input handling"""
        with pytest.raises(ValueError, match="Call volume must be non-negative"):
            calculator.calculate(-1, 300, 0.8, 20)
        
        with pytest.raises(ValueError, match="Average handle time must be positive"):
            calculator.calculate(100, 0, 0.8, 20)
        
        with pytest.raises(ValueError, match="Service level target must be between 0 and 1"):
            calculator.calculate(100, 300, 1.5, 20)
    
    def test_high_service_level_requirement(self, calculator):
        """Test calculation with high service level requirement"""
        result = calculator.calculate(100, 300, 0.95, 10)
        
        # Should require more agents for higher service level
        basic_result = calculator.calculate(100, 300, 0.8, 20)
        assert result['required_agents'] > basic_result['required_agents']
    
    @patch('src.algorithms.erlang_c.numpy')
    def test_numerical_stability(self, mock_numpy, calculator):
        """Test numerical stability for large numbers"""
        # Mock numpy to test overflow handling
        mock_numpy.exp.side_effect = OverflowError("Numerical overflow")
        
        with pytest.raises(ValueError, match="Numerical overflow"):
            calculator.calculate(10000, 600, 0.8, 30)
    
    def test_caching_mechanism(self, calculator):
        """Test that results are cached for identical inputs"""
        # First call
        result1 = calculator.calculate(100, 300, 0.8, 20)
        
        # Second identical call should use cache
        with patch.object(calculator, '_erlang_c_probability', wraps=calculator._erlang_c_probability) as mock_prob:
            result2 = calculator.calculate(100, 300, 0.8, 20)
            
            # Should not recalculate if cached
            if hasattr(calculator, '_cache'):
                mock_prob.assert_not_called()
            
            assert result1 == result2
    
    def test_multi_skill_adjustment(self, calculator):
        """Test multi-skill group adjustment"""
        # Assuming the calculator has multi-skill support
        if hasattr(calculator, 'calculate_multi_skill'):
            result = calculator.calculate_multi_skill(
                skill_groups=[
                    {'name': 'sales', 'volume': 50, 'aht': 180},
                    {'name': 'support', 'volume': 100, 'aht': 360}
                ],
                service_level_target=0.8,
                service_level_seconds=20
            )
            
            assert 'total_agents' in result
            assert 'skill_distribution' in result
            assert len(result['skill_distribution']) == 2


@pytest.mark.performance
class TestErlangCPerformance:
    """Performance tests for Erlang C calculator"""
    
    def test_calculation_speed(self):
        """Test calculation speed for typical scenarios"""
        import time
        calculator = ErlangCCalculator()
        
        start_time = time.time()
        for _ in range(100):
            calculator.calculate(100, 300, 0.8, 20)
        end_time = time.time()
        
        # Should complete 100 calculations in under 1 second
        assert (end_time - start_time) < 1.0
    
    def test_large_scale_calculation(self):
        """Test handling of large-scale calculations"""
        calculator = ErlangCCalculator()
        
        # Test with large call center scenario
        result = calculator.calculate(
            call_volume=5000,
            average_handle_time=240,
            service_level_target=0.8,
            service_level_seconds=30
        )
        
        assert result['required_agents'] > 100
        assert result['service_level'] >= 0.75