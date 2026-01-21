FROM gcr.io/oss-fuzz-base/base-builder

# 安装基础构建工具和 libtiff 特有的依赖 (zlib, jpeg)
RUN apt-get update && apt-get install -y make autoconf automake libtool cmake nasm zlib1g-dev libjpeg-dev

# 复制构建脚本
COPY build.sh $SRC/
WORKDIR $SRC/
