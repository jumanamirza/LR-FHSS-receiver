function thisdataseg = lrfh_demodulate_payload(thispktsig,thisDataSegTime,thisDataSegFreqHz,LRF_cfg,maxbitnum)
    local_ant_num = size(thispktsig,1);
    thischecksig_0 = thispktsig(:,thisDataSegTime(1):thisDataSegTime(2));
    thischecksig = lrfh_lpfsig(thischecksig_0,thisDataSegFreqHz,LRF_cfg);
    thisdataseg.start = LRF_cfg.lookdist+1;
    thisdataseg.smpltime = thisdataseg.start + [0:maxbitnum-1]*LRF_cfg.smblsmplnum;
    GMSKbitvals = lrfh_demod_smbls(thisdataseg.smpltime,thischecksig,LRF_cfg);   
    thisdataseg.bits = GMSKbitvals;
    