# llama-server model presets shared by every host: the chat model
# scripts/ask.py asks for with --local, and the embedding model.
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

  # ~330 MB, small enough to keep resident. Pooling comes from the GGUF
  # metadata; ctx-size is the model's maximum.
  "embeddinggemma-300m" = {
    hf-repo = "ggml-org/embeddinggemma-300m-qat-q8_0-GGUF";
    hf-file = "embeddinggemma-300m-qat-Q8_0.gguf";
    alias = "google/embeddinggemma-300m";
    embedding = "true";
    ctx-size = "2048";
    load-on-startup = "true";
  };
}
