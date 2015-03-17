#ifndef __FFT__
#define __FFT__

void fft_d(double *REX, double *IMX, unsigned int N);
void fft(float *REX, float *IMX, unsigned int N);
void ifft_d(double *REX, double *IMX, unsigned int N);
void ifft(float *REX, float *IMX, unsigned int N);
void mag_phase_response(float *REX, float *IMX, float *MAG, float *PHA, unsigned int N);
#endif
