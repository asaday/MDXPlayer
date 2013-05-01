// ◇

#define LOG_TAG "mxdrvg"
#define LOG_SUBTAG "jniwrap"

#define LOGV_ENABLE 0
#define LOGD_ENABLE 0
#define LOGI_ENABLE 1

#include "jniwrap.h"
#include "mxdrvg/mxdrvg.h"

// Global env ref (for callbacks)
static JavaVM *g_VM;
static JNIEnv *g_env;
static jclass g_clazz;

static jmethodID onOPMIntFunc = NULL;
static jmethodID onTerminatePlayFunc = NULL;

static MXDRVG_WORK_CH *FM;
static MXDRVG_WORK_CH *PCM;
static MXDRVG_WORK_GLOBAL *G;
static MXDRVG_WORK_OPM *OPM;
static int UseIRQ;

static int Terminated;
static int FadeoutStart;
static int FadeoutRequest;
static int LoopLimit;

// =====================================================================
// Java VMの取得
// =====================================================================

static void getJavaVM(
	JNIEnv *env,
	jclass clazz
) {
	env->GetJavaVM(&g_VM);
	g_env = env;
	g_clazz = clazz;
}

// =====================================================================
// Javaインポート関数の取得
// =====================================================================

static int getJavaStaticMethod(
	JNIEnv *env,
	jclass clazz,
	const char *funcname,
	const char *funcsig,
	jmethodID *ret_func
) {
	jmethodID func;

	func = env->GetStaticMethodID(
		clazz,
		funcname,
		funcsig
	);
	if (func == NULL) {
		LOGE("failed GetStaticMethodID: %s[%s]", funcname, funcsig);
		return (-1);
	}
	*(ret_func) = func;

	LOGI("get Java Function: %s[%s]", funcname, funcsig);
	return (0);
}

// =====================================================================
// JNIとしてloadされたときのコールバック
// =====================================================================

jint JNI_OnLoad(
	JavaVM *vm,
	void *reserved
) {
	LOGI("start");
	return JNI_VERSION_1_6;
}

// =====================================================================
// JNIとしてunloadされるときのコールバック
// =====================================================================

void JNI_OnUnload(
	JavaVM *vm,
	void *reserved
) {
	LOGI("start");
	return;
}

// =====================================================================

void jniwrap_MXDRVG_OPMINTFUNC(
	void
);

// =====================================================================

//JNIEXPORT jint JNICALL Java_net_gorry_ndk_Natives_ndkEntry
JNIAPI(jint, ndkEntry)(
	JNIEnv *env,
	jclass cls,
	jobjectArray jargv
) {
	LOGD("start");
	return 0;
}

JNIAPI(jint, mxdrvgStart)(
	JNIEnv *env,
	jclass cls, 
	jint samprate,
	jint fastmode,
	jint mdxbufsize,
	jint pdxbufsize,
	jint useirq
) {
	int size;
	int ret;

	LOGI("start: env=%p", env);

	if (!env) {
		LOGE("error !env");
		return -1;
	}

	getJavaVM(env, cls);
	g_clazz = cls;

	// Natives.class#onOPMIntFunc -> javap -s Mxdrvg
	ret = getJavaStaticMethod(
		env, cls,
		"onOPMIntFunc",
		"(II[B[B)V",
		&onOPMIntFunc
	);
	if (ret < 0) {
		LOGE("failed getJavaMethod: onOPMIntFunc");
		return 0;
	}

	// Natives.class#onTerminatePlayFunc -> javap -s Natives
	ret = getJavaStaticMethod(
		env, cls,
		"onTerminatePlayFunc",
		"(I)V",
		&onTerminatePlayFunc
	);
	if (ret < 0) {
		LOGE("failed getJavaMethod: onTerminatePlayFunc");
		return 0;
	}

	UseIRQ = useirq;
	ret = MXDRVG_Start(samprate, fastmode, mdxbufsize, pdxbufsize);

	FM = (MXDRVG_WORK_CH *)MXDRVG_GetWork( MXDRVG_WORKADR_FM );
	PCM = (MXDRVG_WORK_CH *)MXDRVG_GetWork( MXDRVG_WORKADR_PCM );
	G = (MXDRVG_WORK_GLOBAL *)MXDRVG_GetWork( MXDRVG_WORKADR_GLOBAL );
	OPM = (MXDRVG_WORK_OPM *)MXDRVG_GetWork( MXDRVG_WORKADR_OPM );

	MXDRVG_CALLBACK_OPMINTFUNC **p;
	p = (MXDRVG_CALLBACK_OPMINTFUNC **)MXDRVG_GetWork( MXDRVG_WORKADR_OPMINT );
	*(p) = &jniwrap_MXDRVG_OPMINTFUNC;

	return ret;
}

JNIAPI(void, mxdrvgEnd)(
	JNIEnv *env,
	jclass cls,
	int dummy
) {
	LOGI("start: env=%p", env);
	MXDRVG_End();
}

JNIAPI(jint, mxdrvgGetPCM)(
	JNIEnv *env,
	jclass cls, 
	jshortArray buf,
	jint ofs,
	jint len
) {
	LOGD("start: env=%p, len=%d", env, len);
	jshort *a;

	getJavaVM(env, cls);

	a = env->GetShortArrayElements(buf, 0);

	MXDRVG_GetPCM(a+ofs*2, len);
#if 0
	{
		int i;
		for (i=0; i<len; i++) {
			if (a[len*2+0] || a[len*2+1]) {
				LOGD("sound found");
			}
		}
	}
#endif

	env->ReleaseShortArrayElements(buf, a, 0);
	if (Terminated) {
		LOGD("Terminated");
	} else {
		LOGD("not Terminated");
	}
	return Terminated;
}

JNIAPI(void, mxdrvgSetData)(
	JNIEnv *env,
	jclass cls, 
	jbyteArray mdx,
	jint mdxsize,
	jbyteArray pdx,
	jint pdxsize
) {
	LOGI("start: env=%p", env);
	if ((mdx == NULL) || (mdxsize == 0)) {
		return;
	}
	jbyte *jmdx = env->GetByteArrayElements(mdx, 0);
	jbyte *jpdx = NULL;
	if ((pdx != NULL) && (pdxsize != 0)) {
		jpdx = env->GetByteArrayElements(pdx, 0);
	}
#if 0
	if (jpdx) {
		int i;
		for (i=0; i<256; i+=16) {
			char s[1024];
			unsigned char *p = (unsigned char *)jpdx;
			sprintf(s, "%02X: %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X", i,
			p[i+0x00], p[i+0x01], p[i+0x02], p[i+0x03], 
			p[i+0x04], p[i+0x05], p[i+0x06], p[i+0x07], 
			p[i+0x08], p[i+0x09], p[i+0x0a], p[i+0x0b], 
			p[i+0x0c], p[i+0x0d], p[i+0x0e], p[i+0x0f]
			);
			LOGD(s);
		}
	}
#endif
	MXDRVG_SetData(jmdx, mdxsize, jpdx, pdxsize);
	if (jpdx) {
		env->ReleaseByteArrayElements(pdx, jpdx, 0);
	}
	env->ReleaseByteArrayElements(mdx, jmdx, 0);
	Terminated = 0;
}

JNIAPI(jint, mxdrvgMeasurePlayTime)(
	JNIEnv *env,
	jclass cls, 
	jint loop,
	jint fadeout
) {
	LOGI("start: env=%p", env);
	jint ret = MXDRVG_MeasurePlayTime(loop, fadeout);
	return ret;
}

JNIAPI(void, mxdrvgPlayAt)(
	JNIEnv *env,
	jclass cls, 
	jint playat,
	jint loop,
	jint fadeout
) {
	LOGI("start: env=%p", env);
	LoopLimit = loop;
	FadeoutRequest = fadeout;
	FadeoutStart = 0;
	Terminated = 0;
	MXDRVG_PlayAt(playat, loop, fadeout);
}

JNIAPI(jint, mxdrvgGetPlayAt)(
	JNIEnv *env,
	jclass cls, 
	jint dummy
) {
	LOGD("start: env=%p", env);
	return MXDRVG_GetPlayAt();
}

JNIAPI(jint, mxdrvgGetTerminated)(
	JNIEnv *env,
	jclass cls, 
	jint dummy
) {
	LOGI("start: env=%p", env);
	return Terminated;
}

JNIAPI(void, mxdrvgTotalVolume)(
	JNIEnv *env,
	jclass cls, 
	jint vol
) {
	LOGI("start: env=%p", env);
	MXDRVG_TotalVolume(vol);
}

JNIAPI(jint, mxdrvgGetTotalVolume)(
	JNIEnv *env,
	jclass cls, 
	jint vol
) {
	LOGI("start: env=%p", env);
	return MXDRVG_GetTotalVolume();
}

JNIAPI(void, mxdrvgChannelMask)(
	JNIEnv *env,
	jclass cls, 
	jint mask
) {
	LOGI("start: env=%p", env);
	MXDRVG_ChannelMask(mask);
}

JNIAPI(jint, mxdrvgGetChannelMask)(
	JNIEnv *env,
	jclass cls, 
	jint dummy
) {
	LOGI("start: env=%p", env);
	return MXDRVG_GetChannelMask();
}

JNIAPI(void, mxdrvgFadeout)(
	JNIEnv *env,
	jclass cls,
	jint dummy
) {
	LOGI("start: env=%p", env);
	MXDRVG_Fadeout();
}

JNIAPI(void, mxdrvgFadeout2)(
	JNIEnv *env,
	jclass cls,
	jint a
) {
	LOGI("start: env=%p", env);
	MXDRVG_Fadeout2(a)
}

void jniwrap_MXDRVG_OPMINTFUNC(
	void
) {
	LOGD("start");

	JNIEnv *env = NULL;
	jint result;

	if (!g_VM) {
		LOGE("No JNI VM available.");
		return;
	}
	if (!g_clazz) {
		LOGE("No JNI g_clazz available.");
		return;
	}
	result = g_VM->AttachCurrentThread((JNIEnv **)&env, NULL);
	if (result != JNI_OK)
	{
		LOGE("AttachCurrentThread() failed.\n");
		return;
	}
	if (!env) {
		LOGE("AttachCurrentThread() failed.\n");
		return;
	}
	LOGD("env=%p", env);

	if (UseIRQ & 2) {
		if (onOPMIntFunc) {
			jbyteArray jMdxChannelWork;
			jbyteArray jMdxGlobalWork;
			int size;

			size = sizeof(MXDRVG_WORK_CH)*16;
			LOGD("NewByteArray: size=%d", size);
			jMdxChannelWork = env->NewByteArray(size);
			LOGD("jMdxChannelWork=%p", jMdxChannelWork);

			size = sizeof(MXDRVG_WORK_GLOBAL);
			LOGD("NewByteArray: size=%d", size);
			jMdxGlobalWork = env->NewByteArray(size);
			LOGD("jMdxGlobalWork=%p", jMdxGlobalWork);

			int i;
			for (i=0; i<9; i++) {
				env->SetByteArrayRegion(
				  jMdxChannelWork, i*sizeof(MXDRVG_WORK_CH), sizeof(MXDRVG_WORK_CH), 
				  (jbyte *)(&FM[i])
				);
			}
			for (i=0; i<7; i++) {
				env->SetByteArrayRegion(
				  jMdxChannelWork, (i+9)*sizeof(MXDRVG_WORK_CH), sizeof(MXDRVG_WORK_CH), 
				  (jbyte *)(&PCM[i])
				);
			}

			env->SetByteArrayRegion(
			  jMdxGlobalWork, 0, sizeof(MXDRVG_WORK_GLOBAL), 
			  (jbyte *)G
			);

			env->CallStaticVoidMethod(
			  g_clazz,
			  onOPMIntFunc,
			  16,
			  sizeof(MXDRVG_WORK_CH),
			  jMdxChannelWork,
			  jMdxGlobalWork
			);

			env->DeleteLocalRef(jMdxChannelWork);
			env->DeleteLocalRef(jMdxGlobalWork);
		}
	}

	if (!Terminated) {
		if (G->L001e13 != 0) {
			 LOGD("Terminated by L001e13");
			Terminated = 1;
		}
		if (G->L002246 == 65535) {
			 LOGD("Terminated by L002246");
			Terminated = 1;
		} else {
			int loopcount;
			loopcount = G->L002246;
			if ( !FadeoutStart ) {
				if ( loopcount >= LoopLimit ) {
					if ( FadeoutRequest ) {
						FadeoutStart = TRUE;
						MXDRVG_Fadeout();
					} else {
						 LOGD("Terminated by LOOPCOUNT");
						Terminated = 1;
					}
				}
			}
		}
	}
	if (UseIRQ & 1) {
		if (Terminated) {
			jint result;
			if (onTerminatePlayFunc) {
				env->CallStaticVoidMethod(
				  g_clazz,
				  onTerminatePlayFunc,
				  0
				);
			}
		}
	}
}

// [EOF]
