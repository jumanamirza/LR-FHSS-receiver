% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

lrfh_init;

lrfh_sim_config.gen_trace_flag = 1;
lrfh_sim_config.use_ursp_flag  = 0;

if lrfh_sim_config.use_ursp_flag == 1
    lrfh_sim_config.gen_trace_flag = 0;
end
lrfh_sim_config.decode_try_num = LRF_cfg.decode_try_num;

if lrfh_sim_config.gen_trace_flag 
    
    % --------- sim config main bgn ---------------------------------------
    if lrfh_USE_WRAPPER == 0
        lrfh_sim_config.drsel = LRF_cfg.CONST_use_DR8; % NOTE: 1: DR8, 2, DR9, 3, bothDR
        lrfh_sim_config.pkt_num = 2;
        lrfh_sim_config.base_SNR_dB = -17; 
        lrfh_sim_config.PDiff_dB = 20;
        lrfh_sim_config.sim_channel = 'ETU'; % 'AWGN' 'ETU'
        lrfh_sim_config.siglensec = 10;  
        lrfh_sim_config.run_detection_flag = 1; % NOTE: 0: ideal; 1 run it, 
    end
    % --------- sim config main end ---------------------------------------
 
    if lrfh_sim_config.drsel == LRF_cfg.CONST_use_DR8
        herenum = [lrfh_sim_config.pkt_num 0];
    elseif lrfh_sim_config.drsel == LRF_cfg.CONST_use_DR9
        herenum = [0 lrfh_sim_config.pkt_num];
    else
        tempp = round(lrfh_sim_config.pkt_num/2);
        herenum = [tempp lrfh_sim_config.pkt_num-tempp];
    end
    lrfh_sim_config.USE_FILE_IDX_array = [];
    for dridx=1:2
        thisnum = herenum(dridx);
        hererange = diff(LRF_cfg.DR89traceidx(dridx,:))+1;
        addedidx = [];
        if thisnum > 0
            while length(addedidx) < thisnum
                tempp = randperm(hererange);
                herepicknum = min(thisnum-length(addedidx),hererange);
                tempp1 = tempp(1:herepicknum) + LRF_cfg.DR89traceidx(dridx,1) - 1;
                addedidx = [addedidx, tempp1];
            end
        end
        lrfh_sim_config.USE_FILE_IDX_array = [lrfh_sim_config.USE_FILE_IDX_array addedidx];
    end

    lrfh_sim_config.siglen = lrfh_sim_config.siglensec * LRF_cfg.samplingrate;  
    lrfh_sim_config.SNR_dB = rand(1,lrfh_sim_config.pkt_num)*lrfh_sim_config.PDiff_dB + lrfh_sim_config.base_SNR_dB;
    if lrfh_sim_config.drsel == LRF_cfg.CONST_use_bothDR
        tempp = find(lrfh_sim_config.USE_FILE_IDX_array > 500); 
        lrfh_sim_config.SNR_dB(tempp) = lrfh_sim_config.SNR_dB(tempp) + 4; % DR9 with more dB
    end
    lrfh_sim_config.pkt_start = ceil(sort(rand(1,lrfh_sim_config.pkt_num))*(lrfh_sim_config.siglen-LRF_cfg.max_pkt_len_sec*LRF_cfg.samplingrate)); % NOTE: assume pkt is no longer than 0.2 of the sim time
    lrfh_sim_config.pkt_gird = ceil(rand(1,lrfh_sim_config.pkt_num)*LRF_cfg.grid_num);
    lrfh_sim_config.addpktcfo_Hz = zeros(1,lrfh_sim_config.pkt_num);

    tempp = lrfh_sim_config.SNR_dB + 10*log10((LRF_cfg.allBW / LRF_cfg.samplingrate));
    lrfh_sim_config.amp = sqrt(power(10, tempp/10));
    lrfh_sim_config.pkt_channseed = ceil(rand(1,lrfh_sim_config.pkt_num)*1000000);
    lrfh_sim_config.pkt_ntn_delayspread = 10e-9 + 30e-9*rand(1,lrfh_sim_config.pkt_num);
    
    [LRFHSS_time_sig_clean,LRFHSS_sim_noise_sig,LRFHSS_sim_sig_tx_count,LRFHSS_time_sig_sep_clean] = lrfh_gen_sig(lrfh_sim_config,LRF_cfg);
end
if lrfh_sim_config.use_ursp_flag
    thisfilename = 'your file name';
    fprintf(1, 'reading %s\n', thisfilename);
    thisfile = fopen(thisfilename,'r');
    a = fread(thisfile, 'int16'); % or 'float'
    fclose(thisfile);
    LRFHSS_time_sig_clean = transpose(a(1:2:end) + 1i*a(2:2:end));
    clear a;
    LRFHSS_sim_noise_sig = zeros(size(LRFHSS_time_sig_clean));

    lrfh_sim_config.run_detection_flag = 1; % NOTE: 0: ideal; 1 run it, 
    lrfh_sim_config.drsel = LRF_cfg.CONST_use_DR9; % NOTE: 1: DR8, 2, DR9, 3, bothDR
    lrfh_sim_config.siglen = size(LRFHSS_time_sig_clean,2);  
end
LRFHSS_time_sig = LRFHSS_time_sig_clean + LRFHSS_sim_noise_sig;

if lrfh_sim_config.use_ursp_flag == 0
    if lrfh_sim_config.pkt_num == 1
        lrfh_sim_config.decode_try_num = 1;
    end
end
if lrfh_sim_config.use_ursp_flag == 0
    FoundDataSeg = lrfh_use_ideal_pkt_info(lrfh_sim_config, ALL_PKT_INFO, LRF_cfg);
    idealFoundDataSeg = FoundDataSeg;
else
    idealFoundDataSeg = [];
end
lrfh_sim_result = cell(1,LRF_cfg.decode_try_num);
for lrfh_sim_decode_try_count=1:lrfh_sim_config.decode_try_num
    if lrfh_sim_config.run_detection_flag == 1
        [HeaderOutput,FoundDataSeg] = lrfh_detect_pkt(lrfh_sim_decode_try_count,LRFHSS_time_sig,lrfh_sim_result,LRF_cfg);
        lrfh_print_detected_pkt_info(idealFoundDataSeg,FoundDataSeg,lrfh_sim_config);     
    else
        todolist = [];
        for pktidx=1:length(FoundDataSeg)
            if FoundDataSeg{pktidx}.CRCpass == 0
                todolist{length(todolist)+1} = FoundDataSeg{pktidx};
            end
        end
        FoundDataSeg = todolist;
    end
    [FoundSigGird, FoundDataSeg] = lrfh_get_overlapinfo(FoundDataSeg,floor(size(LRFHSS_time_sig,2)/LRF_cfg.use_grid_time_sampnum),LRF_cfg);
    [FoundDataSeg, LRFHSS_recon_time_sig] = lrfh_decode_found_pkts(FoundDataSeg,LRFHSS_time_sig,LRF_cfg);
    LRFHSS_time_sig = LRFHSS_time_sig - LRFHSS_recon_time_sig;     
    lrfh_sim_result{lrfh_sim_decode_try_count} = FoundDataSeg;
end
[sta_decoded_flag, drinfo] = lrfh_print_decoded_pkt_info(idealFoundDataSeg, lrfh_sim_result, lrfh_sim_config);