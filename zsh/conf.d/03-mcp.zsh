# MCP Notion timeout configuration
export MCP_TIMEOUT=30000

# MCP Memory - Dream consolidation
export MCP_CONSOLIDATION_ENABLED=true

# Quality scoring optimized for technical content
# Disable AI scoring (DeBERTa/MS-MARCO have prose bias, undervalue technical content)
export MCP_QUALITY_AI_PROVIDER=none
export MCP_QUALITY_SYSTEM_ENABLED=true
export MCP_QUALITY_BOOST_ENABLED=false  # Rely on implicit signals only (access, recency, ranking)

# Association-based quality boost
export MCP_CONSOLIDATION_QUALITY_BOOST_ENABLED=true
export MCP_CONSOLIDATION_MIN_CONNECTIONS_FOR_BOOST=3
export MCP_CONSOLIDATION_QUALITY_BOOST_FACTOR=1.2

# Graph storage for associations persistence
export GRAPH_STORAGE_MODE=dual_write

# Consolidation scheduling (APScheduler)
export MCP_CONSOLIDATION_SCHEDULE_DAILY="14:00"
export MCP_CONSOLIDATION_SCHEDULE_WEEKLY="SUN 14:00"
export MCP_CONSOLIDATION_SCHEDULE_MONTHLY="01 14:00"
export MCP_CONSOLIDATION_SCHEDULE_QUARTERLY="disabled"
export MCP_CONSOLIDATION_SCHEDULE_YEARLY="disabled"

# Enabled phases per horizon
# DISABLED: Associations/Compression create additive noise (771 associations + 26 clusters cleaned 2025-01)
export MCP_CONSOLIDATION_ENABLED_PHASES_ASSOCIATIONS="disabled"
export MCP_CONSOLIDATION_ENABLED_PHASES_COMPRESSION="disabled"
export MCP_CONSOLIDATION_ENABLED_PHASES_CLUSTERING="disabled"
export MCP_CONSOLIDATION_ENABLED_PHASES_FORGETTING="disabled"

# Retention periods by memory type (days)
export MCP_CONSOLIDATION_RETENTION_CRITICAL=365    # T1 equivalent
export MCP_CONSOLIDATION_RETENTION_REFERENCE=180   # T2 equivalent
export MCP_CONSOLIDATION_RETENTION_STANDARD=90     # T3 equivalent
export MCP_CONSOLIDATION_RETENTION_TEMPORARY=30    # T4 equivalent
