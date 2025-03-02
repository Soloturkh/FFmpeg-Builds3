#!/bin/bash

SCRIPT_REPO="https://github.com/opencv/opencv.git"
SCRIPT_COMMIT="4.11.0"

ffbuild_enabled() {
    [[ $TARGET == linux* ]] && return 0
    return 1
}

ffbuild_dockerdl() {
	default_dl .
        echo "git submodule update --init --recursive --depth=1"
	if [ ! -d "opencv_contrib" ]; then
		echo "git clone --branch \${SCRIPT_COMMIT} https://github.com/opencv/opencv_contrib.git"
	fi
}

ffbuild_dockerbuild() {
    mkdir build && cd build
    if command -v nvidia-smi &> /dev/null; then
    		echo "NVIDIA GPU algılandı, CUDA desteği ve TBB devre dışı bırakılıyor..."
    		GPU_OPTIONS="-DWITH_CUDA=ON \
    					  -DWITH_CUDNN=ON \
    					  -DOPENCV_DNN_CUDA=ON \
    					  -DCUDA_ARCH_BIN=ALL \
    					  -DENABLE_FAST_MATH=ON \
    					  -DCUDA_FAST_MATH=ON \
    					  -DWITH_CUBLAS=ON \
    					  -DBUILD_opencv_cudacodec=ON"
    		TBB_OPTION="-DWITH_TBB=OFF"  # GPU mevcutsa TBB devre dışı
    else
    		echo "NVIDIA GPU algılanmadı, sadece CPU desteği etkinleştiriliyor..."
    		GPU_OPTIONS="-DWITH_CUDA=OFF \
    					  -DWITH_CUDNN=OFF \
    					  -DOPENCV_DNN_CUDA=OFF \
    					  -DWITH_CUBLAS=OFF \
    					  -DBUILD_opencv_cudacodec=OFF"
    		TBB_OPTION="-DWITH_TBB=ON"  # GPU yoksa TBB etkin
    fi

    cmake -G Ninja -DCMAKE_TOOLCHAIN_FILE="$FFBUILD_CMAKE_TOOLCHAIN" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$FFBUILD_PREFIX" -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DCMAKE_INSTALL_BINDIR=bin -DCMAKE_INSTALL_LIBDIR=lib \
        -DOPENCV_EXTRA_MODULES_PATH=../opencv_contrib/modules \
        -DENABLE_PRECOMPILED_HEADERS=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_TESTS=OFF \
        -DBUILD_PERF_TESTS=OFF \
	$GPU_OPTIONS \
	$TBB_OPTION \
        -DWITH_OPENCL=OFF \
        -DWITH_V4L=ON \
	-DWITH_FFMPEG=OFF \
	-DWITH_GSTREAMER=OFF \
        -DWITH_MSMF=OFF \
	-DWITH_DSHOW=OFF \
	-DWITH_AVFOUNDATION=OFF \
	-DWITH_1394=OFF \
        -DWITH_IPP=OFF \
        -DWITH_PROTOBUF=OFF \
        -DBUILD_PKG_CONFIG=ON \
        -DOPENCV_GENERATE_PKGCONFIG=ON \
        -DOPENCV_ENABLE_NONFREE=ON \
        -DBUILD_EXAMPLES=OFF \
	-DINSTALL_PYTHON_EXAMPLES=OFF \
	-DINSTALL_C_EXAMPLES=OFF \
        -DBUILD_ZLIB=ON \
        -DBUILD_SHARED_LIBS=OFF \
        ..

    ninja -j$(nproc)
    ninja install
    #find / -name *.pc 2>/dev/null
    found_pc_files=$(find . -name 'opencv.pc' -o -name 'opencv4.pc')
    while IFS= read -r pc_file; do
 	echo "Libs.private: -lstdc++" >> $pc_file
	# Hedefteki dosya zaten varsa, hiçbir işlem yapma
	if [ ! -e "$FFBUILD_PREFIX/lib/pkgconfig/opencv4.pc" ]; then
	    # Hedefteki dosya yoksa sembolik bağlantı oluştur
	    ln -s "$pc_file" "$FFBUILD_PREFIX/lib/pkgconfig/opencv4.pc"
	fi
    done <<< "$found_pc_files"
}

ffbuild_configure() {
    echo --enable-libopencv4
}

ffbuild_unconfigure() {
    echo --disable-libopencv4
}
