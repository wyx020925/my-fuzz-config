#!/bin/bash -eu

PROJECT_DIR="$SRC/test-libtiff-buttercup"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: Directory $PROJECT_DIR not found!"
    ls -la $SRC
    exit 1
fi

cd $PROJECT_DIR

# 2. 编译 libtiff
./autogen.sh
./configure --disable-shared --enable-static --disable-jbig --disable-lzma --disable-zstd
make -j$(nproc) clean
make -j$(nproc)

# 3. 编译 Fuzzer Harness
echo "Patching harness..."
sed -i 's/static void TIFFErrorHandler/static void MyTIFFErrorHandler/g' contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc
sed -i 's/TIFFSetErrorHandler(TIFFErrorHandler)/TIFFSetErrorHandler(MyTIFFErrorHandler)/g' contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc
sed -i 's/TIFFSetWarningHandler(TIFFErrorHandler)/TIFFSetWarningHandler(MyTIFFErrorHandler)/g' contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc

# === 最终修复: 强制静态链接 libjpeg ===
# 我们直接使用 .a 文件的绝对路径，而不是 -ljpeg
# 这样程序就不会依赖系统里的 .so 文件了
echo "Compiling harness with STATIC libraries..."

$CXX $CXXFLAGS -std=c++11 -I. -Ilibtiff \
    contrib/oss-fuzz/tiff_read_rgba_fuzzer.cc \
    -o $OUT/tiff_read_rgba_fuzzer \
    libtiff/.libs/libtiffxx.a \
    libtiff/.libs/libtiff.a \
    /usr/lib/x86_64-linux-gnu/libjpeg.a \
    -lz -lm $LIB_FUZZING_ENGINE

echo "Build finished successfully!"
