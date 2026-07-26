#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

build=_build$ndk_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf $build
	exit 0
else
	exit 255
fi

unset CC CXX # meson wants these unset

# vulkan: links against the libvulkan.so stub from the NDK sysroot via the
# vulkan.pc installed by scripts/vulkan-headers.sh (vk-proc-addr)
# shaderc: NDK-built libshaderc_combined.a via the shaderc.pc installed by
# scripts/shaderc.sh; glslang is not needed
# dovi: built-in Dolby Vision reshaping support (no external dependency)
meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
	-Dvulkan=enabled \
	-Dopengl=enabled \
	-Dshaderc=enabled \
	-Ddovi=enabled \
	-Dglslang=disabled \
	-Dd3d11=disabled \
	-Dlcms=disabled \
	-Ddemos=false \
	-Dtests=false \
	-Dbench=false

ninja -C $build -j$cores
DESTDIR="$prefix_dir" ninja -C $build install

# add missing library for static linking
# this isn't "-lstdc++" due to a meson bug: https://github.com/mesonbuild/meson/issues/11300
${SED:-sed} '/^Libs:/ s|$| -lc++|' "$prefix_dir"/lib/pkgconfig/libplacebo.pc -i

# meson, DESTDIR (/usr/local/lib/pkgconfig) altına kurar; kimi pkg-config
# sürümleri PKG_CONFIG_LIBDIR varken varsayılan arama yolunu kullanmaz.
# FFmpeg/mpy yapılandırmasının gördüğü sonucu burada doğrula ki zincirin
# hangi halkası eksikse pkg-config'in kendi mesajıyla logda görünsün.
cp "$prefix_dir"/usr/local/lib/pkgconfig/libplacebo.pc "$prefix_dir"/lib/pkgconfig/
pkg-config --exists --print-errors "libplacebo >= 4.192.0"
