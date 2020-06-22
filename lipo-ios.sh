#!/bin/sh -e

LIBRARIES="libuchardet libfribidi libfreetype libharfbuzz libass ffmpeg libmpv libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale"
ROOT="$(pwd)"
SCRATCH="$ROOT/scratch-ios"
LIB="$ROOT/lib-ios"
mkdir -p $LIB

for LIBRARY in $LIBRARIES; do
    if [[ "$LIBRARY" != "ffmpeg" ]]; then
        lipo -create $SCRATCH/arm64/lib/$LIBRARY.a -create $SCRATCH/armv7/lib/$LIBRARY.a $SCRATCH/x86_64/lib/$LIBRARY.a -o $LIB/$LIBRARY.a
    fi
    if [[ "$LIBRARY" = "libavcodec" ]]; then
        zip -r -j $LIB/$LIBRARY.a.zip $LIB/$LIBRARY.a
        rm -f $LIB/$LIBRARY.a
    fi
done
