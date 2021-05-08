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

* macOS 10.15.4
* Xcode 11.3.1

## Usage

1. [Build OpenSSL](https://github.com/x2on/OpenSSL-for-iPhone/tree/OpenSSL-1.0.2l) for iOS and tvOS
2. Copy built OpenSSL libraries to `./openssl-ios` and `./openssl-tv`
3. Run `./download.sh` to download and unarchive the projects' source
4. Run `./build-ios.sh -e ENVIRONMENT`, where environment is one of:

`development`: builds x86_64 static libaries, and builds mpv with debug symbols and no optimization.

`distribution`: builds x86_64 and arm64 static libraries, adds bitcode, and adds `-Os` to optimize for size and speed.

5. Run `./lipo-ios.sh` to create fat static libraries from the development and distribution architectures.

To build for tvOS, run `./build-tv.sh` and `./lipo-tv.sh` instead.

Alternatively, run `./build.sh` to build and create fat static libraries for iOS and tvOS from the development and distribution architectures.

## References

These scripts build upon [ybma-xbzheng/mpv-build-mac-iOS](https://github.com/ybma-xbzheng/mpv-build-mac-iOS) and [mpv-player/mpv-build](https://github.com/mpv-player/mpv-build)