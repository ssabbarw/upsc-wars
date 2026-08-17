"""
debug_api.py
Run this to see exactly what the Anthropic API returns.
Cheap test — small prompt, no retries.
"""

import os
import anthropic
from dotenv import load_dotenv

load_dotenv()

client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

print("Sending test request...")

response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=500,
    system="You are a helpful assistant. Always respond with valid JSON only.",
    tools=[{"type": "web_search_20250305", "name": "web_search"}],
    messages=[{
        "role": "user",
        "content": "What is today's date? Return JSON: {\"date\": \"YYYY-MM-DD\"}"
    }]
)

print(f"\nStop reason: {response.stop_reason}")
print(f"Number of blocks: {len(response.content)}")
print()

for i, block in enumerate(response.content):
    print(f"Block {i}: type={block.type}")
    if hasattr(block, 'text'):
        print(f"  text preview: {block.text[:300]}")
    if hasattr(block, 'name'):
        print(f"  tool name: {block.name}")
    if hasattr(block, 'input'):
        print(f"  tool input: {block.input}")
    print()