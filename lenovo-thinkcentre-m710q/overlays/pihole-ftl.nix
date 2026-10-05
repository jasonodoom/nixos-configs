# pihole-ftl 6.7.1 trips -Werror=unused-but-set-variable on a newer GCC
# (src/config/validator.c). Upstream has not fixed the dead variable, so
# demote that one warning and leave the rest of -Werror alone.
# Drop this overlay once upstream removes the variable.
final: prev: {
  pihole-ftl = prev.pihole-ftl.overrideAttrs (old: {
    env = (old.env or { }) // {
      NIX_CFLAGS_COMPILE = toString [
        (old.env.NIX_CFLAGS_COMPILE or "")
        "-Wno-error=unused-but-set-variable"
      ];
    };
  });
}
