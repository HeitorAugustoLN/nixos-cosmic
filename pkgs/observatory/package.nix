{
  lib,
  fetchFromGitHub,
  libcosmicAppHook,
  rustPlatform,
  just,
  stdenv,
  gnused,
  protobuf,
  nix-update-script,
}:

rustPlatform.buildRustPackage rec {
  pname = "observatory";
  version = "0.2.2-unstable-2025-04-01";

  src = fetchFromGitHub {
    owner = "cosmic-utils";
    repo = "observatory";
    rev = "02abde5648ca70a8f1e0e0f211e16d174272821a";
    hash = "sha256-lWabTPlYf3oZIS5hMLF9udPw1RM/Ya96JDEyIY+r80A=";
    fetchSubmodules = true;
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-Td1Dc00doBSDIlDekVp03TmAMuhEGAtShcgoMnggqA8=";

  nativeBuildInputs = [
    libcosmicAppHook
    gnused
    just
    protobuf
  ];

  monitord = rustPlatform.buildRustPackage {
    pname = "observatory-monitord";

    inherit version src;

    useFetchCargoVendor = true;
    cargoHash = "sha256-+ELF/COm0SSDJk8ydyS4x/4ImTqj7PNZI4W2+4v62Js=";

    sourceRoot = "${src.name}/monitord";

    nativeBuildInputs = [
      protobuf
    ];

    cargoBuildFlags = [
      "--package"
      "monitord-service"
    ];
    cargoTestFlags = [
      "--package"
      "monitord-service"
    ];
  };

  postPatch = ''
    sed -i \
      -e '/sudo system/d' \
      -e '/@just monitord/d' \
      -e 's/sudo install/install/' \
      justfile

    substituteInPlace resources/monitord.service \
      --replace-fail '/usr/bin/monitord' "''${!outputBin}/bin/monitord"
  '';

  dontUseJustBuild = true;
  dontUseJustCheck = true;

  justFlags = [
    "--set"
    "prefix"
    (placeholder "out")
    "--set"
    "bin-src"
    "target/${stdenv.hostPlatform.rust.cargoShortTarget}/release/observatory"
  ];

  env.VERGEN_GIT_SHA = src.rev;

  postInstall = ''
    cp $monitord/bin/monitord $out/bin/

    mkdir -p $out/lib/systemd/system
    cp resources/monitord.service $out/lib/systemd/system/
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    homepage = "https://github.com/cosmic-utils/observatory";
    description = "System monitor application for the COSMIC Desktop Environment";
    licenses = with lib.licenses; [
      # observatory
      mpl20
      # monitord
      mit
    ];
    maintainers = with lib.maintainers; [
      # lilyinstarlight
    ];
    platforms = lib.platforms.linux;
    mainProgram = "observatory";
  };
}
