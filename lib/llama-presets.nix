# llama-server model presets shared by every host: the chat model
# scripts/ask.py asks for with --local, and two Qwen3 embedders.
#
# Keys are long llama-server flags without the dashes. Nothing here may be
# newer than b9190 (nixos-26.05), which melpomene and thalia run — kalliope
# is on v0.3.0 and would accept more.
#
# Hosts merge these with their own presets — see hosts/*/configuration.nix
# and home/thalia.nix.
{
  # QAT weights, so Q4 costs little quality. ~4.2 GB.
  "gemma-4-E4B" = {
    hf-repo = "unsloth/gemma-4-E4B-it-qat-GGUF";
    hf-file = "gemma-4-E4B-it-qat-UD-Q4_K_XL.gguf";
    alias = "unsloth/gemma-4-E4B-it";
    jinja = "on";
    ctx-size = "8192";
    sleep-idle-seconds = "600";
  };

  # Embedders. An embedding input must fit in one ubatch (default 512), so
  # the batch sizes match ctx-size. Pooling is last-token, per the model card.
  "Qwen3-Embedding-8B" = {
    hf-repo = "Qwen/Qwen3-Embedding-8B-GGUF";
    hf-file = "Qwen3-Embedding-8B-Q8_0.gguf";
    alias = "Qwen/Qwen3-Embedding-8B";
    embedding = "true";
    pooling = "last";
    ctx-size = "8192";
    batch-size = "8192";
    ubatch-size = "8192";
    sleep-idle-seconds = "600";
  };

  # ~0.6 GB, small enough to keep resident.
  "Qwen3-Embedding-0.6B" = {
    hf-repo = "Qwen/Qwen3-Embedding-0.6B-GGUF";
    hf-file = "Qwen3-Embedding-0.6B-Q8_0.gguf";
    alias = "Qwen/Qwen3-Embedding-0.6B";
    embedding = "true";
    pooling = "last";
    ctx-size = "8192";
    batch-size = "8192";
    ubatch-size = "8192";
    load-on-startup = "true";
  };
}
