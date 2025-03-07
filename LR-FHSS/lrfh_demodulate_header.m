% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function [bits, GMSKmodvaladj] = lrfh_demodulate_header(thispktsig,thisHeader,LRF_cfg)

    if thisHeader.shouldkeepflag 
        local_osf = 1; 
        local_offset = 0;
        local_smaple_time = thisHeader.smpltime;
        local_len = thisHeader.CoarseTime(2) - thisHeader.CoarseTime(1) + 1;
        thischecksig_0 = thispktsig(:,thisHeader.start-thisHeader.startofffset+local_offset:local_osf:thisHeader.start+local_len-thisHeader.startofffset-1+local_offset);
        thischecksig = lrfh_lpfsig(thischecksig_0,thisHeader.foundfreq,0,LRF_cfg);
        [bits, GMSKmodvaladj] = lrfh_demod_smbls(local_smaple_time,thischecksig,0,LRF_cfg);  
    else
        bits = zeros(1,LRF_cfg.hdr_bit_num);
        GMSKmodvaladj = 0;
    end