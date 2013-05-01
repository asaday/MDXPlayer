#if !defined(__FMXDRVG_DOWNSAMPLE_H__)
#define __FMXDRVG_DOWNSAMPLE_H__

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <assert.h>

#define LPF_COL 64

#include "../types.h"

namespace X68K
{
	typedef MXDRVG_SAMPLETYPE Sample;
	typedef int32 ISample;

	class DOWNSAMPLE
	{
	public:
		DOWNSAMPLE();
		~DOWNSAMPLE() {}

		bool Init(int inrate, int outrate, bool fastmode);
		bool SetRate(int inrate, int outrate, bool fastmode);
		void Reset();

		void DownSample(Sample *inbuf, int noutsamples, Sample *outbuf);
		int GetInSamplesForDownSample(int noutsamples);

	private:
		double inpfirbuf_dummy;
		sint16 InpFirBuf0[LPF_COL*2];
		sint16 InpFirBuf1[LPF_COL*2];
		int InpFir_idx;
		int LPFidx;
		sint16 *LPFp;
		int LPFc;
		int PreFirRate;
		int PostFirRate;
		bool FastMode;

#if 0
		int InpInpOpm[2];
		int InpOpm[2];
		int InpInpOpm_prev[2];
		int InpOpm_prev[2];
		int InpInpOpm_prev2[2];
		int InpOpm_prev2[2];
		int OpmHpfInp[2];
		int OpmHpfInp_prev[2];
		int OpmHpfOut[2];;
#endif

	};
}

#endif  // __FMXDRVG_DOWNSAMPLE_H__

// [EOF]
