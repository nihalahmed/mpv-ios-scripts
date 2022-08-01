#!/bin/sh -e

./compile.sh -p ios -e development && ./compile.sh -p ios -e distribution && ./compile.sh -p tv -e development && ./compile.sh -p tv -e distribution && ./xcframework.sh
