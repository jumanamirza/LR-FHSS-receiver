function [LRFHSS_time_sig_clean,LRFHSS_sim_noise_sig] = lrfh_gen_sig(lrfh_sim_config,LRF_cfg)

if strcmp(lrfh_sim_config.sim_channel, 'AWGN') == 0
    LRFHSS_time_sig_clean = zeros(LRF_cfg.antnum,lrfh_sim_config.siglen);
else
    LRFHSS_time_sig_clean = zeros(1,lrfh_sim_config.siglen);
end

USE_FILE_IDX = lrfh_sim_config.USE_FILE_IDX;
thisfilename = sprintf('../pkttrace/%d', USE_FILE_IDX);
thisfile = fopen(thisfilename); A = fread(thisfile, 'int16'); fclose(thisfile); 
B = A(1:2:end) + 1i*A(2:2:end); A=[]; B=transpose(B); 

maxampval = max(abs(B));
thresh = maxampval/3;
tempp = find(abs(B) > thresh);
useB = B(max(1,tempp(1)-LRF_cfg.tracemargin):min(tempp(end)+LRF_cfg.tracemargin,length(B)));
useB = useB/max(abs(useB));

thisgrid = lrfh_sim_config.pkt_gird;
thisgridfreq_Hz = (thisgrid - 1) * LRF_cfg.BW;
thisgridshiftwave = exp(1i*[0:length(useB)-1]*2*pi/length(useB)*thisgridfreq_Hz*(length(useB)/LRF_cfg.samplingrate));
outp = useB.*thisgridshiftwave;

if strcmp(lrfh_sim_config.sim_channel, 'ETU')
    cpchcfg = LRF_cfg.chcfg; cpchcfg.Seed = lrfh_sim_config.pkt_channseed;
    outp = transpose(lteFadingChannel(cpchcfg, transpose(outp)));        
end
channel_sig_P = sum(sum(outp.*conj(outp)));
outp = outp/sqrt(channel_sig_P/numel(outp));

thisbgn = lrfh_sim_config.pkt_start;
thisend = thisbgn + length(outp) - 1; 
LRFHSS_time_sig_clean(:,thisbgn:thisend) = LRFHSS_time_sig_clean(:,thisbgn:thisend) + outp*lrfh_sim_config.amp;

LRFHSS_sim_noise_sig = (randn(size(LRFHSS_time_sig_clean)) + 1i*randn(size(LRFHSS_time_sig_clean)))/sqrt(2);
    

