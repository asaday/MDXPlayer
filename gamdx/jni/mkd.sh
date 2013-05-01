#!/bin/sh
echo Compile NDK part in DEBUG build.

rm -r ../obj/local/*/*.a
ndk-build NDK_DEBUG=1 V=1
