# mpv iOS build scripts

These are build scripts for building [libmpv](https://github.com/mpv-player/mpv), and its dependencies:

* FFmpeg
* libass
* freetype
* harfbuzz
* fribidi
* uchardet

Currently used to help build [Outplayer](http://get.outplayer.app) on iOS.

## Configuration

Tested with:

* macOS 12.5
* Xcode 14.1

## Usage

1. [Build OpenSSL](https://github.com/x2on/OpenSSL-for-iPhone/tree/dc64c470b5e1aeec5d66d861e6dc164478c9289b) for iOS and tvOS
2. Copy built OpenSSL libraries to `./openssl`
3. Run `./download.sh` to download and unarchive the projects' source
4. Run `./compile.sh -p PLATFORM -e ENVIRONMENT`, where platform is one of `ios`, `tv` and environment is one of:

`development`: builds x86_64 and arm64 static libaries, and builds mpv with debug symbols and no optimization.

`distribution`: builds arm64 static libraries, adds bitcode, and adds `-Os` to optimize for size and speed.

5. Run `./xcframework.sh` to create a framework from the development and distribution architectures.

Alternatively, run `./build.sh` to build and create a framework for iOS and tvOS from the development and distribution architectures.

## References

These scripts build upon [ybma-xbzheng/mpv-build-mac-iOS](https://github.com/ybma-xbzheng/mpv-build-mac-iOS) and [mpv-player/mpv-build](https://github.com/mpv-player/mpv-build)