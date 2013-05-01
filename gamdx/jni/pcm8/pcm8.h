#if !defined(__FMXDRVG_PCM8_H__)
#define __FMXDRVG_PCM8_H__

namespace X68K
{


class Pcm8 {
	static const int TotalVolume = 256;

	int Scale;  // 
	int Pcm;  // 16bit PCM Data
	int Pcm16Prev;  // 16bit,8bitPCMの1つ前のデータ
	int InpPcm,InpPcm_prev,OutPcm;  // HPF用 16bit PCM Data
	int OutInpPcm,OutInpPcm_prev;  // HPF用
	int AdpcmRate;  // 187500(15625*12), 125000(10416.66*12), 93750(7812.5*12), 62500(5208.33*12), 46875(3906.25*12), ...
	int RateCounter;
	int N1Data;  // ADPCM 1サンプルのデータの保存
	int N1DataFlag;  // 0 or 1

	volatile int Mode;
	volatile int Volume;  // x/16
	volatile int PcmKind;  // 0～4:ADPCM  5:16bitPCM  6:8bitPCM  7:謎

	unsigned char DmaLastValue;
	unsigned char AdpcmReg;

	volatile unsigned char *DmaMar;
	volatile unsigned int DmaMtc;
	volatile unsigned char *DmaBar;
	volatile unsigned int DmaBtc;
	volatile int DmaOcr;  // 0:チェイン動作なし 0x08:アレイチェイン 0x0C:リンクアレイチェイン

	int DmaArrayChainSetNextMtcMar();
	int DmaLinkArrayChainSetNextMtcMar();
	int DmaGetByte();
	void adpcm2pcm(unsigned char adpcm);
	void pcm16_2pcm(int pcm16);

public:

	Pcm8(void);
	~Pcm8() {};
	void Init();
	void Reset();

	int Out(void *adrs, int mode, int len);
	int Aot(void *tbl, int mode, int cnt);
	int Lot(void *tbl, int mode);
	int SetMode(int mode);
	int GetRest();
	int GetMode();

	int GetPcm22();
	int GetPcm62();

};

}

#endif  // __FMXDRVG_PCM8_H__

// [EOF]
