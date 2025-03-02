{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  libcosmicAppHook,
  cmake,
  cosmic-randr,
  expat,
  fontconfig,
  freetype,
  just,
  libclang,
  libinput,
  mold,
  pipewire,
  pkg-config,
  pulseaudio,
  udev,
  util-linux,
  xkeyboard_config,
  nix-update-script,

  withMoldLinker ? builtins.all (lib.meta.availableOn stdenv.hostPlatform) [
    libclang
    mold
  ],
}:

let
  libcosmicAppHook' = (libcosmicAppHook.__spliced.buildHost or libcosmicAppHook).override {
    includeSettings = false;
  };

  inherit (stdenv.hostPlatform.rust) cargoEnvVarTarget;
in

rustPlatform.buildRustPackage {
  pname = "cosmic-settings";
  version = "1.0.0-alpha.6-unstable-2025-02-28";

  src = fetchFromGitHub {
    owner = "pop-os";
    repo = "cosmic-settings";
    rev = "95e77491c5b713bbef20e2ae1b52b7d20399e90b";
    hash = "sha256-z4xsieGHw2UiBlAatn3+UWindoLO1hnOMKL01FBlD+k=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-OhkpJYe9Nfo8wqozamKfhPcPlaGmS0suGc43inLf/U0=";

  nativeBuildInputs =
    [
      libcosmicAppHook'
      rustPlatform.bindgenHook
      cmake
      just
      pkg-config
      util-linux
    ]
    ++ lib.optionals withMoldLinker [
      libclang
      mold
    ];
  buildInputs = [
    expat
    fontconfig
    freetype
    libinput
    pipewire
    pulseaudio
    udev
  ];

  dontUseJustBuild = true;
  dontUseJustCheck = true;

  postConfigure = lib.optionalString withMoldLinker ''
    if [ -n "''${CARGO_TARGET_${cargoEnvVarTarget}_RUSTFLAGS+x}" ]; then
      export CARGO_TARGET_${cargoEnvVarTarget}_RUSTFLAGS="-C linker=${lib.getExe libclang} -C link-arg=--ld-path=${lib.getExe mold} $CARGO_TARGET_${cargoEnvVarTarget}_RUSTFLAGS"
    else
      export CARGO_TARGET_${cargoEnvVarTarget}_RUSTFLAGS="-C linker=${lib.getExe libclang} -C link-arg=--ld-path=${lib.getExe mold}"
    fi
  '';

  justFlags = [
    "--set"
    "prefix"
    (placeholder "out")
    "--set"
    "bin-src"
    "target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/cosmic-settings"
  ];

  postInstall = ''
    libcosmicAppWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ cosmic-randr ]})
    libcosmicAppWrapperArgs+=(--set-default X11_BASE_RULES_XML ${xkeyboard_config}/share/X11/xkb/rules/base.xml)
    libcosmicAppWrapperArgs+=(--set-default X11_EXTRA_RULES_XML ${xkeyboard_config}/share/X11/xkb/rules/base.extras.xml)
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version-regex"
      "epoch-(.*)"
    ];
  };

  meta = {
    homepage = "https://github.com/pop-os/cosmic-settings";
    description = "Settings for the COSMIC Desktop Environment";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [
      # lilyinstarlight
    ];
    platforms = lib.platforms.linux;
    mainProgram = "cosmic-settings";
  };
}
