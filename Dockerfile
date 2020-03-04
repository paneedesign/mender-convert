FROM ubuntu:18.04

ARG MENDER_ARTIFACT_VERSION=3.2.1
ARG GOLANG_VERSION=1.11.2

RUN apt-get update && apt-get install -y \
    kpartx \
    bison \
    flex \
    mtools \
    parted \
    mtd-utils \
    e2fsprogs \
    u-boot-tools \
    pigz \
    device-tree-compiler \
    autoconf \
    autotools-dev \
    libtool \
    pkg-config \
    python \
    jq \
# for mender-convert to run (mkfs.vfat is required for boot partition)
    sudo \
    dosfstools \
# to compile U-Boot
    bc \
# to download mender-artifact
    wget \
# to download mender-convert and U-Boot sources
    git \
# for arm64 support
    gcc-aarch64-linux-gnu

#Needed to handle S3
RUN apt-get install apt-utils python-dev python-pip -y && \
    apt-get clean && pip install --upgrade pip

RUN pip install awscli

# Disable sanity checks made by mtools. These checks reject copy/paste operations on converted disk images.
RUN echo "mtools_skip_check=1" >> $HOME/.mtoolsrc

# To provide support for Raspberry Pi Zero W a toolchain tuned for ARMv6 architecture must be used.
# https://tracker.mender.io/browse/MEN-2399
# Assumes $(pwd) is /
RUN wget -nc -q https://toolchains.bootlin.com/downloads/releases/toolchains/armv6-eabihf/tarballs/armv6-eabihf--glibc--stable-2018.11-1.tar.bz2 \
    && tar -xjf armv6-eabihf--glibc--stable-2018.11-1.tar.bz2 \
    && rm armv6-eabihf--glibc--stable-2018.11-1.tar.bz2 \
    && echo 'export PATH=$PATH:/armv6-eabihf--glibc--stable-2018.11-1/bin' >> /root/.bashrc

RUN wget -q -O /usr/bin/mender-artifact https://d1b0l86ne08fsf.cloudfront.net/mender-artifact/$MENDER_ARTIFACT_VERSION/linux/mender-artifact \
    && chmod +x /usr/bin/mender-artifact

# Golang environment, for cross-compiling the Mender client
RUN wget https://dl.google.com/go/go$GOLANG_VERSION.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go$GOLANG_VERSION.linux-amd64.tar.gz \
    && echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc

ENV PATH "$PATH:/usr/local/go/bin:/armv6-eabihf--glibc--stable-2018.11-1/bin"
ENV GOPATH "/root/go"

# Download Mender client
ARG mender_client_version
RUN test -n "$mender_client_version" || (echo "Argument 'mender_client_version' is mandatory." && exit 1)
ENV MENDER_CLIENT_VERSION=$mender_client_version

RUN go get -d github.com/mendersoftware/mender
WORKDIR $GOPATH/src/github.com/mendersoftware/mender
RUN git checkout $MENDER_CLIENT_VERSION

# Toolchain configuration
ARG toolchain_host
RUN test -n "$toolchain_host" || (echo "Argument 'toolchain_host' is mandatory." && exit 1)
ENV TOOLCHAIN_HOST=${toolchain_host}

ARG go_flags
RUN test -n "$go_flags" || (echo "Argument 'go_flags' is mandatory." && exit 1)
ENV GO_FLAGS=$go_flags

RUN test -n "$mender_client_version" || (echo "Argument 'mender_client_version' is mandatory." && exit 1)
ENV MENDER_CLIENT_VERSION=$mender_client_version

ENV CC "${TOOLCHAIN_HOST}-gcc"

# Build liblzma from source
RUN wget -q https://tukaani.org/xz/xz-5.2.4.tar.gz \
    && tar -C /root -xzf xz-5.2.4.tar.gz \
    && cd /root/xz-5.2.4 \
    && ./configure --host=${TOOLCHAIN_HOST} --prefix=/root/xz-5.2.4/install \
    && make \
    && make install

ENV LIBLZMA_INSTALL_PATH "/root/xz-5.2.4/install"

# NOTE: we are assuming generic ARM board here, needs to be extended later
RUN env CGO_ENABLED=1 \
    CGO_CFLAGS="-I${LIBLZMA_INSTALL_PATH}/include" \
    CGO_LDFLAGS="-L${LIBLZMA_INSTALL_PATH}/lib" \
    CC=$CC \
    GOOS=linux \
    ${GO_FLAGS} make build

# allow us to keep original PATH variables when sudoing
RUN echo "Defaults        secure_path=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin:$PATH\"" > /etc/sudoers.d/secure_path_override
RUN chmod 0440 /etc/sudoers.d/secure_path_override

WORKDIR /

COPY docker-entrypoint.sh /usr/local/bin/

# we cant bind volumes on fargate, so we must add directories instead of binding
ADD ./ /mender-convert/

ENTRYPOINT \
    #set acces keys
    TENANT_TOKEN=$TENANT &&\
    echo "Starting Mender Image Conversion by PED.Devops..." && \
    #copy from s3 to disk
    mkdir -p /mender-convert/input && \
    mkdir -p /mender-convert/output && \
    echo "Copying img from s3://${INPUT_BUCKET}/${INPUT_IMG} to .input/${INPUT_IMG}..." && \
    aws s3 cp s3://${INPUT_BUCKET}/${INPUT_IMG} /mender-convert/input/${INPUT_IMG} && \
    #convert
    MENDER_ARTIFACT_NAME="${INPUT_IMG%.*}" && \
    bash /usr/local/bin/docker-entrypoint.sh from-raw-disk-image  \
        --raw-disk-image /mender-convert/input/${INPUT_IMG}  \
        --storage-total-size-mb 10000                        \
        --mender-disk-image ${MENDER_ARTIFACT_NAME}.sdimg    \
        --device-type raspberrypi3                           \
        --artifact-name $MENDER_ARTIFACT_NAME                       \
        --bootloader-toolchain arm-buildroot-linux-gnueabihf \
        --server-url "https://hosted.mender.io"              \
        --tenant-token $TENANT_TOKEN && \
    #copy back the converted img to s3
    echo "Copying converted img to S3://${INPUT_BUCKET}/${OUTPUT_FILE} ..." && \
    aws s3 cp /mender-convert/output/${INPUT_IMG%.*}.mender s3://${OUTPUT_BUCKET}/raspberrypi-${INPUT_IMG%.*}.mender && \
    aws s3 cp /mender-convert/output/${INPUT_IMG%.*}.sdimg s3://${OUTPUT_BUCKET}/raspberrypi-${INPUT_IMG%.*}.sdimg
