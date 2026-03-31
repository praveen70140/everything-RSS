import urllib.request
import json
import re

url = "https://raw.githubusercontent.com/DIYgod/RSSHub/master/assets/build/radar-rules.json"
req = urllib.request.Request(url)

try:
    with urllib.request.urlopen(req) as response:
        content = response.read().decode('utf-8')
        data = json.loads(content)
        
        for domain, rules in data.items():
            if 'mastodon' in domain:
                print(f"Domain: {domain}")
                for rule in rules.get('_name', []):
                     print(f"  Rule: {rule}")
except Exception as e:
    print(f"Error: {e}")
