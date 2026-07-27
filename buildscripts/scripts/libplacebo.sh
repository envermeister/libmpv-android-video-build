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
# vk-proc-addr kapalı: libplacebo, libvulkan.so'u çalışma zamanında dlopen
# eder (API 21 hedefinde link-bağımlılığı olmaz).
# shaderc: NDK-built libshaderc_combined.a via the shaderc.pc installed by
# scripts/shaderc.sh; glslang is not needed
# dovi: built-in Dolby Vision reshaping support (no external dependency)
# mpv 0.40 her varyantta libplacebo ister; vulkan yalnız dv'de (API 21
# hedefli varyantlarda vk referansı ve stub gereksinimi doğmasın).
if [ -n "${DV+x}" ]; then
	vulkan_opt="-Dvulkan=enabled"
else
	vulkan_opt="-Dvulkan=disabled"
fi

meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
	$vulkan_opt \
	-Dvk-proc-addr=disabled \
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

# Teşhis: pc içeriği ve FFmpeg-stili require sonucu logda görünsün.
# (usr -> . sembolik bağı sayesinde usr/local/lib/pkgconfig zaten ana dizin.)
cat "$prefix_dir"/lib/pkgconfig/libplacebo.pc >&2
pkg-config --exists --print-errors "libplacebo >= 4.192.0"
