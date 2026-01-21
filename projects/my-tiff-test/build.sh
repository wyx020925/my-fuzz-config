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
./autogen.sh
./configure --disable-shared --enable-static --disable-jbig --disable-lzma --disable-zstd
make -j$(nproc) clean
make -j$(nproc)

# 3. 编译 Fuzzer Harness
# === 修复 1: 解决函数名冲突 ===
echo "Patching harness to fix naming conflict..."
sed -i 's/static void TIFFErrorHandler/static void MyTIFFErrorHandler/g' contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc
sed -i 's/TIFFSetErrorHandler(TIFFErrorHandler)/TIFFSetErrorHandler(MyTIFFErrorHandler)/g' contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc
sed -i 's/TIFFSetWarningHandler(TIFFErrorHandler)/TIFFSetWarningHandler(MyTIFFErrorHandler)/g' contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc

# === 修复 2: 添加 -ljpeg (关键!) ===
# 下面这行必须包含 -ljpeg
$CXX $CXXFLAGS -std=c++11 -I. -Ilibtiff \
    contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc \
    -o $OUT/tiff_read_rgba_fuzzer \
    libtiff/.libs/libtiff.a -ljpeg -lz -lm $LIB_FUZZING_ENGINE

echo "Build finished successfully!"
