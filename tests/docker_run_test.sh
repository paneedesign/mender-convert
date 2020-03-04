docker build -t ped/mender-convert-lambda-fargate .

docker run -it \
    -e INPUT_BUCKET='dev-mender-input-watchfolder' \
    -e OUTPUT_BUCKET='dev-mender-output-watchfolder' \
    -e INPUT_IMG='2019-06-20-raspbian-buster-lite.img' \
    -e AWS_ACCESS_KEY_ID=##KEY## \
    -e AWS_SECRET_ACCESS_KEY=##SECRET## \
    --privileged=true \
    --cap-add=SYS_MODULE \

    ped/mender-convert-lambda-fargate

docker run -it --entrypoint bash ped/mender-convert-lambda-fargate
