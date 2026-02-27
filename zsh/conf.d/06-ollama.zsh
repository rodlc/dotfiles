# Ollama batch worker (M3 Pro 36 GB)
export OLLAMA_FLASH_ATTENTION=1        # Flash attention → less RAM, enables KV quant
export OLLAMA_KV_CACHE_TYPE=q8_0       # KV cache size / 2 vs f16
export OLLAMA_NUM_PARALLEL=8           # 8 concurrent requests (qwen3:4b = léger, on-demand)
export OLLAMA_MAX_LOADED_MODELS=1      # One model at a time, saves RAM
