lrfh_init;
lrfh_init_light;
lrfh_sim_config.pkt_num = 1;
lrfh_sim_config.siglensec = 10;  
lrfh_sim_config.base_SNR_dB = -14; lrfh_sim_config.PDiff_dB = 0;
lrfh_sim_config.sim_channel = 'AWGN'; % 'AWGN' 'ETU'
lrfh_sim_config.drsel = LRF_cfg.CONST_use_DR9; % NOTE: 1: DR8, 2, DR9, 
lrfh_sim_config.USE_FILE_IDX = 1;
LRF_cfg.siglen = lrfh_sim_config.siglensec * LRF_cfg.samplingrate;
lrfh_sim_config.siglen = LRF_cfg.siglen;
lrfh_sim_config.SNR_dB = rand(1,lrfh_sim_config.pkt_num)*lrfh_sim_config.PDiff_dB + lrfh_sim_config.base_SNR_dB;
tempp = lrfh_sim_config.SNR_dB + 10*log10((LRF_cfg.allBW / LRF_cfg.samplingrate));
lrfh_sim_config.amp = sqrt(power(10, tempp/10));
lrfh_sim_config.pkt_gird = ceil(rand(1,lrfh_sim_config.pkt_num)*LRF_cfg.grid_num);%1;
lrfh_sim_config.pkt_channseed = ceil(rand(1,lrfh_sim_config.pkt_num)*1000000);%
lrfh_sim_config.pkt_ntn_delayspread = 10e-9 + 30e-9*rand(1,lrfh_sim_config.pkt_num);
lrfh_sim_config.pkt_start = 0.1*LRF_cfg.samplingrate;
lrfh_sim_config.decode_try_num = 1;    
fprintf(1, 'lrfh sim genterating signal ... ')
[LRFHSS_time_sig_clean,LRFHSS_sim_noise_sig] = lrfh_gen_sig(lrfh_sim_config,LRF_cfg);
fprintf(1, 'done\n');
LRFHSS_time_sig = LRFHSS_time_sig_clean + LRFHSS_sim_noise_sig;
lrfh_sim_result = cell(1,LRF_cfg.decode_try_num);
[HeaderOutput,FoundDataSeg] = lrfh_detect_pkt(1,LRFHSS_time_sig,lrfh_sim_result,LRF_cfg);   
FoundDataSeg = lrfh_decode_found_pkts(FoundDataSeg,LRFHSS_time_sig,LRF_cfg);
