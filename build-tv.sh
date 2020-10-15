#!/bin/sh -e

LIBRARIES="libuchardet libfribidi libfreetype libharfbuzz libass ffmpeg libmpv"
OPENSSL="$(pwd)/openssl-tv"

export PKG_CONFIG_PATH
export LDFLAGS
export CFLAGS
export CXXFLAGS
export COMMON_OPTIONS
export ENVIRONMENT
export ARCH
export PLATFORM

while getopts "e:" OPTION; do
case $OPTION in
		e )
			ENVIRONMENT=$(echo "$OPTARG" | awk '{print tolower($0)}')
			;;
		? )
			echo "Invalid option"
			exit 1
			;;
	esac
done

export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"
DEPLOYMENT_TARGET="11.0"

if [[ "$ENVIRONMENT" = "distribution" ]]; then
    ARCHS="arm64"
elif [[ "$ENVIRONMENT" = "development" ]]; then
    ARCHS="x86_64"
elif [[ "$ENVIRONMENT" = "" ]]; then
    echo "An environment option is required (-e development or -e distribution)"
    exit 1
else
    echo "Unhandled environment option"
    exit 1
fi

ROOT="$(pwd)"
SCRIPTS="$ROOT/scripts"
SCRATCH="$ROOT/scratch-tv"
export SRC="$ROOT/src"

for ARCH in $ARCHS; do
    if [[ $ARCH = "arm64" ]]; then
        HOSTFLAG="aarch64"
        PLATFORM="AppleTVOS"
		export SDKPATH="$(xcodebuild -sdk appletvos -version Path)"
		ACFLAGS="-arch $ARCH -isysroot $SDKPATH -mtvos-version-min=$DEPLOYMENT_TARGET"
		ALDFLAGS="-arch $ARCH -isysroot $SDKPATH -Wl,-tvos_version_min,$DEPLOYMENT_TARGET -lbz2"
	elif [[ $ARCH = "x86_64" ]]; then
        HOSTFLAG="x86_64"
        PLATFORM="AppleTVSimulator"
		export SDKPATH="$(xcodebuild -sdk appletvsimulator -version Path)"
		ACFLAGS="-arch $ARCH -isysroot $SDKPATH -mtvos-simulator-version-min=$DEPLOYMENT_TARGET"
		ALDFLAGS="-arch $ARCH -isysroot $SDKPATH -Wl,-tvos_simulator_version_min,$DEPLOYMENT_TARGET -lbz2"
	else
        echo "Unhandled architecture option"
        exit 1
    fi

    if [[ "$ENVIRONMENT" = "development" ]]; then
        CFLAGS="$ACFLAGS"
        LDFLAGS="$ALDFLAGS"
    else
        CFLAGS="$ACFLAGS -fembed-bitcode -Os"
        LDFLAGS="$ALDFLAGS -fembed-bitcode -Os"
    fi
    CXXFLAGS="$CFLAGS"

    CFLAGS="$CFLAGS -I$OPENSSL/include"
    LDFLAGS="$LDFLAGS -L$OPENSSL/lib"

    mkdir -p $SCRATCH

    PKG_CONFIG_PATH="$SCRATCH/$ARCH/lib/pkgconfig"
    COMMON_OPTIONS="--prefix=$SCRATCH/$ARCH --exec-prefix=$SCRATCH/$ARCH --build=x86_64-apple-darwin14 --enable-static \
                    --disable-shared --disable-dependency-tracking --with-pic --host=$HOSTFLAG"
    
    for LIBRARY in $LIBRARIES; do
        case $LIBRARY in
            "libfribidi" )
				mkdir -p $SCRATCH/$ARCH/fribidi && cd $_ && $SCRIPTS/fribidi-build
				;;
            "libfreetype" )
				mkdir -p $SCRATCH/$ARCH/freetype && cd $_ && $SCRIPTS/freetype-build
				;;
            "libharfbuzz" )
				mkdir -p $SCRATCH/$ARCH/harfbuzz && cd $_ && $SCRIPTS/harfbuzz-build
				;;
            "libass" )
				mkdir -p $SCRATCH/$ARCH/libass && cd $_ && $SCRIPTS/libass-build
				;;
            "libuchardet" )
				mkdir -p $SCRATCH/$ARCH/uchardet && cd $_ && $SCRIPTS/uchardet-build
				;;
            "ffmpeg" )
				mkdir -p $SCRATCH/$ARCH/ffmpeg && cd $_ && $SCRIPTS/ffmpeg-build
				;;
            "libmpv" )
                if [[ "$ENVIRONMENT" = "development" ]]; then
                    CFLAGS="$ACFLAGS -fembed-bitcode -g2 -Og"
                    LDFLAGS="$ALDFLAGS -fembed-bitcode -g2 -Og"
                fi
				$SCRIPTS/mpv-build && cp $SRC/mpv*/build/libmpv.a "$SCRATCH/$ARCH/lib"
				;;
        esac
    done
done
