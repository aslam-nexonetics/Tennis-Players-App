import http.server
import socketserver
import urllib.parse
import os

PORT = 8089
SAVE_DIR = "/home/nexonetics/nexonetics/tennis_app/scratch/scraped_html"

class HTMLReceiverHandler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        parsed_url = urllib.parse.urlparse(self.path)
        if parsed_url.path == "/save":
            query_params = urllib.parse.parse_qs(parsed_url.query)
            filename = query_params.get("filename", ["temp.html"])[0]
            
            # Clean filename to prevent traversal
            filename = os.path.basename(filename)
            if not filename.endswith(".html"):
                filename += ".html"
                
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            
            os.makedirs(SAVE_DIR, exist_ok=True)
            filepath = os.path.join(SAVE_DIR, filename)
            
            with open(filepath, "wb") as f:
                f.write(post_data)
                
            print(f"Saved {len(post_data)} bytes to {filepath}")
            
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b"Success")
        else:
            self.send_response(404)
            self.end_headers()
            
    def do_OPTIONS(self):
        # Handle CORS preflight
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, GET, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

def main():
    os.makedirs(SAVE_DIR, exist_ok=True)
    with socketserver.TCPServer(("", PORT), HTMLReceiverHandler) as httpd:
        print(f"Receiver server running on port {PORT}...")
        httpd.serve_forever()

if __name__ == "__main__":
    main()
