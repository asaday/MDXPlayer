#include "lzx042.h"

unsigned lzx042check(const unsigned char *pData)
{
	if (pData[4] != 0x4c || pData[5] != 0x5a || pData[6] != 0x58 || pData[7] != 0x20) return 0;
	return (((unsigned)pData[0x12]) << 24) + (((unsigned)pData[0x13]) << 16) + (((unsigned)pData[0x14]) << 8) + pData[0x15];
}

unsigned lzx042decode(unsigned char *pBuffer, unsigned uBufferLength, const unsigned char *pData, unsigned uDataLength)
{

#define GETBYTE(x)			\
{							\
	if (sp == se) return 0;	\
	x = *sp++;				\
}

#define GETBIT(x)				\
{								\
	if (bitnum-- == 0)			\
	{							\
		GETBYTE(bitbuf);		\
		bitnum = 7;				\
	}							\
	x = (bitbuf >> bitnum) & 1;	\
}

#define STOREBYTE(x)		\
{							\
	if (dp == de) return 0;	\
	*dp++ = x;				\
}

	signed char bitnum;
	unsigned char bitbuf;
	unsigned char *dt, *dp, *de;
	const unsigned char *st, *sp, *se;
	dt = dp = de = pBuffer;
	de += uBufferLength;
	st = sp = se = pData;
	se += uDataLength;
	for (sp += 0x26; sp[0] != 0x7F || sp[1] != 0xFF || sp[2] != 0xFF || sp[3] != 0x4C; sp += 2) if (sp + 8 >= se) return 0;
	sp += 4;
	bitbuf = bitnum = 0;
	while (1)
	{
		unsigned char bitwork;
		GETBIT(bitwork);
		if (bitwork)
		{
			unsigned char bytework;
			GETBYTE(bytework);
			STOREBYTE(bytework);
		}
		else
		{
			int offset;
			unsigned int count;
			GETBIT(bitwork);
			if (!bitwork)
			{
				GETBIT(count);
				GETBIT(bitwork);
				count = count + count + bitwork + 2;
				GETBYTE(offset);
				offset -= 1 << 8;
			}
			else
			{
				GETBYTE(offset);
				GETBYTE(count);
				offset = (offset << 5) + (count >> 3);
				offset -= 1 << (8 + 5);
				count = (count & 7) + 2;
				if (count == 2)
				{
					GETBYTE(count);
					if (++count == 1) return dp - dt;
				}
			}
			if (dp + offset < dt) return 0;
			while (count--) STOREBYTE(dp[offset]);
		}
	}
}
