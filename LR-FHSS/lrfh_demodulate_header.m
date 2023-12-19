function thisHeader = lrfh_demodulate_header(thispktsig,thisHdrCoarseTime,thisHdrCoarseFreqHz, dbg_use_opt_info, LRF_cfg)
    local_ant_num = size(thispktsig,1);
    herestartofffset = round(2000*LRF_cfg.samplingrate/2000000);
    thisHeader.CoarseTime = thisHdrCoarseTime;
    thisHeader.CoarseFreqHz = thisHdrCoarseFreqHz;
    if isempty(dbg_use_opt_info)
    else
        thisHdrCoarseTime = [dbg_use_opt_info.start, dbg_use_opt_info.start+LRF_cfg.finesiglen-1];
        thisHdrCoarseFreqHz = dbg_use_opt_info.foundfreq;
    end
    thischecksig_0 = thispktsig(:,thisHdrCoarseTime(1):thisHdrCoarseTime(2));
    thischecksig = lrfh_lpfsig(thischecksig_0,thisHdrCoarseFreqHz,LRF_cfg);
    
    cfo_max = pi/2;  toffmax = 5; 
    cfostep = pi/50; Toff_step = LRF_cfg.smblsmplnum/10; % pi/50 in 2 ms, so 5 Hz
    % NOTE: cfostep = pi/50 means that in one symbol phases changes by
    % pi/50. given that the symbol is aboiut 2 ms, it is 5 Hz 
    cfo_array = [-cfo_max:cfostep:cfo_max]; % NOTE: amount of phase change between two data points
    Toff_bgn = (LRF_cfg.sync_start_bit-toffmax)*LRF_cfg.smblsmplnum; 
    Toff_end = (LRF_cfg.sync_start_bit+toffmax)*LRF_cfg.smblsmplnum;
    Toff_array = round([Toff_bgn:Toff_step:Toff_end]);    
    scanvals = zeros(length(Toff_array),length(cfo_array));
    for tidx=1:length(Toff_array)
        thisbgn = Toff_array(tidx);
        thisend = thisbgn + LRF_cfg.smblsmplnum*length(LRF_cfg.SYNC_WORD)-1;
        for ant=1:local_ant_num
            thissamples = thischecksig(ant,thisbgn:LRF_cfg.smblsmplnum:thisend);
            for cidx=1:length(cfo_array)
                thiscfo = cfo_array(cidx);
                thisadjwave = exp(1i*[0:length(LRF_cfg.SYNC_WORD)-1]*thiscfo);
                tempp = thissamples.*thisadjwave./LRF_cfg.SYNC_vec;
                scanvals(tidx,cidx) = scanvals(tidx,cidx) + abs(sum(tempp))*abs(sum(tempp));
            end
        end
    end
    maxsyncval = max(max(scanvals));
    [optidx,opcidx] = find(scanvals==maxsyncval);
    op_sig_bgn = Toff_array(optidx) - LRF_cfg.sync_start_bit*LRF_cfg.smblsmplnum + thisHdrCoarseTime(1); 
    op_cfo = cfo_array(opcidx)/LRF_cfg.smblsmplnum; 
    thisHeader.start = max(op_sig_bgn,herestartofffset+1); % NOTE: this is the start of the segment
    thiscfo_Hz = -(op_cfo*LRF_cfg.finesiglen/(2*pi))/(LRF_cfg.finesiglen/LRF_cfg.samplingrate);
    thisHeader.cfo = thiscfo_Hz; % NOTE: this is the CFO after the coarse correction
    thisHeader.foundfreq = thisHdrCoarseFreqHz + thiscfo_Hz;    
    thisHeader.maxsyncval = maxsyncval;
    
    thischecksig_0 = thispktsig(:,thisHeader.start-herestartofffset:thisHeader.start+size(thischecksig_0,2)-herestartofffset-1);
    thischecksig = lrfh_lpfsig(thischecksig_0,thisHeader.foundfreq,LRF_cfg);
    thisHeader.smpltime = herestartofffset + [0:LRF_cfg.hdr_bit_num-1]*LRF_cfg.smblsmplnum;

    GMSKbitvals = lrfh_demod_smbls(thisHeader.smpltime,thischecksig,LRF_cfg);  
    thisHeader.bits = GMSKbitvals;

