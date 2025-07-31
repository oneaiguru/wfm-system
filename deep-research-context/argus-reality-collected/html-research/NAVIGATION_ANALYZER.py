#!/usr/bin/env python3
"""
Argus Navigation Analyzer
Analyzes saved HTML pages to create navigation map for R-agents
"""

import os
import zipfile
import re
import json
import yaml
from pathlib import Path
from bs4 import BeautifulSoup
from collections import defaultdict

class ArgusNavigationAnalyzer:
    def __init__(self, zip_dir="/Users/m/Documents/wfm/main/agents/HTML-RESERACH"):
        self.zip_dir = Path(zip_dir)
        self.navigation_map = defaultdict(dict)
        self.url_patterns = {}
        self.menu_items = []
        self.forms_catalog = {}
        
    def analyze_all_zips(self):
        """Analyze all zip files in the directory"""
        zip_files = list(self.zip_dir.glob("*.zip"))
        
        print(f"Found {len(zip_files)} zip files to analyze...")
        
        for zip_file in zip_files:  # Process all files
            print(f"Analyzing {zip_file.name}...")
            self.analyze_zip(zip_file)
            
        self.generate_navigation_map()
        self.save_results()
        
    def analyze_zip(self, zip_file):
        """Analyze a single zip file"""
        try:
            with zipfile.ZipFile(zip_file, 'r') as zf:
                for file_info in zf.filelist:
                    if file_info.filename.endswith('.xhtml') or file_info.filename.endswith('.html'):
                        try:
                            content = zf.read(file_info.filename).decode('utf-8', errors='ignore')
                            self.analyze_page(file_info.filename, content)
                        except Exception as e:
                            print(f"Error reading {file_info.filename}: {e}")
        except Exception as e:
            print(f"Error processing {zip_file}: {e}")
            
    def analyze_page(self, filename, content):
        """Analyze a single HTML page"""
        soup = BeautifulSoup(content, 'html.parser')
        
        # Extract URL pattern
        url = self.extract_url_from_filename(filename)
        
        # Extract breadcrumbs
        breadcrumbs = self.extract_breadcrumbs(soup)
        
        # Extract menu items
        menu_items = self.extract_menu_items(soup)
        
        # Extract forms and inputs
        forms = self.extract_forms(soup)
        
        # Extract page title
        title = self.extract_title(soup)
        
        # Extract key UI elements
        buttons = self.extract_buttons(soup)
        
        # Determine feature type
        feature = self.classify_feature(url, title, forms, buttons)
        
        if feature:
            self.navigation_map[feature] = {
                'url': url,
                'title': title,
                'breadcrumbs': breadcrumbs,
                'forms': forms,
                'buttons': buttons,
                'menu_items': menu_items
            }
            
    def extract_url_from_filename(self, filename):
        """Extract URL pattern from filename"""
        # Remove domain and convert to URL
        url = filename.replace('cc1010wfmcc.argustelecom.ru/', '')
        url = url.replace('lkcc1010wfmcc.argustelecom.ru/', '')
        return '/' + url if not url.startswith('/') else url
        
    def extract_breadcrumbs(self, soup):
        """Extract breadcrumb navigation"""
        breadcrumbs = []
        
        # Common breadcrumb patterns
        breadcrumb_selectors = [
            '.breadcrumb',
            '.breadcrumbs', 
            '[data-testid*="breadcrumb"]',
            '.ui-breadcrumb'
        ]
        
        for selector in breadcrumb_selectors:
            elements = soup.select(selector)
            for elem in elements:
                text = elem.get_text(strip=True)
                if text and '>' in text:
                    breadcrumbs.append(text)
                    
        return breadcrumbs
        
    def extract_menu_items(self, soup):
        """Extract menu items and navigation"""
        menu_items = []
        
        # Look for navigation menus
        nav_elements = soup.find_all(['nav', 'ul', 'div'], class_=re.compile(r'menu|nav|sidebar'))
        
        for nav in nav_elements:
            links = nav.find_all('a')
            for link in links:
                text = link.get_text(strip=True)
                href = link.get('href', '')
                if text and len(text) > 1:
                    menu_items.append({'text': text, 'href': href})
                    
        return menu_items
        
    def extract_forms(self, soup):
        """Extract forms and input fields"""
        forms = []
        
        for form in soup.find_all('form'):
            form_data = {
                'action': form.get('action', ''),
                'method': form.get('method', 'GET'),
                'inputs': []
            }
            
            # Find all inputs
            for input_elem in form.find_all(['input', 'select', 'textarea']):
                input_data = {
                    'name': input_elem.get('name', ''),
                    'type': input_elem.get('type', 'text'),
                    'placeholder': input_elem.get('placeholder', ''),
                    'value': input_elem.get('value', '')
                }
                form_data['inputs'].append(input_data)
                
            forms.append(form_data)
            
        return forms
        
    def extract_title(self, soup):
        """Extract page title"""
        title_elem = soup.find('title')
        if title_elem:
            return title_elem.get_text(strip=True)
            
        # Try h1 as fallback
        h1_elem = soup.find('h1')
        if h1_elem:
            return h1_elem.get_text(strip=True)
            
        return ""
        
    def extract_buttons(self, soup):
        """Extract buttons and key actions"""
        buttons = []
        
        button_elements = soup.find_all(['button', 'input', 'a'], 
                                      attrs={'type': re.compile(r'button|submit'),
                                            'class': re.compile(r'btn|button|action')})
        
        for btn in button_elements:
            text = btn.get_text(strip=True) or btn.get('value', '')
            if text:
                buttons.append(text)
                
        return buttons
        
    def classify_feature(self, url, title, forms, buttons):
        """Classify what feature this page represents"""
        url_lower = url.lower()
        title_lower = title.lower()
        
        # Vacation request patterns
        if any(word in url_lower for word in ['vacation', 'request', 'calendar']):
            if any(word in title_lower for word in ['календарь', 'отпуск', 'заявка']):
                return 'vacation_request'
                
        # Employee management
        if any(word in url_lower for word in ['employee', 'personnel']):
            if any(word in title_lower for word in ['сотрудник', 'персонал']):
                return 'employee_management'
                
        # Manager dashboard
        if any(word in url_lower for word in ['manager', 'dashboard']):
            return 'manager_dashboard'
            
        # Schedule
        if any(word in url_lower for word in ['schedule', 'planning']):
            return 'schedule_management'
            
        # Authentication
        if any(word in url_lower for word in ['login', 'auth', 'signin']):
            return 'authentication'
            
        return None
        
    def generate_navigation_map(self):
        """Generate the final navigation map in YAML format"""
        navigation_yaml = {
            'ARGUS_NAVIGATION_MAP': {}
        }
        
        for feature, data in self.navigation_map.items():
            navigation_yaml['ARGUS_NAVIGATION_MAP'][feature] = {
                'url': data['url'],
                'title': data['title'],
                'breadcrumbs': data['breadcrumbs'][0] if data['breadcrumbs'] else '',
                'key_buttons': data['buttons'][:3],  # Top 3 buttons
                'forms_count': len(data['forms'])
            }
            
        self.final_map = navigation_yaml
        
    def save_results(self):
        """Save analysis results"""
        # Save YAML navigation map
        with open(self.zip_dir / 'NAVIGATION_MAP.yaml', 'w', encoding='utf-8') as f:
            yaml.dump(self.final_map, f, default_flow_style=False, allow_unicode=True)
            
        # Save detailed JSON analysis
        with open(self.zip_dir / 'DETAILED_ANALYSIS.json', 'w', encoding='utf-8') as f:
            json.dump(dict(self.navigation_map), f, indent=2, ensure_ascii=False)
            
        print("✅ Navigation analysis complete!")
        print(f"📁 Saved NAVIGATION_MAP.yaml ({len(self.navigation_map)} features)")
        print(f"📁 Saved DETAILED_ANALYSIS.json")

if __name__ == "__main__":
    analyzer = ArgusNavigationAnalyzer()
    analyzer.analyze_all_zips()