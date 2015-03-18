/* Adapted from Stephen Smith's algorithm (www.dspguide.com) */
#include <math.h>

/* Fast Fourier Transform using double precision */
void fft_d(double *REX, double *IMX, unsigned int N)
{
	const unsigned int NM1 = N - 1;
	const unsigned int ND2 = N / 2;
	const unsigned int M = (unsigned int)log2((double)N);
	unsigned int k;
	unsigned int LE, LE2;
	unsigned int IP;
	int j = ND2;
	int i, l;	/* Loop counters */
	int jm1;
	double TR, TI, UR, UI, SR, SI;

	/* Bit reversal sorting */
	for (i = 1; i < N - 1; ++i) {
		if (i >= j)
			goto SKIP;
		TR = REX[j];
		TI = IMX[j];
		REX[j] = REX[i];
		IMX[j] = IMX[i];
		REX[i] = TR;
		IMX[i] = TI;
SKIP:
		k = ND2;
		while (k <= j) {
			j = j-k;
			k /= 2;
		}
		j = j + k;
	}
	
	for (l = 1; l <= M; ++l) {
		LE = pow(2.0, l);
		LE2 = LE / 2;
		UR = 1;
		UI = 0;
		SR = cos(M_PI / LE2);
		SI = sin(M_PI / LE2);
		for (j = 1; j <= LE2; ++j) {
			jm1 = j - 1;
			/* Start "buttefly" calculations */
			for (i = jm1; i <= NM1; i += LE) {
				IP = i + LE2;
				TR = REX[IP] * UR - IMX[IP] * UI;
				TI = REX[IP] * UI + IMX[IP] * UR;
				REX[IP] = REX[i] - TR;
				IMX[IP] = IMX[i] - TI;
				REX[i] = REX[i] + TR;
				IMX[i] = IMX[i] + TI;
			}
			TR = UR;
			UR = TR * SR - UI * SI;
			UI = TR * SI + UI * SR;
		}
	}
}

/* Fast Fourier Transform using single precision */
void fft(float *REX, float *IMX, unsigned int N)
{
	const unsigned int NM1 = N - 1;
	const unsigned int ND2 = N / 2;
	const unsigned int M = (unsigned int)log2((float)N);
	unsigned int k;
	unsigned int LE, LE2;
	unsigned int IP;
	int j = ND2;
	int i, l;	/* Loop counters */
	int jm1;
	float TR, TI, UR, UI, SR, SI;

	/* Bit reversal sorting */
	for (i = 1; i < N - 1; ++i) {
		if (i >= j)
			goto SKIP;
		TR = REX[j];
		TI = IMX[j];
		REX[j] = REX[i];
		IMX[j] = IMX[i];
		REX[i] = TR;
		IMX[i] = TI;
SKIP:
		k = ND2;
		while (k <= j) {
			j = j-k;
			k /= 2;
		}
		j = j + k;
	}
	
	for (l = 1; l <= M; ++l) {
		LE = pow(2.0, l);
		LE2 = LE / 2;
		UR = 1;
		UI = 0;
		SR = cos(M_PI / LE2);
		SI = sin(M_PI / LE2);
		for (j = 1; j <= LE2; ++j) {
			jm1 = j - 1;
			/* Start "buttefly" calculations */
			for (i = jm1; i <= NM1; i += LE) {
				IP = i + LE2;
				TR = REX[IP] * UR - IMX[IP] * UI;
				TI = REX[IP] * UI + IMX[IP] * UR;
				REX[IP] = REX[i] - TR;
				IMX[IP] = IMX[i] - TI;
				REX[i] = REX[i] + TR;
				IMX[i] = IMX[i] + TI;
			}
			TR = UR;
			UR = TR * SR - UI * SI;
			UI = TR * SI + UI * SR;
		}
	}
}
/* Inverse Fast Fourier Transform using double precision */
void ifft_d(double *REX, double *IMX, unsigned int N)
{
	int i, k;

	/* Change the sign of IMX[] */
	for (k = 0; k < N; ++k)
		IMX[k] *= -1;
	fft_d(REX, IMX, N);
	
	for (i=0; i < N; ++i) {
		REX[i] = REX[i] / N;
		IMX[i] = -1 * IMX[i] / N;
	}
}

/* Inverse Fast Fourier Transform using single precision */
void ifft(float *REX, float *IMX, unsigned int N)
{
	int i, k;

	/* Change the sign of IMX[] */
	for (k = 0; k < N; ++k)
		IMX[k] *= -1;
	fft(REX, IMX, N);
	
	for (i=0; i < N; ++i) {
		REX[i] = REX[i] / N;
		IMX[i] = -1 * IMX[i] / N;
	}
}

void mag_phase_response(float *REX, float *IMX, float *MAG, float *PHA, unsigned int N)
{
	float RE2, IM2;
	int i;

	for (i = 0; i < N; ++i) {
		RE2 = REX[i] * REX[i];
		IM2 = IMX[i] * IMX[i];
		MAG[i] = 20 * log10(sqrt((double)(RE2 + IM2)));
		PHA[i] = atan((double)(IMX[i] / REX[i]));
	}
}

