% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

LRF_cfg.region_val_EU = 0;
LRF_cfg.region_val_US = 1;
LRF_cfg.region = LRF_cfg.region_val_EU;

if LRF_cfg.region == LRF_cfg.region_val_EU
    LRF_cfg.pkt_trace_sampling_rate = 500000; % 
    LRF_cfg.pkt_trace_downsampling_factor = 3; % 
    LRF_cfg.allBW = 137000;
elseif LRF_cfg.region == LRF_cfg.region_val_US
    LRF_cfg.pkt_trace_sampling_rate = 2000000; % 
    LRF_cfg.pkt_trace_downsampling_factor = 1; % 
    LRF_cfg.allBW = 1523000;
end

LRF_cfg.decode_try_num = 3;
LRF_cfg.viterbi_use_soft_flag = 1;
LRF_cfg.data_demod_use_interf_erasure_flag = 5; % NOTE: 0: no CAED; 1: old CAED; 5: new CAED

LRF_cfg.use_new_SIC_flag = 1;

LRF_cfg.SYNC_WORD = '00101100000011110111100110010101'-'0';
% NOTE: starts at bit 42 in the header
LRF_cfg.SYNC_phasevals = [0];
for h=2:length(LRF_cfg.SYNC_WORD)
    if LRF_cfg.SYNC_WORD(h) ~= LRF_cfg.SYNC_WORD(h-1)
        LRF_cfg.SYNC_phasevals(h) = LRF_cfg.SYNC_phasevals(h-1);
    else
        if LRF_cfg.SYNC_WORD(h) == 1
            LRF_cfg.SYNC_phasevals(h) = LRF_cfg.SYNC_phasevals(h-1) + pi/2;
        else
            LRF_cfg.SYNC_phasevals(h) = LRF_cfg.SYNC_phasevals(h-1) - pi/2;
        end
    end
end
LRF_cfg.SYNC_vec = exp(1i*LRF_cfg.SYNC_phasevals);

LRF_cfg.pkt_trace_offset = 50000; % 

LRF_cfg.samplingrate = round(LRF_cfg.pkt_trace_sampling_rate/LRF_cfg.pkt_trace_downsampling_factor); % 
LRF_cfg.grid_num = 8;
LRF_cfg.BW = 488;
LRF_cfg.baudrate = 1/LRF_cfg.BW; 
LRF_cfg.smblsmplnum = round(LRF_cfg.samplingrate*LRF_cfg.baudrate); 
LRF_cfg.staytime_data = 0.1024; % sec
LRF_cfg.staytime_hdr = 0.233472; % sec
LRF_cfg.staysmplnum_data = round(LRF_cfg.staytime_data*LRF_cfg.samplingrate); 
LRF_cfg.staysmplnum_hdr = round(LRF_cfg.staytime_hdr*LRF_cfg.samplingrate); 
LRF_cfg.hdr_num = 2;
LRF_cfg.sync_start_bit = 41;
LRF_cfg.hdr_bit_num = 113;
LRF_cfg.lowpassHz = 200; 50*2000000/LRF_cfg.samplingrate;
LRF_cfg.max_freq_drift_Hz = 12000; 

LRF_cfg.demod_soft_val_cap = 1;

LRF_cfg.sync_scan_seconds = 0.05; % NOTE: has been 0.05
LRF_cfg.sync_scan_step = round(LRF_cfg.samplingrate*LRF_cfg.sync_scan_seconds);
LRF_cfg.synccheckpeakrangehalf = ceil((LRF_cfg.allBW+2*LRF_cfg.max_freq_drift_Hz)/LRF_cfg.samplingrate*LRF_cfg.sync_scan_step/2);

LRF_cfg.lookdist = round(LRF_cfg.smblsmplnum/4);
LRF_cfg.demodusenum = 4;

LRF_cfg.DSF = 10;

LRF_cfg.recon_seg_len_symbol_num = 10;

LRF_cfg.tracemargin = round(200*LRF_cfg.samplingrate/2000000); 
LRF_cfg.antnum = 2;
LRF_cfg.maxhdrnum = 3;
LRF_cfg.phasechange = pi/2;
LRF_cfg.phaseslope = LRF_cfg.phasechange/LRF_cfg.smblsmplnum;

LRF_cfg.use_grid_freq_Hz = 100; 
LRF_cfg.use_grid_time_sec = 1/LRF_cfg.BW; 
LRF_cfg.use_grid_time_sampnum = round(LRF_cfg.samplingrate*LRF_cfg.use_grid_time_sec);
LRF_cfg.use_grid_freq_num = ceil(LRF_cfg.allBW*1.65/LRF_cfg.use_grid_freq_Hz); % NOTE: used to be 1.25, to deal with CFO, changed to 1.65 to deal with NTN
tempp = ceil(LRF_cfg.BW/LRF_cfg.use_grid_freq_Hz);
LRF_cfg.use_grid_freq_idx_offset = [0:tempp-1] - floor(tempp/2);
LRF_cfg.coherelensec = 0.001; % channel cohereence len 
LRF_cfg.coheresmpnum = round(LRF_cfg.coherelensec*LRF_cfg.samplingrate);  
LRF_cfg.max_pkt_len_sec = 1.8;
LRF_cfg.finesiglen = ceil(LRF_cfg.smblsmplnum*LRF_cfg.hdr_bit_num*1.02);

lrfh_init_trellis;

LRF_cfg.interf_alarm_thresh = 1.5;
LRF_cfg.adapttofreqdrift_flag = 1;
LRF_cfg.max_SIC_time_off_smpl_num = round(0.1/LRF_cfg.BW*LRF_cfg.samplingrate);

LRF_cfg.chcfg.DelayProfile = 'ETU';
LRF_cfg.chcfg.NRxAnts = LRF_cfg.antnum;
LRF_cfg.chcfg.DopplerFreq = 5; % orig: 5
LRF_cfg.chcfg.MIMOCorrelation = 'Low';
LRF_cfg.chcfg.Seed = 1;
LRF_cfg.chcfg.InitPhase = 'Random';
LRF_cfg.chcfg.ModelType = 'GMEDS';
LRF_cfg.chcfg.NTerms = 16;
LRF_cfg.chcfg.NormalizeTxAnts = 'On';
LRF_cfg.chcfg.NormalizePathGains = 'On';
LRF_cfg.chcfg.SamplingRate = LRF_cfg.samplingrate; 
LRF_cfg.chcfg.InitTime = 0;

LRF_cfg.InterfP = [0.0062 0.0071 0.0084 0.0108 0.0146 0.0206 0.0294 0.0419 0.0589 0.0811 0.1092 0.1436 0.1844 0.2311 0.2834 0.3402 0.4004 0.4626 0.5252 0.5871 0.6465 0.7022 0.7530 0.7981 0.8373 0.8700 0.8963 0.9166 0.9311 0.9402 0.9441 0.9428 0.9365 0.9248 0.9074 0.8842 0.8548 0.8190 0.7770 0.7292 0.6764 0.6195 0.5595 0.4978 0.4356 0.3749 0.3168 0.2626 0.2134 0.1699 0.1322 0.1007 0.0751 0.0549 0.0395 0.0282 0.0202 0.0149 0.0114 0.0092 0.0079];
LRF_cfg.InterfF = [-600:20:600]; 
LRF_cfg.InterfP = LRF_cfg.InterfP/max(LRF_cfg.InterfP);
LRF_cfg.sim_est_noise_P_per_smpl_after_LPF = 0.0014; 
LRF_cfg.SINRcap_val = [5,10]; % DR8, DR9 

p(1) = -1.7223e-05;
p(2) = 0.0042;
p(3) = -0.0042;
hereidx = [1:241];
f = polyval(p,hereidx);
LRF_cfg.wave_1to0 = f;

LRF_cfg.SIREraThresh = 2; % NOTE: outdated
LRF_cfg.CAEDlowerboundSNR = 10; % NOTE: outdated

LRF_cfg.DR89traceidx = [1 500; 501 1000];
LRF_cfg.max_payload_byte_num = 100; 

LRF_cfg.CONST_use_DR8 = 1;
LRF_cfg.CONST_use_DR9 = 2;
LRF_cfg.CONST_use_bothDR = 3;

LRF_cfg.dbg_plot_phase_flag = 0;
LRF_cfg.for_link_test_flag = 0;
LRF_cfg.check_SIC_flag = 1;