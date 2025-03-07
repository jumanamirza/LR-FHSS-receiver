% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function [LRFHSS_time_sig_clean,LRFHSS_sim_noise_sig, LRFHSS_sim_sig_tx_count, LRFHSS_time_sig_sep_clean] = lrfh_gen_sig(lrfh_sim_config,LRF_cfg)

if strcmp(lrfh_sim_config.sim_channel, 'AWGN') == 0
    LRFHSS_time_sig_clean = zeros(LRF_cfg.antnum,lrfh_sim_config.siglen);
else
    LRFHSS_time_sig_clean = zeros(1,lrfh_sim_config.siglen);
end
LRFHSS_sim_sig_tx_count = zeros(1,lrfh_sim_config.siglen);
LRFHSS_time_sig_sep_clean = [];
local_save_sig_flag = (length(lrfh_sim_config.USE_FILE_IDX_array) <=2) && LRF_cfg.check_SIC_flag;

local_print_flag = 1;
if local_print_flag
    fprintf(1, 'lrfh sim genterating signal: ')
    for h=1:20 fprintf(1, ' '); end
end
for useidx=1:length(lrfh_sim_config.USE_FILE_IDX_array)
    USE_FILE_IDX = lrfh_sim_config.USE_FILE_IDX_array(useidx);

    if local_print_flag
        for h=1:20 fprintf(1, '\b'); end
        fprintf(1, 'pkt %4d, trace %4d', useidx, USE_FILE_IDX);
    end    
    thisfilename = sprintf('../pkttrace/%d', USE_FILE_IDX);
    thisfile = fopen(thisfilename); A = fread(thisfile, 'int16'); fclose(thisfile); 
    B = A(1:2:end) + 1i*A(2:2:end); A=[]; B=transpose(B); 

    % NOTE: have to keep this selection code because pkt info was obtained with this 
    maxampval = max(abs(B));
    thresh = maxampval/3; % NOTE: the SNR has to be 20 dB or more to be safe! 
    tempp = find(abs(B) > thresh);
    useB = B(max(1,tempp(1)-LRF_cfg.tracemargin):min(tempp(end)+LRF_cfg.tracemargin,length(B)));
    
    useB = useB/max(abs(useB));
    useB = useB(1:LRF_cfg.pkt_trace_downsampling_factor:end);

    thisgrid = lrfh_sim_config.pkt_gird(useidx);
    thisgridfreq_Hz = (thisgrid - 1) * LRF_cfg.BW;
    thisaddcfoHz = lrfh_sim_config.addpktcfo_Hz(useidx);
    thisfreqshiftwave = exp(1i*[0:length(useB)-1]*2*pi/length(useB)*(thisgridfreq_Hz+thisaddcfoHz)*(length(useB)/LRF_cfg.samplingrate));
    outp = useB.*thisfreqshiftwave;
    
    if strcmp(lrfh_sim_config.sim_channel, 'ETU')
        cpchcfg = LRF_cfg.chcfg; cpchcfg.Seed = lrfh_sim_config.pkt_channseed(useidx);
        outp = transpose(lteFadingChannel(cpchcfg, transpose(outp))); 
    end
    channel_sig_P = sum(sum(outp.*conj(outp)));
    outp = outp/sqrt(channel_sig_P/numel(outp));

    thisbgn = lrfh_sim_config.pkt_start(useidx);
    thisend = thisbgn + length(outp) - 1; 
    thissig = outp*lrfh_sim_config.amp(useidx);
    if local_save_sig_flag
        LRFHSS_time_sig_sep_clean{useidx} = zeros(size(LRFHSS_time_sig_clean));
        LRFHSS_time_sig_sep_clean{useidx}(:,thisbgn:thisend) = thissig;
    end
    LRFHSS_time_sig_clean(:,thisbgn:thisend) = LRFHSS_time_sig_clean(:,thisbgn:thisend) + thissig;
    LRFHSS_sim_sig_tx_count(thisbgn:thisend) = LRFHSS_sim_sig_tx_count(thisbgn:thisend) + 1;
end
LRFHSS_sim_noise_sig = (randn(size(LRFHSS_time_sig_clean)) + 1i*randn(size(LRFHSS_time_sig_clean)))/sqrt(2);
if local_print_flag
    fprintf(1, '\n'); 
end