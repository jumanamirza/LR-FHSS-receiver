
LRF_cfg.decode_try_num = 1;
LRF_cfg.viterbi_use_soft_flag = 1;

LRF_cfg.SYNC_WORD = '00101100000011110111100110010101'-'0';
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

LRF_cfg.samplingrate = 500000; % 
LRF_cfg.allBW = 137000;
LRF_cfg.grid_num = 8;
LRF_cfg.BW = 488;
LRF_cfg.baudrate = 1/LRF_cfg.BW; 
LRF_cfg.smblsmplnum = round(LRF_cfg.samplingrate*LRF_cfg.baudrate); 
LRF_cfg.staytime_data = 0.1024; % sec
LRF_cfg.staytime_hdr = 0.233472; % sec
LRF_cfg.staysmplnum_data = LRF_cfg.staytime_data*LRF_cfg.samplingrate; 
LRF_cfg.staysmplnum_hdr = LRF_cfg.staytime_hdr*LRF_cfg.samplingrate; 
LRF_cfg.hdr_num = 2;
LRF_cfg.sync_start_bit = 41;
LRF_cfg.hdr_bit_num = 113;
LRF_cfg.lowpassHz = 50*2000000/LRF_cfg.samplingrate;

LRF_cfg.DSF = 10;

LRF_cfg.sync_scan_seconds = 0.05;
LRF_cfg.sync_scan_step = round(LRF_cfg.samplingrate*LRF_cfg.sync_scan_seconds);
LRF_cfg.lookdist = round(LRF_cfg.smblsmplnum/4);

LRF_cfg.tracemargin = round(200*LRF_cfg.samplingrate/2000000); 
LRF_cfg.antnum = 2;
LRF_cfg.maxhdrnum = 3;
LRF_cfg.phasechange = pi/2;
LRF_cfg.phaseslope = LRF_cfg.phasechange/LRF_cfg.smblsmplnum;

LRF_cfg.use_grid_freq_Hz = 100; 
LRF_cfg.use_grid_time_sec = 1/LRF_cfg.BW; 
LRF_cfg.use_grid_time_sampnum = round(LRF_cfg.samplingrate*LRF_cfg.use_grid_time_sec);
LRF_cfg.use_grid_freq_num = ceil(LRF_cfg.allBW*1.25/LRF_cfg.use_grid_freq_Hz); % 1.25 to deal with CFO
tempp = ceil(LRF_cfg.BW/LRF_cfg.use_grid_freq_Hz);
LRF_cfg.use_grid_freq_idx_offset = [0:tempp-1] - floor(tempp/2);
LRF_cfg.coherelensec = 0.001; % channel cohereence len 
LRF_cfg.coheresmpnum = round(LRF_cfg.coherelensec*LRF_cfg.samplingrate);  
LRF_cfg.max_pkt_len_sec = 1.8;
LRF_cfg.finesiglen = ceil(LRF_cfg.smblsmplnum*LRF_cfg.hdr_bit_num*1.02);

lrfh_init_trellis;

LRF_cfg.CONST_use_DR8 = 1;
LRF_cfg.CONST_use_DR9 = 2;
LRF_cfg.CONST_use_bothDR = 3;


LRF_cfg.chcfg.DelayProfile = 'ETU';
LRF_cfg.chcfg.NRxAnts = LRF_cfg.antnum;
LRF_cfg.chcfg.DopplerFreq = 5; 
LRF_cfg.chcfg.MIMOCorrelation = 'Low';
LRF_cfg.chcfg.Seed = 1;
LRF_cfg.chcfg.InitPhase = 'Random';
LRF_cfg.chcfg.ModelType = 'GMEDS';
LRF_cfg.chcfg.NTerms = 16;
LRF_cfg.chcfg.NormalizeTxAnts = 'On';
LRF_cfg.chcfg.NormalizePathGains = 'On';
LRF_cfg.chcfg.SamplingRate = LRF_cfg.samplingrate; 
LRF_cfg.chcfg.InitTime = 0;

LRF_cfg.demodusenum = 4;