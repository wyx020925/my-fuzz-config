#!/bin/bash -eu

# $SRC 是源码根目录。
PROJECT_DIR="$SRC/test-libtiff-buttercup"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: Directory $PROJECT_DIR not found!"
    ls -la $SRC
    exit 1
fi

cd $PROJECT_DIR

# 2. 编译 libtiff (静态库)
# 生成配置
./autogen.sh
# 配置：禁用共享库，禁用不需要的压缩算法以减少依赖麻烦
./configure --disable-shared --enable-static --disable-jbig --disable-lzma --disable-zstd
# 编译 (make 会自动编译 libtiff.a 和 libtiffxx.a)
make -j$(nproc) clean
make -j$(nproc)

# 3. 编译 Fuzzer Harness
# === 修复 1: 解决函数名冲突 ===
echo "Patching harness to fix naming conflict..."
sed -i 's/static void TIFFErrorHandler/static void MyTIFFErrorHandler/g' contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc
sed -i 's/TIFFSetErrorHandler(TIFFErrorHandler)/TIFFSetErrorHandler(MyTIFFErrorHandler)/g' contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc
sed -i 's/TIFFSetWarningHandler(TIFFErrorHandler)/TIFFSetWarningHandler(MyTIFFErrorHandler)/g' contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc

# === 修复 2 & 3: 完整的链接命令 ===
# 关键点：
# 1. 链接 libtiffxx.a (解决 TIFFStreamOpen 报错)
# 2. 链接 libtiff.a (基础 C 库)
# 3. 链接 -ljpeg (解决 jpeg 报错)
echo "Compiling harness with C++ support..."
$CXX $CXXFLAGS -std=c++11 -I. -Ilibtiff \
    contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc \
    -o $OUT/tiff_read_rgba_fuzzer \
    libtiff/.libs/libtiffxx.a \
    libtiff/.libs/libtiff.a \
    -ljpeg -lz -lm $LIB_FUZZING_ENGINE

echo "Build finished successfully!"
