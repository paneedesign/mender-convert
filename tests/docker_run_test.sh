docker build -t ped/mender-convert-lambda-fargate .

docker run -it \
    -e INPUT_BUCKET='dev-mender-input-watchfolder' \
    -e OUTPUT_BUCKET='dev-mender-output-watchfolder' \
    -e INPUT_IMG='2019-06-20-raspbian-buster-lite.img' \
    -e AWS_ACCESS_KEY_ID=AKIATISB4SDT7HCD7LNR \
    -e AWS_SECRET_ACCESS_KEY=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 \
    --privileged=true \
    --cap-add=SYS_MODULE \

    ped/mender-convert-lambda-fargate

docker run -it --entrypoint bash ped/mender-convert-lambda-fargate
