# Raycast MCP
When user shares/references a screenshot, capture, or clipboard content:
- Clipboard → `mcp__mcp-raycast-clipboard__clipboard_read`
- Recent screenshots → `mcp__mcp-raycast-clipboard__raycast_recent_images`
- Preview (token-efficient) → `get_thumbnail` then Read if needed
- Metadata only → `get_image_metadata`
