#!/usr/bin/env python3
"""
Simple web proxy server that forwards requests through SOCKS proxy
Creates browser isolation for ChatGPT Agent
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import requests
import json
from urllib.parse import urlparse, parse_qs
import webbrowser

class ProxyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/':
            # Serve simple interface
            self.send_response(200)
            self.send_header('Content-type', 'text/html')
            self.end_headers()
            
            html = """
            <!DOCTYPE html>
            <html>
            <head>
                <title>Workforce Management Testing Environment</title>
                <style>
                    body { margin: 0; padding: 20px; font-family: Arial, sans-serif; }
                    .container { max-width: 800px; margin: 0 auto; }
                    .btn { background: #007bff; color: white; padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; margin: 10px; }
                    .status { background: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }
                    iframe { width: 100%; height: 600px; border: 1px solid #ddd; border-radius: 5px; }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>🏢 Workforce Management Testing Environment</h1>
                    <div class="status">
                        <strong>Status:</strong> Browser isolation active<br>
                        <strong>IP Routing:</strong> Russian proxy (37.113.128.115)<br>
                        <strong>Target:</strong> Argus WFM System
                    </div>
                    
                    <h2>Access Points:</h2>
                    <button class="btn" onclick="loadAdmin()">🔐 Admin Interface</button>
                    <button class="btn" onclick="loadEmployee()">👤 Employee Portal</button>
                    <button class="btn" onclick="loadIP()">🌐 IP Verification</button>
                    
                    <div id="iframe-container" style="margin-top: 20px;">
                        <p>Click a button above to load the corresponding interface in isolated environment.</p>
                    </div>
                </div>
                
                <script>
                function loadAdmin() {
                    document.getElementById('iframe-container').innerHTML = 
                        '<iframe src="/proxy?url=https://cc1010wfmcc.argustelecom.ru/ccwfm/"></iframe>';
                }
                function loadEmployee() {
                    document.getElementById('iframe-container').innerHTML = 
                        '<iframe src="/proxy?url=https://lkcc1010wfmcc.argustelecom.ru/"></iframe>';
                }
                function loadIP() {
                    document.getElementById('iframe-container').innerHTML = 
                        '<iframe src="/proxy?url=https://icanhazip.com"></iframe>';
                }
                </script>
            </body>
            </html>
            """
            self.wfile.write(html.encode())
            
        elif self.path.startswith('/proxy'):
            # Extract target URL
            query = parse_qs(urlparse(self.path).query)
            target_url = query.get('url', [''])[0]
            
            if target_url:
                try:
                    # Make request through SOCKS proxy
                    proxies = {
                        'http': 'socks5://127.0.0.1:1080',
                        'https': 'socks5://127.0.0.1:1080'
                    }
                    
                    response = requests.get(target_url, proxies=proxies, timeout=10)
                    
                    self.send_response(200)
                    self.send_header('Content-type', response.headers.get('content-type', 'text/html'))
                    self.send_header('Access-Control-Allow-Origin', '*')
                    self.end_headers()
                    self.wfile.write(response.content)
                    
                except Exception as e:
                    self.send_response(500)
                    self.send_header('Content-type', 'text/html')
                    self.end_headers()
                    error_html = f"<h1>Proxy Error</h1><p>Could not fetch: {target_url}</p><p>Error: {str(e)}</p>"
                    self.wfile.write(error_html.encode())
            else:
                self.send_response(400)
                self.end_headers()
                
    def log_message(self, format, *args):
        pass  # Suppress logs

if __name__ == '__main__':
    server = HTTPServer(('localhost', 8090), ProxyHandler)
    print("🌐 Workforce Management Testing Environment")
    print("📍 Running at: http://localhost:8090")
    print("🚀 Ready for ChatGPT Agent testing!")
    
    # Auto-open browser
    webbrowser.open('http://localhost:8090')
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped")
        server.shutdown()
