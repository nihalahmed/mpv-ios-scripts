#!/bin/sh -e

LIBRARIES="libuchardet libfribidi libfreetype libharfbuzz libass libmpv libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale libcrypto libssl"
PLATFORMS="ios tv"
ROOT="$(pwd)"
LIB="$ROOT/lib"
mkdir -p $LIB

for PLATFORM in $PLATFORMS; do
    SCRATCH="$ROOT/scratch-$PLATFORM"
    ENVIRONMENTS=""

    if [ -d "$SCRATCH/x86_64-development" ] && [ -d "$SCRATCH/arm64-development" ]; then
        ENVIRONMENTS="$ENVIRONMENTS development"
        mkdir -p $SCRATCH/development
        for LIBRARY in $LIBRARIES; do
            lipo -create $SCRATCH/x86_64-development/lib/$LIBRARY.a $SCRATCH/arm64-development/lib/$LIBRARY.a -o $SCRATCH/development/$LIBRARY
        done
    fi

    if [[ -d "$SCRATCH/arm64-distribution" ]]; then
        ENVIRONMENTS="$ENVIRONMENTS distribution"
        mkdir -p $SCRATCH/distribution
        for LIBRARY in $LIBRARIES; do
            cp $SCRATCH/arm64-distribution/lib/$LIBRARY.a $SCRATCH/distribution/$LIBRARY
        done
    fi

    for ENVIRONMENT in $ENVIRONMENTS; do
        LIBS=""
        for LIBRARY in $LIBRARIES; do
            LIBS="$LIBS $SCRATCH/$ENVIRONMENT/$LIBRARY"
        done
        mkdir -p $SCRATCH/$ENVIRONMENT-combined/libmpv.framework
        libtool -static -o $SCRATCH/$ENVIRONMENT-combined/libmpv.framework/libmpv $LIBS
        cp -a $ROOT/framework-meta/. $SCRATCH/$ENVIRONMENT-combined/libmpv.framework/
        FRAMEWORKS="$FRAMEWORKS -framework $SCRATCH/$ENVIRONMENT-combined/libmpv.framework"
    done
done

xcodebuild -create-xcframework $FRAMEWORKS -output $LIB/libmpv.xcframework
