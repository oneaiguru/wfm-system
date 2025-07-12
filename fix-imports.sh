#!/bin/bash

# WFM Enterprise Import Path Fix Script
# Fixes critical import errors preventing server startup

echo "🔧 Fixing import paths for demo..."

# Fix personnel employees.py
echo "📝 Fixing personnel/employees.py..."
sed -i '' 's/from \.\.\.\.auth\.dependencies/from \.\.\.auth\.dependencies/g' src/api/v1/endpoints/personnel/employees.py

# Fix personnel skills.py
echo "📝 Fixing personnel/skills.py..."
sed -i '' 's/from \.\.\.\.auth\.dependencies/from \.\.\.auth\.dependencies/g' src/api/v1/endpoints/personnel/skills.py

# Fix personnel groups.py
echo "📝 Fixing personnel/groups.py..."
sed -i '' 's/from \.\.\.\.auth\.dependencies/from \.\.\.auth\.dependencies/g' src/api/v1/endpoints/personnel/groups.py

# Fix personnel organization.py
echo "📝 Fixing personnel/organization.py..."
sed -i '' 's/from \.\.\.\.auth\.dependencies/from \.\.\.auth\.dependencies/g' src/api/v1/endpoints/personnel/organization.py

# Fix personnel bulk_operations.py
echo "📝 Fixing personnel/bulk_operations.py..."
sed -i '' 's/from \.\.\.\.auth\.dependencies/from \.\.\.auth\.dependencies/g' src/api/v1/endpoints/personnel/bulk_operations.py

# Fix schedules imports
echo "📝 Fixing schedules imports..."
find src/api/v1/endpoints/schedules/ -name "*.py" -exec sed -i '' 's/from \.\.\.\.auth\.dependencies/from \.\.\.auth\.dependencies/g' {} \;

# Fix forecasting imports
echo "📝 Fixing forecasting imports..."
find src/api/v1/endpoints/forecasting/ -name "*.py" -exec sed -i '' 's/from \.\.\.\.auth\.dependencies/from \.\.\.auth\.dependencies/g' {} \;

# Fix integrations imports
echo "📝 Fixing integrations imports..."
find src/api/v1/endpoints/integrations/ -name "*.py" -exec sed -i '' 's/from \.\.\.\.auth\.dependencies/from \.\.\.auth\.dependencies/g' {} \;

echo "✅ Import paths fixed!"

# Test basic import
echo "🧪 Testing basic import..."
cd /Users/m/Documents/wfm/main/project
python3 -c "
try:
    from src.api.core.config import settings
    print('✅ Config import works')
except Exception as e:
    print(f'❌ Config import failed: {e}')

try:
    from src.api.auth.dependencies import get_current_user
    print('✅ Auth dependencies import works')
except Exception as e:
    print(f'❌ Auth dependencies import failed: {e}')
"

echo "🎯 Import fix complete!"