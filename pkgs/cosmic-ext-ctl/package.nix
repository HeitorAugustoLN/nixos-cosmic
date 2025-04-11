{
  lib,
  fetchFromGitHub,
  rustPlatform,
  nix-update-script,
}:

rustPlatform.buildRustPackage {
  pname = "cosmic-ext-ctl";
  version = "1.3.0-unstable-2025-04-11";

  src = fetchFromGitHub {
    owner = "cosmic-utils";
    repo = "cosmic-ctl";
    rev = "287b49173d4ffc0d244d164f2758dd38121d94d8";
    hash = "sha256-xvjLbJcTgmxb154s6sEuxVPhwuHel5QyE+Ktplwzh1s=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-FZ2RLnDCmfKJxwtnVpI9zE3G9mR4EbGfnjNuGhHIqDI=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "CLI for COSMIC Desktop Environment configuration management";
    homepage = "https://github.com/cosmic-utils/cosmic-ctl";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      # lilyinstarlight
    ];
    platforms = lib.platforms.linux;
    mainProgram = "cosmic-ctl";
  };
}
