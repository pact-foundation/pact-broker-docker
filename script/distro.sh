# shellcheck shell=sh
# Sourced, not executed. Validates DISTRO and derives TAG_SUFFIX from it.
# Alpine is the default image, so it also owns the unsuffixed tags; every other
# distribution is published as `${TAG}-${DISTRO}`.

: "${DISTRO:=alpine}"

case "${DISTRO}" in
alpine) TAG_SUFFIX="" ;;
debian) TAG_SUFFIX="-${DISTRO}" ;;
*)
  echo "Unknown DISTRO '${DISTRO}': expected alpine or debian" >&2
  exit 1
  ;;
esac

export DISTRO TAG_SUFFIX
