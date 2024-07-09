{ lib
, stdenv
, fetchFromGitHub
, asio
, glib
, jsoncpp
, libcap_ng
, libnl
, libuuid
, lz4
, openssl
, pkg-config
, protobuf
, python3
, systemd
, enableSystemdResolved ? false
, tinyxml-2
, wrapGAppsHook3 # TODO: do we need it?
, gobject-introspection
# begin(pportnov)
, meson
, ninja
, bash
, breakpointHook
, gdbuspp
, cmake
, git
# end(pportnov)
}:

stdenv.mkDerivation rec {
  pname = "openvpn3";
  # also update openvpn3-core
  version = "22_dev";

  src = fetchFromGitHub {
    owner = "OpenVPN";
    #owner = "JarvisCraft";
    repo = "openvpn3-linux";
    #rev = "v${version}-nixos";
    rev = "62f3536b015ab9f348a2a87e32864cc330709c1a";
    hash = "sha256-zCklE1jTPLPKiEWUyt0s3T7ivyhBK/1HyR6wf50ED8I=";
    fetchSubmodules = true;
    # This is required to generate version information.
    leaveDotGit = true;
  };

  patches = [
    #./0001-fix-use-usr-bin-env-bash-in-scripts.patch
    #./0002-build-shorter-asio-path.patch
    ./0003-no-auto-install.patch
  ];

  postPatch = ''
    patchShebangs ** /*.py ** /*.sh ./src/python/{openvpn2,openvpn3-as,openvpn3-autoload} \
    ./distro/systemd/openvpn3-systemd ./src/tests/dbus/netcfg-subscription-test

    # echo "3.git:v${version}:unknown" > openvpn3-core-version
  '';

  # TODO(pportnov): do we need it?
  outputs = [ "out" "dev" ];

  pythonPath = python3.withPackages (ps: [
    ps.dbus-python
    ps.pygobject3
    ps.systemd
  ]);
  nativeBuildInputs = [
    meson
    ninja
    bash
    cmake
    git

    python3.pkgs.docutils
    python3.pkgs.jinja2
    pkg-config
    wrapGAppsHook3

    python3.pkgs.wrapPython
    gobject-introspection
  ];

  buildInputs = [
    asio
    glib
    jsoncpp
    libcap_ng
    libnl
    libuuid
    lz4
    openssl
    protobuf
    tinyxml-2
    gdbuspp
  ] ++ lib.optionals enableSystemdResolved [
    systemd
  ];

  # runtime deps

  mesonFlags = [
    (lib.mesonOption "selinux" "disabled")
    (lib.mesonOption "selinux_policy" "disabled")
    # "-Dbash-completion=enabled"
    (lib.mesonOption "test_programs" "disabled")
    (lib.mesonOption "unit_tests" "disabled")
    (lib.mesonOption "asio_path" "${asio}")
    # "openvpn3-linux-${version}"
    # "-Ddbus-1:datadir=$out/share/"
    (lib.mesonOption "dbuspolicydir" "${placeholder "out"}/share/dbus-1/system.d")
    # (lib.mesonOption "dbussessionservicedir" "${placeholder "out"}/share/dbus-1/services")
    (lib.mesonOption "dbussystemservicedir" "${placeholder "out"}/share/dbus-1/system-services")
    (lib.mesonOption "systemdsystemunitdir" "${placeholder "out"}/lib/systemd/system")
    # (lib.mesonOption "openvpn3_statedir" "/var/lib/openvpn3")
    (lib.mesonOption "sharedstatedir" "/var/lib")
  ];

  dontWrapGApps = true;
  preFixup = ''
    makeWrapperArgs+=("''${gappsWrapperArgs[@]}")
  '';
  postFixup = ''
    wrapPythonPrograms
    wrapPythonProgramsIn "$out/libexec/openvpn3-linux" "$out ${pythonPath}"
  '';

  /* `mesonFlags` are used instead
  configureFlags = [
    "--enable-bash-completion"
    "--enable-addons-aws"
    "--disable-selinux-build"
    "--disable-build-test-progs"
  ] ++ lib.optionals enableSystemdResolved [
    # This defaults to --resolv-conf /etc/resolv.conf. See
    # https://github.com/OpenVPN/openvpn3-linux/blob/v20/configure.ac#L434
    "DEFAULT_DNS_RESOLVER=--systemd-resolved"
  ];
  */

  NIX_LDFLAGS = "-lpthread";

  meta = {
    description = "OpenVPN 3 Linux client";
    license = lib.licenses.agpl3Plus;
    homepage = "https://github.com/OpenVPN/openvpn3-linux/";
    maintainers = [
      lib.maintainers.shamilton
      lib.maintainers.kfears
      lib.maintainers.progrm_jarvis
    ];
    platforms = lib.platforms.linux;
  };
}
