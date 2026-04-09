# Ollama batch worker — modèle: qwen3:4b (profil curated, code-first)
export OLLAMA_FLASH_ATTENTION=1        # Flash attention → less RAM
# OLLAMA_KV_CACHE_TYPE=q8_0 retiré — bug Ollama #9683 (KV quant cassé sur gemma3/qwen3, ~16 tok/s vs 55)
export OLLAMA_NUM_PARALLEL=8           # 8 concurrent requests (qwen3:4b = léger, on-demand)
export OLLAMA_MAX_LOADED_MODELS=1      # One model at a time, saves RAM
