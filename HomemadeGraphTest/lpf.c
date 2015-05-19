//
//  lpf.c
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/21/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#include <stdio.h>
#include <math.h>
#include "lpf.h"

void GMBProcessArray_BiQuad2ndOrderLPF_Mono(float* src, float fc, float Q, int N)
{
	int n = 0;				//Counter
	
	if (N <= 0)
		return;
	if (Q > 10)
		Q = 10;
	if (Q <= 0)
		Q = 0.707;
	if (fc <= 0)
		fc = 500;
	if (fc > 20000)
		fc = 20000;
	
	//Initialize our coefficients.
	lpf.d = 1 / Q;
	lpf.fc_r = (2 * M_PI * fc) / lpf.Fs;
	lpf.beta = 0.5 * (1 - ( (lpf.d / 2.0) * sin(lpf.fc_r) ) ) / ( 1 + (lpf.d / 2.0) * sin(lpf.fc_r) );
	lpf.gamma = (0.5 + lpf.beta) * cos(lpf.fc_r);
	lpf.a0 = (0.5 + lpf.beta - lpf.gamma);
	lpf.a1 = (0.5 + lpf.beta - lpf.gamma) / 2.0;
	lpf.a2 = lpf.a0;
	lpf.b1 = -2 * lpf.gamma;
	lpf.b2 = 2 * lpf.beta;
	
	while (n < N)
	{
		while (flt_start && n < 3)
		{
			switch (n)
			{
				case 0:
					lpf.xnL = *(src + n);																//Store current sample as x(n)
					lpf.ynL = (lpf.a0 * lpf.xnL) + (lpf.a1 * lpf.xn_1L) + (lpf.a2 * lpf.xn_2L) - (lpf.b1 * lpf.yn_1L) - (lpf.b2 * lpf.yn_2L);	//Calculate the value of the output sample
					*(src + n) = lpf.ynL;																//Send the output sample to the output.
					break;
				case 1:																				//Repeat case 0 for left channel but also take care of propagating prior samples through the one sample delay pipeline
					lpf.xn_1L = lpf.xnL;
					lpf.xnL = *(src + n);
					lpf.yn_1L = lpf.ynL;
					lpf.ynL = (lpf.a0 * lpf.xnL) + (lpf.a1 * lpf.xn_1L) + (lpf.a2 * lpf.xn_2L) - (lpf.b1 * lpf.yn_1L) - (lpf.b2 * lpf.yn_2L);
					*(src + n) = lpf.ynL;
					break;

				case 2:
					lpf.xn_2L = lpf.xn_1L;
					lpf.xn_1L = lpf.xnL;
					lpf.xnL = *(src + n);
					lpf.yn_2L = lpf.yn_1L;
					lpf.yn_1L = lpf.ynL;
					lpf.ynL = (lpf.a0 * lpf.xnL) + (lpf.a1 * lpf.xn_1L) + (lpf.a2 * lpf.xn_2L) - (lpf.b1 * lpf.yn_1L) - (lpf.b2 * lpf.yn_2L);
					*(src + n) = lpf.ynL;
					break;
			}
			++n;
			if (n >= 3)
				flt_start = 0;
		}

		lpf.yn_2L = lpf.yn_1L;
		lpf.yn_1L = lpf.ynL;
		lpf.xn_2L = lpf.xn_1L;
		lpf.xn_1L = lpf.xnL;
		lpf.xnL = *(src + n);
		lpf.ynL = (lpf.a0 * lpf.xnL) + (lpf.a1 * lpf.xn_1L) + (lpf.a2 * lpf.xn_2L) - (lpf.b1 * lpf.yn_1L) - (lpf.b2 * lpf.yn_2L);
		*(src + n) = lpf.ynL;
		++n;
	}

}


void GMBProcessArray_BiQuad2ndOrderLPF_Stereo(float* src, float fc, float Q, int N)
{
	int n = 0;				//Counter

	if (N <= 0)
		return;
	if (Q > 10)
		Q = 10;
	if (Q <= 0)
		Q = 0.707;
	if (fc <= 0)
		fc = 500;
	if (fc > 20000)
		fc = 20000;

	//Initialize our coefficients.
	lpf.d = 1 / Q;
	lpf.fc_r = (2 * M_PI * fc) / lpf.Fs;
	lpf.beta = 0.5 * (1 - ( (lpf.d / 2.0) * sin(lpf.fc_r) ) ) / ( 1 + (lpf.d / 2.0) * sin(lpf.fc_r) );
	lpf.gamma = (0.5 + lpf.beta) * cos(lpf.fc_r);
	lpf.a0 = (0.5 + lpf.beta - lpf.gamma);
	lpf.a1 = (0.5 + lpf.beta - lpf.gamma) / 2.0;
	lpf.a2 = lpf.a0;
	lpf.b1 = -2 * lpf.gamma;
	lpf.b2 = 2 * lpf.beta;
	
	while (n < N)
	{
		while (flt_start && n < 5)
		{
			switch (n)
			{
				case 0:
					lpf.xnL = *(src + n);																//Store current sample as x(n)
					lpf.ynL = (lpf.a0 * lpf.xnL) + (lpf.a1 * lpf.xn_1L) + (lpf.a2 * lpf.xn_2L) - (lpf.b1 * lpf.yn_1L) - (lpf.b2 * lpf.yn_2L);	//Calculate the value of the output sample
					*(src + n) = lpf.ynL;																//Send the output sample to the output.
					break;
				case 1:																				//Repeat case 0 for the right channel
					lpf.xnR = *(src + n);
					lpf.ynR = (lpf.a0 * lpf.xnR) + (lpf.a1 * lpf.xn_1R) + (lpf.a2 * lpf.xn_2R) - (lpf.b1 * lpf.yn_1R) - (lpf.b2 * lpf.yn_2R);
					*(src + n) = lpf.ynR;
					break;
				case 2:																				//Repeat case 0 for left channel but also take care of propagating prior samples through the one sample delay pipeline
					lpf.xn_1L = lpf.xnL;
					lpf.xnL = *(src + n);
					lpf.yn_1L = lpf.ynL;
					lpf.ynL = (lpf.a0 * lpf.xnL) + (lpf.a1 * lpf.xn_1L) + (lpf.a2 * lpf.xn_2L) - (lpf.b1 * lpf.yn_1L) - (lpf.b2 * lpf.yn_2L);
					*(src + n) = lpf.ynL;
					break;
				case 3:																				//Repeat case 2 for the right channel, etc etc...
					lpf.xn_1R = lpf.xnR;
					lpf.xnR = *(src + n);
					lpf.ynR = (lpf.a0 * lpf.xnR) + (lpf.a1 * lpf.xn_1R) + (lpf.a2 * lpf.xn_2R) - (lpf.b1 * lpf.yn_1R) - (lpf.b2 * lpf.yn_2R);
					*(src + n) = lpf.ynR;
					break;
				case 4:
					lpf.xn_2L = lpf.xn_1L;
					lpf.xn_1L = lpf.xnL;
					lpf.xnL = *(src + n);
					lpf.yn_2L = lpf.yn_1L;
					lpf.yn_1L = lpf.ynL;
					lpf.ynL = (lpf.a0 * lpf.xnL) + (lpf.a1 * lpf.xn_1L) + (lpf.a2 * lpf.xn_2L) - (lpf.b1 * lpf.yn_1L) - (lpf.b2 * lpf.yn_2L);
					*(src + n) = lpf.ynL;
					break;
				case 5:
					lpf.yn_2R = lpf.yn_1R;
					lpf.yn_1R = lpf.ynR;
					lpf.xn_2R = lpf.xn_1R;
					lpf.xn_1R = lpf.xnR;
					lpf.xnR = *(src + n);
					lpf.ynR = (lpf.a0 * lpf.xnR) + (lpf.a1 * lpf.xn_1R) + (lpf.a2 * lpf.xn_2R) - (lpf.b1 * lpf.yn_1R) - (lpf.b2 * lpf.yn_2R);
					*(src + n) = lpf.ynR;
					break;
			}
			++n;
			if (n >= 5)
				flt_start = 0;
		}
		if (n % 2 == 0)
		{
			lpf.yn_2L = lpf.yn_1L;
			lpf.yn_1L = lpf.ynL;
			lpf.xn_2L = lpf.xn_1L;
			lpf.xn_1L = lpf.xnL;
			lpf.xnL = *(src + n);
			lpf.ynL = (lpf.a0 * lpf.xnL) + (lpf.a1 * lpf.xn_1L) + (lpf.a2 * lpf.xn_2L) - (lpf.b1 * lpf.yn_1L) - (lpf.b2 * lpf.yn_2L);
			*(src + n) = lpf.ynL;
		}
		else
		{
			lpf.yn_2R = lpf.yn_1R;
			lpf.yn_1R = lpf.ynR;
			lpf.xn_2R = lpf.xn_1R;
			lpf.xn_1R = lpf.xnR;
			lpf.xnR = *(src + n);
			lpf.ynR = (lpf.a0 * lpf.xnR) + (lpf.a1 * lpf.xn_1R) + (lpf.a2 * lpf.xn_2R) - (lpf.b1 * lpf.yn_1R) - (lpf.b2 * lpf.yn_2R);
			*(src + n) = lpf.ynR;
		}
		++n;
	}
}
