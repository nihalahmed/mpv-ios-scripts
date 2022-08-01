#!/bin/sh -e

LIBRARIES="libuchardet libfribidi libfreetype libharfbuzz libass ffmpeg libmpv libssl"
IOS_SDK_VERSION="15.5"
TVOS_SDK_VERSION="15.4"
DEPLOYMENT_TARGET="11.0"

export PKG_CONFIG_PATH
export LDFLAGS
export CFLAGS
export CXXFLAGS
export COMMON_OPTIONS
export ENVIRONMENT
export ARCH
export PLATFORM
export CMAKE_OSX_ARCHITECTURES

while getopts "p:e:" OPTION; do
case $OPTION in
		e )
			ENVIRONMENT=$(echo "$OPTARG" | awk '{print tolower($0)}')
			;;
		p )
			PLATFORM=$(echo "$OPTARG" | awk '{print tolower($0)}')
			;;
		? )
			echo "Invalid option"
			exit 1
			;;
	esac
done

export PATH="/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/:$PATH"

if [[ "$ENVIRONMENT" = "distribution" ]]; then
    ARCHS="arm64"
elif [[ "$ENVIRONMENT" = "development" ]]; then
    ARCHS="x86_64 arm64"
elif [[ "$ENVIRONMENT" = "" ]]; then
    echo "An environment option is required (-e development or -e distribution)"
    exit 1
else
    echo "Unhandled environment option"
    exit 1
fi

if [[ "$PLATFORM" = "ios" ]]; then
    SDK_VERSION=$IOS_SDK_VERSION
    PLATFORM_SIMULATOR="iPhoneSimulator"
    PLATFORM_DEVICE="iPhoneOS"
    SDKPATH_SIMULATOR="$(xcodebuild -sdk iphonesimulator -version Path)"
    SDKPATH_DEVICE="$(xcodebuild -sdk iphoneos -version Path)"
    MIN_VERSION_SIMULATOR_CFLAG="-mios-simulator-version-min"
    MIN_VERSION_SIMULATOR_LDFLAG="-Wl,-ios_simulator_version_min"
    MIN_VERSION_DEVICE_CFLAG="-mios-version-min"
    MIN_VERSION_DEVICE_LDFLAG="-Wl,-ios_version_min"
elif [[ "$PLATFORM" = "tv" ]]; then
    SDK_VERSION=$TVOS_SDK_VERSION
    PLATFORM_SIMULATOR="AppleTVSimulator"
    PLATFORM_DEVICE="AppleTVOS"
    SDKPATH_SIMULATOR="$(xcodebuild -sdk appletvsimulator -version Path)"
    SDKPATH_DEVICE="$(xcodebuild -sdk appletvos -version Path)"
    MIN_VERSION_SIMULATOR_CFLAG="-mtvos-simulator-version-min"
    MIN_VERSION_SIMULATOR_LDFLAG="-Wl,-tvos_simulator_version_min"
    MIN_VERSION_DEVICE_CFLAG="-mtvos-version-min"
    MIN_VERSION_DEVICE_LDFLAG="-Wl,-tvos_version_min"
elif [[ "$PLATFORM" = "" ]]; then
    echo "A platform option is required (-p ios or -p tv)"
    exit 1
else
    echo "Unhandled platform option"
    exit 1
fi

ROOT="$(pwd)"
SCRIPTS="$ROOT/scripts"
SCRATCH="$ROOT/scratch-$PLATFORM"
export SRC="$ROOT/src"

for ARCH in $ARCHS; do
    if [[ $ARCH = "arm64" ]]; then
        HOSTFLAG="aarch64"
        CMAKE_OSX_ARCHITECTURES=$ARCH
        if [[ "$ENVIRONMENT" = "development" ]]; then
            PLATFORM=$PLATFORM_SIMULATOR
            export SDKPATH=$SDKPATH_SIMULATOR
            ACFLAGS="-arch $ARCH -isysroot $SDKPATH $MIN_VERSION_SIMULATOR_CFLAG=$DEPLOYMENT_TARGET"
            ALDFLAGS="-arch $ARCH -isysroot $SDKPATH $MIN_VERSION_SIMULATOR_LDFLAG,$DEPLOYMENT_TARGET -lbz2"
            OPENSSL="$ROOT/openssl/$PLATFORM$SDK_VERSION-arm64.sdk"
        else
            PLATFORM=$PLATFORM_DEVICE
            export SDKPATH=$SDKPATH_DEVICE
            ACFLAGS="-arch $ARCH -isysroot $SDKPATH $MIN_VERSION_DEVICE_CFLAG=$DEPLOYMENT_TARGET"
            ALDFLAGS="-arch $ARCH -isysroot $SDKPATH $MIN_VERSION_DEVICE_LDFLAG,$DEPLOYMENT_TARGET -lbz2"
            OPENSSL="$ROOT/openssl/$PLATFORM$SDK_VERSION-arm64.sdk"
        fi
	elif [[ $ARCH = "x86_64" ]]; then
        HOSTFLAG="x86_64"
        CMAKE_OSX_ARCHITECTURES=$ARCH
        PLATFORM=$PLATFORM_SIMULATOR
		export SDKPATH=$SDKPATH_SIMULATOR
		ACFLAGS="-arch $ARCH -isysroot $SDKPATH $MIN_VERSION_SIMULATOR_CFLAG=$DEPLOYMENT_TARGET"
		ALDFLAGS="-arch $ARCH -isysroot $SDKPATH $MIN_VERSION_SIMULATOR_LDFLAG,$DEPLOYMENT_TARGET -lbz2"
		OPENSSL="$ROOT/openssl/$PLATFORM$SDK_VERSION-x86_64.sdk"
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

    PKG_CONFIG_PATH="$SCRATCH/$ARCH-$ENVIRONMENT/lib/pkgconfig"
    COMMON_OPTIONS="--prefix=$SCRATCH/$ARCH-$ENVIRONMENT --exec-prefix=$SCRATCH/$ARCH-$ENVIRONMENT --build=x86_64-apple-darwin14 --enable-static \
                    --disable-shared --disable-dependency-tracking --with-pic --host=$HOSTFLAG"
    
    for LIBRARY in $LIBRARIES; do
        case $LIBRARY in
            "libfribidi" )
				mkdir -p $SCRATCH/$ARCH-$ENVIRONMENT/fribidi && cd $_ && $SCRIPTS/fribidi-build
				;;
            "libfreetype" )
				mkdir -p $SCRATCH/$ARCH-$ENVIRONMENT/freetype && cd $_ && $SCRIPTS/freetype-build
				;;
            "libharfbuzz" )
				mkdir -p $SCRATCH/$ARCH-$ENVIRONMENT/harfbuzz && cd $_ && $SCRIPTS/harfbuzz-build
				;;
            "libass" )
				mkdir -p $SCRATCH/$ARCH-$ENVIRONMENT/libass && cd $_ && $SCRIPTS/libass-build
				;;
            "libuchardet" )
				mkdir -p $SCRATCH/$ARCH-$ENVIRONMENT/uchardet && cd $_ && $SCRIPTS/uchardet-build
				;;
            "ffmpeg" )
				mkdir -p $SCRATCH/$ARCH-$ENVIRONMENT/ffmpeg && cd $_ && $SCRIPTS/ffmpeg-build
				;;
            "libmpv" )
                if [[ "$ENVIRONMENT" = "development" ]]; then
                    CFLAGS="$ACFLAGS -fembed-bitcode -g2 -Og"
                    LDFLAGS="$ALDFLAGS -fembed-bitcode -g2 -Og"
                fi
				$SCRIPTS/mpv-build && cp $SRC/mpv*/build/libmpv.a "$SCRATCH/$ARCH-$ENVIRONMENT/lib"
				;;
            "libssl" )
                cp -a $OPENSSL/include/. $SCRATCH/$ARCH-$ENVIRONMENT/include/
                cp -a $OPENSSL/lib/. $SCRATCH/$ARCH-$ENVIRONMENT/lib/
				;;
        esac
    done
done
