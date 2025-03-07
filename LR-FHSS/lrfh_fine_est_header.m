% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function thisHeader = lrfh_fine_est_header(thispktsig,thisHdrCoarseTime,thisHdrCoarseFreqHz, dbg_use_opt_info, LRF_cfg)
    cfo_max = pi;  toffmax = 5; % 
    cfostep = pi/50; Toff_step = LRF_cfg.smblsmplnum/10; % pi/50 in 2 ms, so 5 Hz
    
    cfo_array = [-cfo_max:cfostep:cfo_max]; % NOTE: amount of phase change between two data points
    Toff_bgn = (LRF_cfg.sync_start_bit-toffmax)/LRF_cfg.BW*LRF_cfg.samplingrate; 
    Toff_end = Toff_bgn+toffmax*2/LRF_cfg.BW*LRF_cfg.samplingrate;
    Toff_array = round([Toff_bgn:Toff_step:Toff_end]);    
    
    local_ant_num = size(thispktsig,1);

    thisHeader.startofffset = round(2000*LRF_cfg.samplingrate/2000000);
    thisHeader.CoarseTime = thisHdrCoarseTime;
    thisHeader.CoarseFreqHz = thisHdrCoarseFreqHz;
    thisHeader.shouldkeepflag = 1;

    if isempty(dbg_use_opt_info)
    else
        thisHdrCoarseTime = [dbg_use_opt_info.start, dbg_use_opt_info.start+LRF_cfg.finesiglen-1];
        thisHdrCoarseFreqHz = dbg_use_opt_info.foundfreq;
    end
    thischecksig_0 = thispktsig(:,thisHdrCoarseTime(1):thisHdrCoarseTime(2));
    thischecksig = lrfh_lpfsig(thischecksig_0,thisHdrCoarseFreqHz,0,LRF_cfg); 
    syncsampleoffset = round([0:length(LRF_cfg.SYNC_WORD)-1]/LRF_cfg.BW*LRF_cfg.samplingrate);

    scanvals0 = zeros(length(Toff_array),length(LRF_cfg.SYNC_WORD));
    for tidx=1:length(Toff_array)
        thisbgn = Toff_array(tidx);
        for ant=1:local_ant_num
            thissamples = thischecksig(ant,thisbgn+syncsampleoffset);
            tempp = fft(thissamples./LRF_cfg.SYNC_vec);
            scanvals0(tidx,:) = scanvals0(tidx,:) + tempp.*conj(tempp);
        end
    end
    maxsyncval0 = max(max(scanvals0));
    [toptidx,topfidx] = find(scanvals0==maxsyncval0);
    if min(scanvals0(:,topfidx)) > max(scanvals0(:,topfidx))*0.25
        thisHeader.shouldkeepflag = 0;
    else
        scanvals = zeros(length(Toff_array),length(cfo_array));
        
        tlookout = 4;
        trange =[max(1,toptidx-tlookout):min(toptidx+tlookout,length(Toff_array))];
        topfidx_adj = topfidx - 1;
        if topfidx_adj > length(LRF_cfg.SYNC_WORD)/2
            topfidx_adj = topfidx_adj - length(LRF_cfg.SYNC_WORD);
        end
        topfidx_adj = -topfidx_adj;
        flookout = 1;
        herefmin = max((topfidx_adj-flookout)*2*pi/length(LRF_cfg.SYNC_WORD),cfo_array(1));
        herefmax = min((topfidx_adj+flookout)*2*pi/length(LRF_cfg.SYNC_WORD),cfo_array(end));
        tempp1 = abs(cfo_array-herefmin); [t,a1] = min(tempp1); 
        tempp2 = abs(cfo_array-herefmax); [t,a2] = min(tempp2); 
        frange =[a1:a2];
        for tidx=1:length(trange)
            thisbgn = Toff_array(trange(tidx));
            for ant=1:local_ant_num
                thissamples = thischecksig(ant,thisbgn+syncsampleoffset);
                for cidx=1:length(frange)
                    thiscfo = cfo_array(frange(cidx));
                    thisadjwave = exp(1i*[0:length(LRF_cfg.SYNC_WORD)-1]*thiscfo);
                    tempp = thissamples.*thisadjwave./LRF_cfg.SYNC_vec;
                    scanvals(trange(tidx),frange(cidx)) = scanvals(trange(tidx),frange(cidx)) + abs(sum(tempp))*abs(sum(tempp));
                end
            end
        end
    
        maxsyncval = max(max(scanvals));
        [optidx,opcidx] = find(scanvals==maxsyncval);
        op_sig_bgn = Toff_array(optidx) - round(LRF_cfg.sync_start_bit/LRF_cfg.BW*LRF_cfg.samplingrate) + thisHdrCoarseTime(1); 
        op_cfo = cfo_array(opcidx)/LRF_cfg.smblsmplnum; 
        thisHeader.start = max(op_sig_bgn,thisHeader.startofffset+1); % NOTE: this is the start of the segment
        thiscfo_Hz = -(op_cfo*LRF_cfg.finesiglen/(2*pi))/(LRF_cfg.finesiglen/LRF_cfg.samplingrate);
        thisHeader.cfo = thiscfo_Hz; % NOTE: this is the CFO after the coarse correction
        thisHeader.foundfreq = thisHdrCoarseFreqHz + thiscfo_Hz;    
        thisHeader.maxsyncval = maxsyncval;
    
        tempp = round(([0:LRF_cfg.hdr_bit_num-1]/LRF_cfg.BW)*LRF_cfg.samplingrate);
        thisHeader.smpltime = thisHeader.startofffset + tempp;
    end