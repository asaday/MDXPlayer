#include "downsample.h"
#include "global.h"


namespace X68K
{


// ---------------------------------------------------------------------------
//	構築
//
DOWNSAMPLE::DOWNSAMPLE()
{
	Init(62500, 62500, true);
}

// ---------------------------------------------------------------------------
//	初期化
//
bool DOWNSAMPLE::Init(int inrate, int outrate, bool fastmode)
{
	SetRate(inrate, outrate, fastmode);

	for (int i=0; i<LPF_COL*2; ++i) {
		InpFirBuf0[i] = InpFirBuf1[i]=0;
	}
	InpFir_idx = 0;
	LPFidx = 0;
	LPFp = LOWPASS;
	LPFc = LPF_ROW;

#if 0
	for (int i=0; i<2; i++) {
		InpInpOpm[i] = 0;
		InpOpm[i] = 0;
		InpInpOpm_prev[i] = 0;
		InpOpm_prev[i] = 0;
		InpInpOpm_prev2[i] = 0;
		InpOpm_prev2[i] = 0;
		OpmHpfInp[i] = 0;
		OpmHpfInp_prev[i] = 0;
		OpmHpfOut[i] = 0;
	}
#endif

	return true;
}

// ---------------------------------------------------------------------------
//	サンプルレート設定
//
bool DOWNSAMPLE::SetRate(int inrate, int outrate, bool fastmode)
{
	if ((inrate == 22050) && (outrate == 22050)) {
		PreFirRate = 22050;
		PostFirRate = 22050;
		LPF_ROW = 0;
		LOWPASS = NULL;
		FastMode = true;
		return true;
	}
	if (inrate != 62500) {
		return false;
	}
	if (outrate == 44100) {
		PreFirRate = 62500;
		PostFirRate = 44100;
		LPF_ROW = LPF_ROW_44;
		LOWPASS = (int16 *)LOWPASS_44;
		FastMode = fastmode;
	} else if (outrate == 48000) {
		PreFirRate = 62500;
		PostFirRate = 48000;
		LPF_ROW = LPF_ROW_48;
		LOWPASS = (int16 *)LOWPASS_48;
		FastMode = fastmode;
	} else {
		PreFirRate = 62500;
		PostFirRate = 62500;
		LPF_ROW = 0;
		LOWPASS = NULL;
		FastMode = true;
	}

	return true;
}

// ---------------------------------------------------------------------------
//	リセット
//
void DOWNSAMPLE::Reset()
{
	Init(PreFirRate, PostFirRate, FastMode);
}

// ---------------------------------------------------------------------------
//	ダウンサンプリング
//
void DOWNSAMPLE::DownSample(Sample *inbuf, int noutsamples, Sample *outbuf)
{
	sint32 OutFir[2];

	if (FastMode||(LPF_ROW == 0)||(LOWPASS == NULL)) {
		if (PreFirRate == PostFirRate) {
			memcpy(outbuf, inbuf, noutsamples*sizeof(Sample)*2);
			return;
		}
		for (int i=0; i<noutsamples; ++i) {
			*(outbuf++) = inbuf[0];
			*(outbuf++) = inbuf[1];
			LPFidx += PreFirRate;
			while (LPFidx >= PostFirRate) {
				LPFidx -= PostFirRate;
				inbuf++;
				inbuf++;
			}
		}
		return;
	}

	for (int i=0; i<noutsamples; ++i) {

		LPFidx += PreFirRate;
		while (LPFidx >= PostFirRate) {
			LPFidx -= PostFirRate;

			--InpFir_idx;
			if (InpFir_idx < 0) InpFir_idx = LPF_COL-1;
#if 1
			InpFirBuf0[InpFir_idx] = InpFirBuf0[InpFir_idx+LPF_COL] =
			  (sint16)*(inbuf++);
			InpFirBuf1[InpFir_idx] = InpFirBuf1[InpFir_idx+LPF_COL] =
			  (sint16)*(inbuf++);
#else
			OpmHpfInp[0] = ((sint16)*(inbuf++))<<14;
			OpmHpfInp[1] = ((sint16)*(inbuf++))<<14;

			OpmHpfOut[0] = OpmHpfInp[0]-OpmHpfInp_prev[0]+
			  OpmHpfOut[0]-(OpmHpfOut[0]>>10)-(OpmHpfOut[0]>>12);
			OpmHpfOut[1] = OpmHpfInp[1]-OpmHpfInp_prev[1]+
			  OpmHpfOut[1]-(OpmHpfOut[1]>>10)-(OpmHpfOut[1]>>12);

			OpmHpfInp_prev[0] = OpmHpfInp[0];
			OpmHpfInp_prev[1] = OpmHpfInp[1];

			InpInpOpm[0] = OpmHpfOut[0] >> (4+5);
			InpInpOpm[1] = OpmHpfOut[1] >> (4+5);

			InpInpOpm[0] = InpInpOpm[0]*29;
			InpInpOpm[1] = InpInpOpm[1]*29;

			InpOpm[0] = (InpInpOpm[0] + InpInpOpm_prev[0]+
			  InpOpm[0]*70) >> 7;
			InpOpm[1] = (InpInpOpm[1] + InpInpOpm_prev[1] +
			  InpOpm[1]*70) >> 7;

			InpInpOpm_prev[0] = InpInpOpm[0];
			InpInpOpm_prev[1] = InpInpOpm[1];

			InpFirBuf0[InpFir_idx] = InpFirBuf0[InpFir_idx+LPF_COL] =
			  InpOpm[0] >> 5;
			InpFirBuf1[InpFir_idx] = InpFirBuf1[InpFir_idx+LPF_COL] =
			  InpOpm[1] >> 5;
#endif

		}

		FirMatrix(LPFp, &InpFirBuf0[InpFir_idx], &InpFirBuf1[InpFir_idx], OutFir);

		if (LPFc) {
			LPFp += LPF_COL;
			LPFc--;
			if (LPFc == 0) {
				LPFc = LPF_ROW;
				LPFp = (int16 *)LOWPASS;
			}
		}

		sint32 out;
		out = -OutFir[0];
		if ((uint32)(out+32767) > (uint32)(32767*2)) {
			if ((sint32)(out+32767) >= (sint32)(32767*2)) {
				*(outbuf++) = 32767;
			} else {
				*(outbuf++) = -32767;
			}
		} else {
			*(outbuf++) = (Sample)out;
		}
		
		out = -OutFir[1];
		if ((uint32)(out+32767) > (uint32)(32767*2)) {
			if ((sint32)(out+32767) >= (sint32)(32767*2)) {
				*(outbuf++) = 32767;
			} else {
				*(outbuf++) = -32767;
			}
		} else {
			*(outbuf++) = (Sample)out;
		}
	}
}


// ---------------------------------------------------------------------------
//	ダウンサンプル出力数に必要な入力サンプル数を求める
//
int DOWNSAMPLE::GetInSamplesForDownSample(int noutsamples)
{
	int n = LPFidx+(noutsamples*PreFirRate);
//	return ((n+PostFirRate-1)/PostFirRate);
	return (n/PostFirRate);
}


// ---------------------------------------------------------------------------
}  // namespace X68K

// [EOF]
