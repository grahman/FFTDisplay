//
//  lpf.h
//  HomemadeGraphTest
//
//  Created by Graham Barab on 3/21/15.
//  Copyright (c) 2015 Graham Barab. All rights reserved.
//

#ifndef LPF
#define LPF

//Filter coefficients global vars, etc...
struct lpf {
	float Fs;				//Sample rate
	float fc_r;				//Angular cutoff frequency
	float d;
	float beta;
	float gamma;
	float a0;
	float a1;
	float a2;
	float b1;
	float b2;
	
	float xnL;
	float xn_1L;
	float xn_2L;
	
	float xnR;
	float xn_1R;
	float xn_2R;
	
	float ynL;
	float yn_1L;
	float yn_2L;
	
	float ynR;
	float yn_1R;
	float yn_2R;
};

struct lpf lpf;

#endif
