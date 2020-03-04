#!/bin/bash
YELLOW="$(tput setaf 3)"
NORMAL="$(tput sgr0)"

DEVICE_TYPE="raspberrypi3"
TENANT_TOKEN="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJtZW5kZXIudGVuYW50IjoiNWUxNzQ0YmE3MGQ2OTAwMDAxZDI3YjMyIiwiaXNzIjoiTWVuZGVyIiwic3ViIjoiNWUxNzQ0YmE3MGQ2OTAwMDAxZDI3YjMyIn0.bvJUr6OuU2wOkDM-bLix3gNxXCQlCu7eEmqD4Aoe46-mgUtJZx71fW-JfIH5w1TU8baLEep_aBaKEhS7S_MEja8H9FS3EvwJYir06xhoK_rkmPjB8pZ9_GdU6kHnlM6q2EEy-jFhk2nSm9qabYNpr4E9cH__OE2AXCmEm1tZU_mpINXq9IOfZiE6LhdPIkNSUhr7qsJ-6c5vadgbhguLhZODHXItY3Ohwn7cCb5URP-yQhFHhsnMZmtGO0akaUpopmyi0dOa_mihUY_q7udILnjZbO2BApIjTBafjjCcMnnrH4O1cOlBTtM1hTF9eFhK8nQH4uVOZc9GgGKN_TWPFgfSVoDD54gJ8nD7PBIaA8e98zNo4IFHzovYsdFb1x6ZSB1bfVFADlPyXeVekkJVhNss_btiOk5ZPdNCMG4AS3_N_BjuswxfQOL6pxpjbAJA7042N_FEWW4skL34y9qlrWAoOE4ZcB3CXVU2IpeCdMlX0PyDDuLX0zRMJl9ijiQN"

main() {
  if [[ ! $1 ]] ; then
    printf "${YELLOW}Artifact name required (ex: ./start-convertion "artifact-name" ./input/path/file.img).${NORMAL}\n"
    exit 0
  fi
  ARTIFACT_NAME=$1
  MENDER_DISK_IMAGE="$1.sdimg"

  if [[ ! $2 ]] ; then
    printf "${YELLOW}Input disk image required (ex: ./start-convertion "artifact-name" ./input/path/file.img).${NORMAL}\n"
    exit 0
  fi
  RAW_DISK_IMAGE=$2
  if [ ! -f "$RAW_DISK_IMAGE" ]; then
    printf "${YELLOW}Input disk image does not exist!.${NORMAL}\n"
    exit 0
  fi
  ./docker-mender-convert from-raw-disk-image                      \
              --storage-total-size-mb 10000                        \
              --raw-disk-image $RAW_DISK_IMAGE                     \
              --mender-disk-image $MENDER_DISK_IMAGE               \
              --device-type $DEVICE_TYPE                           \
              --artifact-name $ARTIFACT_NAME                       \
              --bootloader-toolchain arm-buildroot-linux-gnueabihf \
              --server-url "https://hosted.mender.io"              \
              --tenant-token $TENANT_TOKEN
}
main "$1" "$2"
