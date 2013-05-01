LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE    := libmxdrvg
LOCAL_SRC_FILES := jniwrap.cpp    downsample/downsample.cpp    fmgen/fmgen.cpp fmgen/fmtimer.cpp fmgen/opm.cpp    mxdrvg/so.cpp    pcm8/pcm8.cpp pcm8/x68pcm8.cpp
LOCAL_LDLIBS    := -llog
# -lm
# -ljnigraphics

include $(BUILD_SHARED_LIBRARY)
