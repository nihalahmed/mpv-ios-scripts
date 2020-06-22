#!/bin/sh -e

LIBRARIES="libuchardet libfribidi libfreetype libharfbuzz libass ffmpeg libmpv libavcodec libavdevice libavfilter libavformat libavutil libswresample libswscale"
ROOT="$(pwd)"
SCRATCH="$ROOT/scratch-tv"
LIB="$ROOT/lib-tv"
mkdir -p $LIB

for LIBRARY in $LIBRARIES; do
    if [[ "$LIBRARY" != "ffmpeg" ]]; then
        lipo -create $SCRATCH/arm64/lib/$LIBRARY.a $SCRATCH/x86_64/lib/$LIBRARY.a -o $LIB/$LIBRARY.a
    fi
done
