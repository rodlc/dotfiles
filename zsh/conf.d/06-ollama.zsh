# Ollama performance (M3 Pro 36 GB)
export OLLAMA_FLASH_ATTENTION=1        # Flash attention → less RAM, enables KV quant
export OLLAMA_KV_CACHE_TYPE=q8_0       # KV cache size / 2 vs f16
export OLLAMA_KEEP_ALIVE=24h           # Keep model in RAM (default 5m = cold starts)
export OLLAMA_NUM_PARALLEL=1           # MCP = single request, no need for more
export OLLAMA_MAX_LOADED_MODELS=1      # One model at a time, saves RAM
