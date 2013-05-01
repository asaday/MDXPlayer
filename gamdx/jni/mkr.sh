#!/bin/sh
echo Compile NDK part in RELEASE build.

rm -r ../obj/local/*/*.a
ndk-build NDK_DEBUG=0 V=0
