IMAGE_NAME='ped/mender-convert-lambda-fargate' ./docker-build

docker run \
    -e INPUT_BUCKET='dev-mender-input-watchfolder' \
    -e TENANT='eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJtZW5kZXIudGVuYW50IjoiNWUxNzQ0YmE3MGQ2OTAwMDAxZDI3YjMyIiwiaXNzIjoiTWVuZGVyIiwic3ViIjoiNWUxNzQ0YmE3MGQ2OTAwMDAxZDI3YjMyIn0.bvJUr6OuU2wOkDM-bLix3gNxXCQlCu7eEmqD4Aoe46-mgUtJZx71fW-JfIH5w1TU8baLEep_aBaKEhS7S_MEja8H9FS3EvwJYir06xhoK_rkmPjB8pZ9_GdU6kHnlM6q2EEy-jFhk2nSm9qabYNpr4E9cH__OE2AXCmEm1tZU_mpINXq9IOfZiE6LhdPIkNSUhr7qsJ-6c5vadgbhguLhZODHXItY3Ohwn7cCb5URP-yQhFHhsnMZmtGO0akaUpopmyi0dOa_mihUY_q7udILnjZbO2BApIjTBafjjCcMnnrH4O1cOlBTtM1hTF9eFhK8nQH4uVOZc9GgGKN_TWPFgfSVoDD54gJ8nD7PBIaA8e98zNo4IFHzovYsdFb1x6ZSB1bfVFADlPyXeVekkJVhNss_btiOk5ZPdNCMG4AS3_N_BjuswxfQOL6pxpjbAJA7042N_FEWW4skL34y9qlrWAoOE4ZcB3CXVU2IpeCdMlX0PyDDuLX0zRMJl9ijiQN' \
    -e OUTPUT_BUCKET='dev-mender-output-watchfolder' \
    -e INPUT_IMG='2019-06-20-raspbian-buster-lite.img' \
    -e AWS_ACCESS_KEY_ID=##KEY## \
    -e AWS_SECRET_ACCESS_KEY=##SECRET## \
    --privileged=true \
    --cap-add=SYS_MODULE \
    ped/mender-convert-lambda-fargate

docker run -it --entrypoint bash ped/mender-convert-lambda-fargate
