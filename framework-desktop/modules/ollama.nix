# Ollama
#
# AMD Strix Halo (gfx1151 / Radeon 8060S) is not yet supported by the ROCm
# backend bundled with Ollama 0.12.x: model weights load to GPU, then the
# runner crashes in hipStreamCreateWithFlags during post-load GPU discovery
# ("llama runner process has terminated: exit status 2" / "ROCm error: out of
# memory" in hipStreamCreateWithFlags). HSA_OVERRIDE_GFX_VERSION=11.0.0 alone
# is not enough on gfx1151.
#
# Force CPU inference until upstream ROCm grows real gfx1151 support. The
# Strix Halo APU has fast unified memory, so CPU inference remains usable.
{ config, pkgs, ... }:

{
  services.ollama = {
    enable = true;
    acceleration = false;
    host = "0.0.0.0";
    environmentVariables = {
      HIP_VISIBLE_DEVICES = "";
      ROCR_VISIBLE_DEVICES = "";
      OLLAMA_LLM_LIBRARY = "cpu";
    };
  };
}
