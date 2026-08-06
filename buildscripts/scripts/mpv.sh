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
# dv varyantı mpv 0.41 derliyor; ao_aaudio.c API 31 sabiti
# (AAUDIO_FORMAT_IEC61937) kullanıyor ama dv hedefi API 26 — uygulama zaten
# yalnız OpenSLES kullandığından aaudio dv'de kapatılır.
if [ -n "${DV+x}" ]; then
	vulkan_libplacebo="-Dvulkan=enabled -Daaudio=disabled"
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
