% NOTE: should run when start
lrfh_init_light;
[y,LRF_cfg.iir] = lowpass(randn(1,100000), LRF_cfg.lowpassHz, LRF_cfg.samplingrate, ...
                'ImpulseResponse','iir','StopbandAttenuation', 100, 'Steepness', 0.9); 

