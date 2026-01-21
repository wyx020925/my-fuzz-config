#!/bin/bash -eu

# $SRC 是源码根目录。
# Buttercup/OSS-Fuzz 会把你的目标代码 (test-libtiff-buttercup) 下载到这里。
# 我们需要准确找到那个目录。

# 1. 定义源码目录名 (必须与你的 Target Git 仓库名一致)
PROJECT_DIR="$SRC/test-libtiff-buttercup"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: Directory $PROJECT_DIR not found!"
    echo "Listing $SRC content:"
    ls -la $SRC
    exit 1
fi

cd $PROJECT_DIR

# 2. 编译 libtiff (静态库)
# 生成 configure 脚本
./autogen.sh
# 配置：禁用共享库(方便fuzz)，禁用不需要的特性以减少依赖报错
./configure --disable-shared --enable-static --disable-jbig --disable-lzma --disable-zstd
# 编译
make -j$(nproc) clean
make -j$(nproc)

# 3. 编译 Fuzzer Harness
# 注意：$LIB_FUZZING_ENGINE 是系统提供的变量，不要自己写 -lFuzzer
# 注意：链接顺序很重要，依赖库放在后面
$CXX $CXXFLAGS -std=c++11 -I. -Ilibtiff \
    contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc \
    -o $OUT/tiff_read_rgba_fuzzer \
    libtiff/.libs/libtiff.a -lz -lm $LIB_FUZZING_ENGINE

echo "Build finished successfully!"
