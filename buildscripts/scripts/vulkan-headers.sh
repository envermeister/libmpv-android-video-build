#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf "$prefix_dir/include/vulkan" "$prefix_dir/include/vk_video" \
		"$prefix_dir/lib/pkgconfig/vulkan.pc"
	exit 0
else
	exit 255
fi

# header-only dependency: copy the headers into the prefix.
# the registry (vk.xml) is not installed on purpose: libplacebo uses the one
# from its own 3rdparty/Vulkan-Headers submodule to keep it in sync with the
# headers it compiles against, and neither FFmpeg nor mpv need it.
mkdir -p "$prefix_dir/include"
cp -r include/vulkan "$prefix_dir/include"
cp -r include/vk_video "$prefix_dir/include"

# pkg-config file so that FFmpeg (--enable-vulkan), libplacebo and mpv can
# find the headers. FFmpeg 7.1 requires vulkan >= 1.3.277, mpv's
# vulkan-interop requires >= 1.3.238; the NDK sysroot headers are too old.
# mpv (vo_gpu vulkan context) vk* sembollerine doğrudan referans verir;
# headers-only pc bu referansları tanımsız bırakır ve cihazda dlopen
# "cannot locate symbol" ile patlar. dv varyantı API 26 olduğundan NDK
# sysroot'taki stub'a linklenir; DT_NEEDED=libvulkan.so olarak işaretlenir
# (2016+ tüm cihazlarda mevcut).
mkdir -p "$prefix_dir"/lib/pkgconfig
# -lvulkan yalnız dv'de (API 26; stub var). Diğer varyantlarda headers-only:
# mpv vulkan=disabled derlendiğinden link gerekmiyor ve API 21 sysroot'unda
# stub yok.
if [ -n "${DV+x}" ]; then
	vulkan_libs="-L\${libdir} -lvulkan"
else
	vulkan_libs=""
fi

cat >"$prefix_dir"/lib/pkgconfig/vulkan.pc <<END
prefix=/usr/local
includedir=\${prefix}/include
libdir=\${prefix}/lib

Name: Vulkan-Headers
Description: Vulkan header files and API registry
Version: ${v_vulkan_headers#vulkan-sdk-}
Libs: $vulkan_libs
Cflags: -I\${includedir}
END
