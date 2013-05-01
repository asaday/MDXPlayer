#!/bin/sh
echo Clean NDK part

ndk-build NDK_DEBUG=1 clean
ndk-build NDK_DEBUG=0 clean
