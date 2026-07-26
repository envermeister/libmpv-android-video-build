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
# -lvulkan resolves against the libvulkan.so stub in the NDK sysroot.
mkdir -p "$prefix_dir"/lib/pkgconfig
cat >"$prefix_dir"/lib/pkgconfig/vulkan.pc <<END
Name: Vulkan-Headers
Description: Vulkan header files and API registry
Version: ${v_vulkan_headers#vulkan-sdk-}
Libs: -L/usr/lib -lvulkan
Cflags: -I/usr/include
END
