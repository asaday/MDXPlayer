#include "x68pcm8.h"

namespace X68K
{


// ---------------------------------------------------------------------------
//	構築
//
X68PCM8::X68PCM8()
{
}

// ---------------------------------------------------------------------------
//	初期化
//
bool X68PCM8::Init(uint rate)
{
	mMask = 0;
	mVolume = 256;
	for (int i=0; i<PCM8_NCH; ++i) {
		mPcm8[i].Init();
	}

	OutInpAdpcm[0] = OutInpAdpcm[1] =
	  OutInpAdpcm_prev[0] = OutInpAdpcm_prev[1] =
	  OutInpAdpcm_prev2[0] = OutInpAdpcm_prev2[1] =
	  OutOutAdpcm[0] = OutOutAdpcm[1] =
	  OutOutAdpcm_prev[0] = OutOutAdpcm_prev[1] =
	  OutOutAdpcm_prev2[0] = OutOutAdpcm_prev2[1] =
	  0;
	OutInpOutAdpcm[0] = OutInpOutAdpcm[1] =
	  OutInpOutAdpcm_prev[0] = OutInpOutAdpcm_prev[1] =
	  OutInpOutAdpcm_prev2[0] = OutInpOutAdpcm_prev2[1] =
	  OutOutInpAdpcm[0] = OutOutInpAdpcm[1] =
	  OutOutInpAdpcm_prev[0] = OutOutInpAdpcm_prev[1] =
	  0;

	SetRate(rate);

	return true;
}

// ---------------------------------------------------------------------------
//	サンプルレート設定
//
bool X68PCM8::SetRate(uint rate)
{
	mSampleRate = rate;

	return true;
}

// ---------------------------------------------------------------------------
//	リセット
//
void X68PCM8::Reset()
{
	Init(mSampleRate);
}

// ---------------------------------------------------------------------------
//	パラメータセット
//
int X68PCM8::Out(int ch, void *adrs, int mode, int len)
{
	return mPcm8[ch & (PCM8_NCH-1)].Out(adrs, mode, len);
}

// ---------------------------------------------------------------------------
//	アボート
//
void X68PCM8::Abort()
{
	Reset();
}

// ---------------------------------------------------------------------------
//	チャンネルマスクの設定
//
void X68PCM8::SetChannelMask(uint mask)
{
	mMask = mask;
}

// ---------------------------------------------------------------------------
//	音量設定
//
void X68PCM8::SetVolume(int db)
{
	db = Min(db, 20);
	if (db > -192)
		mVolume = int(16384.0 * pow(10, db / 40.0));
	else
		mVolume = 0;
}


// ---------------------------------------------------------------------------
//	62500Hz用ADPCM合成処理
//
inline void X68PCM8::pcmset62500(Sample* buffer, int ndata) {
	Sample* limit = buffer + ndata * 2;
	for (Sample* dest = buffer; dest < limit; dest+=2) {
		OutInpAdpcm[0] = OutInpAdpcm[1] = 0;

		for (int ch=0; ch<PCM8_NCH; ++ch) {
			int pan = mPcm8[ch].GetMode();
			int o = mPcm8[ch].GetPcm62();
			if (o != 0x80000000) {
				OutInpAdpcm[0] += (-(pan&1)) & o;
				OutInpAdpcm[1] += (-((pan>>1)&1)) & o;
			}
		}
		OutInpAdpcm[0] = (OutInpAdpcm[0] * mVolume) >> 8;
		OutInpAdpcm[1] = (OutInpAdpcm[1] * mVolume) >> 8;

		#define LIMITS ((1<<19)-1)
		if ((uint32)(OutInpAdpcm[0]+LIMITS) > (uint32)(LIMITS*2)) {
			if ((sint32)(OutInpAdpcm[0]+LIMITS) >= (sint32)(LIMITS*2)) {
				OutInpAdpcm[0] = LIMITS;
			} else {
				OutInpAdpcm[0] = -LIMITS;
			}
		}
		if ((uint32)(OutInpAdpcm[1]+LIMITS) > (uint32)(LIMITS*2)) {
			if ((sint32)(OutInpAdpcm[1]+LIMITS) >= (sint32)(LIMITS*2)) {
				OutInpAdpcm[1] = LIMITS;
			} else {
				OutInpAdpcm[1] = -LIMITS;
			}
		}
		#undef LIMITS
		OutInpAdpcm[0] *= 26;
		OutInpAdpcm[1] *= 26;

		OutInpOutAdpcm[0] = (
		  OutInpAdpcm[0] + OutInpAdpcm_prev[0] +
		  OutInpAdpcm_prev[0] + OutInpAdpcm_prev2[0] -
		  OutInpOutAdpcm_prev[0]*(-1537) - OutInpOutAdpcm_prev2[0]*617
		 ) >> 10;
		OutInpOutAdpcm[1] = (
		  OutInpAdpcm[1] + OutInpAdpcm_prev[1] +
		  OutInpAdpcm_prev[1] + OutInpAdpcm_prev2[1] -
		  OutInpOutAdpcm_prev[1]*(-1537) - OutInpOutAdpcm_prev2[1]*617
		) >> 10;

		OutInpAdpcm_prev2[0] = OutInpAdpcm_prev[0];
		OutInpAdpcm_prev2[1] = OutInpAdpcm_prev[1];
		OutInpAdpcm_prev[0] = OutInpAdpcm[0];
		OutInpAdpcm_prev[1] = OutInpAdpcm[1];
		OutInpOutAdpcm_prev2[0] = OutInpOutAdpcm_prev[0];
		OutInpOutAdpcm_prev2[1] = OutInpOutAdpcm_prev[1];
		OutInpOutAdpcm_prev[0] = OutInpOutAdpcm[0];
		OutInpOutAdpcm_prev[1] = OutInpOutAdpcm[1];

		OutOutInpAdpcm[0] = OutInpOutAdpcm[0] * (356);
		OutOutInpAdpcm[1] = OutInpOutAdpcm[1] * (356);
		OutOutAdpcm[0] = (
		  OutOutInpAdpcm[0] + OutOutInpAdpcm_prev[0] -
		  OutOutAdpcm_prev[0]*(-312)
		) >> 10;
		OutOutAdpcm[1] = (
		  OutOutInpAdpcm[1] + OutOutInpAdpcm_prev[1] -
		  OutOutAdpcm_prev[1]*(-312)
		) >> 10;

		OutOutInpAdpcm_prev[0] = OutOutInpAdpcm[0];
		OutOutInpAdpcm_prev[1] = OutOutInpAdpcm[1];
		OutOutAdpcm_prev[0] = OutOutAdpcm[0];
		OutOutAdpcm_prev[1] = OutOutAdpcm[1];

		// -2048*16～+2048*16 OPMとADPCMの音量バランス調整
		StoreSample(dest[0], (OutOutAdpcm[0]*506) >> (4+9));
		StoreSample(dest[1], (OutOutAdpcm[1]*506) >> (4+9));
	}
}


// ---------------------------------------------------------------------------
//	22050Hz用ADPCM合成処理
//
inline void X68PCM8::pcmset22050(Sample* buffer, int ndata) {
	Sample* limit = buffer + ndata * 2;
	for (Sample* dest = buffer; dest < limit; dest+=2) {

		static int rate=0,rate2=0;
		rate2 -= 15625;
		if (rate2 < 0) {
			rate2 += 22050;
			OutInpAdpcm[0] = OutInpAdpcm[1] = 0;

			for (int ch=0; ch<PCM8_NCH; ++ch) {
				int pan = mPcm8[ch].GetMode();
				int o = mPcm8[ch].GetPcm22();
				if (o != 0x80000000) {
					OutInpAdpcm[0] += (-(pan&1)) & o;
					OutInpAdpcm[1] += (-((pan>>1)&1)) & o;
				}
			}
			OutInpAdpcm[0] = (OutInpAdpcm[0] * mVolume) >> 8;
			OutInpAdpcm[1] = (OutInpAdpcm[1] * mVolume) >> 8;

			#define LIMITS ((1<<19)-1)
			if ((uint32)(OutInpAdpcm[0]+LIMITS) > (uint32)(LIMITS*2)) {
				if ((sint32)(OutInpAdpcm[0]+LIMITS) >= (sint32)(LIMITS*2)) {
					OutInpAdpcm[0] = LIMITS;
				} else {
					OutInpAdpcm[0] = -LIMITS;
				}
			}
			if ((uint32)(OutInpAdpcm[1]+LIMITS) > (uint32)(LIMITS*2)) {
				if ((sint32)(OutInpAdpcm[1]+LIMITS) >= (sint32)(LIMITS*2)) {
					OutInpAdpcm[1] = LIMITS;
				} else {
					OutInpAdpcm[1] = -LIMITS;
				}
			}
			#undef LIMITS

			OutInpAdpcm[0] *= 40;
			OutInpAdpcm[1] *= 40;
		}
		OutOutAdpcm[0] = (
		  OutInpAdpcm[0] + OutInpAdpcm_prev[0] +
		  OutInpAdpcm_prev[0] + OutInpAdpcm_prev2[0] -
		  OutOutAdpcm_prev[0]*(-157) - OutOutAdpcm_prev2[0]*61
		 ) >> 8;
		OutOutAdpcm[1] = (
		  OutInpAdpcm[1] + OutInpAdpcm_prev[1] +
		  OutInpAdpcm_prev[1] + OutInpAdpcm_prev2[1] -
		  OutOutAdpcm_prev[1]*(-157) - OutOutAdpcm_prev2[1]*61
		) >> 8;

		OutInpAdpcm_prev2[0] = OutInpAdpcm_prev[0];
		OutInpAdpcm_prev2[1] = OutInpAdpcm_prev[1];
		OutInpAdpcm_prev[0] = OutInpAdpcm[0];
		OutInpAdpcm_prev[1] = OutInpAdpcm[1];
		OutInpOutAdpcm_prev2[0] = OutInpOutAdpcm_prev[0];
		OutInpOutAdpcm_prev2[1] = OutInpOutAdpcm_prev[1];
		OutInpOutAdpcm_prev[0] = OutInpOutAdpcm[0];
		OutInpOutAdpcm_prev[1] = OutInpOutAdpcm[1];

		StoreSample(dest[0], (OutOutAdpcm[0]>>4));
		StoreSample(dest[1], (OutOutAdpcm[1]>>4));
	}
}


// ---------------------------------------------------------------------------
//	合成 (stereo)
//
void X68PCM8::Mix(Sample* buffer, int nsamples)
{
	if (mSampleRate == 22050) {
		pcmset22050(buffer, nsamples);
	} else {
		pcmset62500(buffer, nsamples);
	}
}

// ---------------------------------------------------------------------------
}  // namespace X68K

// [EOF]
