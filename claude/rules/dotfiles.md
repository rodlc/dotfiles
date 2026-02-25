# Dotfiles & Configuration
Source dotfiles: ~/Code/rodlc/dotfiles/ | Workspace: ~/Code/rodlc/workspace/
Source claude config: ~/Code/rodlc/dotfiles/claude/ — query memory (tags: dotfiles, mcp) before edits
Paths: NEVER hardcode username. Use $HOME (shell), Path.home() (python),
       __HOME__ (plists), ~/ (claude settings), ${HOME} (mcp.json templates)
Plists: always use __HOME__ placeholder, sed at install time
MCP config: .mcp.json is a template, expanded by mcp-sync.sh (envsubst)
Install: install.sh (system+dotfiles) then workspace-install.sh (MCP servers)
