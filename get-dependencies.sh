#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	7zip                  \
	clang                 \
	cmake                 \
	curl                  \
	dbus                  \
	extra-cmake-modules   \
	ffmpeg                \
	freetype2             \
	git                   \
	hicolor-icon-theme    \
	kddockwidgets         \
	kvantum               \
	libbacktrace          \
	libglvnd              \
	libjpeg-turbo         \
	libpcap               \
	libpipewire           \
	libpng                \
	libpulse              \
	libwebp               \
	libx11                \
	libxi                 \
	libxrandr             \
	lld                   \
	llvm                  \
	lxqt-qtplugin         \
	lz4                   \
	ninja                 \
	qt6-base              \
	qt6-svg               \
	qt6-tools             \
	qt6-wayland           \
	qt6ct                 \
	sdl3                  \
	shaderc               \
	systemd-libs          \
	vulkan-headers        \
	zlib                  \
	zstd

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

echo "Building dependencies from the AUR..."
echo "---------------------------------------------------------------"
make-aur-package plutovg
make-aur-package plutosvg
make-aur-package rapidyaml

echo "Building PCSX2..."
echo "---------------------------------------------------------------"
git clone --filter=blob:none --no-checkout https://github.com/PCSX2/pcsx2 ./pcsx2
cd ./pcsx2

if [ "${DEVEL_RELEASE-}" = 1 ]; then
	git checkout master
	git rev-parse --short HEAD > ~/version
else
	git fetch --tags origin
	TAG=$(curl -fsSL https://api.github.com/repos/PCSX2/pcsx2/releases/latest | grep -o '"tag_name": *"[^"]*"' | head -n 1 | cut -d'"' -f4)
	git checkout "$TAG"
	echo "${TAG#v}" > ~/version
fi

curl -fsSL --retry 5 --retry-connrefused \
	https://github.com/PCSX2/pcsx2_patches/releases/latest/download/patches.zip \
	-o bin/resources/patches.zip

cmake -S . -B build -G Ninja                       \
	-DCMAKE_BUILD_TYPE=Release                     \
	-DCMAKE_C_COMPILER=clang                       \
	-DCMAKE_CXX_COMPILER=clang++                   \
	-DCMAKE_EXE_LINKER_FLAGS_INIT="-fuse-ld=lld"   \
	-DCMAKE_MODULE_LINKER_FLAGS_INIT="-fuse-ld=lld" \
	-DCMAKE_INSTALL_PREFIX=/usr                    \
	-DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON        \
	-DDISABLE_ADVANCE_SIMD=ON                      \
	-DENABLE_SETCAP=OFF                            \
	-DPACKAGE_MODE=ON                              \
	-DUSE_VULKAN=ON                                \
	-DWAYLAND_API=ON

cmake --build build -j"$(nproc)"
cmake --install build

install -Dm644 .github/workflows/scripts/linux/pcsx2-qt.desktop /usr/share/applications/PCSX2.desktop
install -Dm644 bin/resources/icons/AppIconLarge.png /usr/share/icons/hicolor/512x512/apps/PCSX2.png
