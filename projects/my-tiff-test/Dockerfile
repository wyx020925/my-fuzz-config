FROM gcr.io/oss-fuzz-base/base-builder

# 1. 安装依赖
RUN apt-get update && apt-get install -y make autoconf automake libtool cmake nasm zlib1g-dev libjpeg-dev

# 2. 克隆源代码 (这是 CUSTOM_CHALLENGES.md 要求的步骤)
RUN git clone https://github.com/wyx020925/test-libtiff-buttercup.git $SRC/test-libtiff-buttercup

# 3. 复制构建脚本
COPY build.sh $SRC/
WORKDIR $SRC/test-libtiff-buttercup
