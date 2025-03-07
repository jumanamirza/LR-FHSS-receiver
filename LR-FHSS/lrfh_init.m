% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

% NOTE: should run when start

lrfh_USE_WRAPPER = 0;
lrfh_init_light;
load ../pkttrace/ALL_PKT_INFO_1.mat

[y,LRF_cfg.iir] = lowpass(randn(1,100000), LRF_cfg.lowpassHz, LRF_cfg.samplingrate, ...
                'ImpulseResponse','iir','StopbandAttenuation', 100, 'Steepness', 0.9); 