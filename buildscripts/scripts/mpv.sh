#!/bin/bash -e

. ../../include/depinfo.sh
. ../../include/path.sh

build=_build$ndk_suffix

if [ "$1" == "build" ]; then
	true
elif [ "$1" == "clean" ]; then
	rm -rf _build$ndk_suffix
	exit 0
else
	exit 255
fi

unset CC CXX # meson wants these unset

# mpv 0.40'ta libplacebo meson seçeneği kaldırıldı (zorunlu bileşen);
# yalnız vulkan koşullu. dv varyantı vulkan'ı etkin derler.
if [ -n "${DV+x}" ]; then
	vulkan_libplacebo="-Dvulkan=enabled"
else
	vulkan_libplacebo="-Dvulkan=disabled"
fi

meson setup $build --cross-file "$prefix_dir"/crossfile.txt \
	--prefer-static \
	--default-library shared \
	-Dgpl=false \
	-Dlibmpv=true \
 	-Dlua=disabled \
 	-Dcplayer=false \
	-Diconv=disabled \
	$vulkan_libplacebo \
 	-Dmanpage-build=disabled

ninja -C $build -j$cores
DESTDIR="$prefix_dir" ninja -C $build install

ln -sf "$prefix_dir"/lib/libmpv.so "$native_dir"
