{ lib, stdenv, fetchgit, meson, ninja, glib, cmake, pkg-config }:
stdenv.mkDerivation {
  name = "gdbuspp";
  src = fetchgit {
    url = "https://codeberg.org/OpenVPN/gdbuspp.git";
    rev = "refs/tags/v1";
    hash = "sha256-vw+37RbKRsB+DUyQU+ibwBHCj4jH/FaGl/bGSx7nrwY=";
  };

  patches = [ ./0001-fix-use-usr-bin-env-in-scripts.patch ];

  nativeBuildInputs = [ meson ninja cmake pkg-config ];

  buildInputs = [ glib ];

  meta = {
    description = "GDBus++ - a glib2 D-Bus wrapper for C++";
    homepage = "https://codeberg.org/OpenVPN/gdbuspp";
    license = lib.licenses.agpl3Only;
    maintainers = [ lib.maintainers.progrm_jarvis ];
    platforms = lib.platforms.linux;
  };
}
