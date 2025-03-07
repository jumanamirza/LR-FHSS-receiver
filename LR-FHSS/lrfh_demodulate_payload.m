% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function [thisdataseg, GMSKmodvaladj] = lrfh_demodulate_payload(thispktsig,thisDataSegTime,thisDataSegFreqHz,LRF_cfg,maxbitnum, overlapinfo, estpower, CR_de)
    local_ant_num = size(thispktsig,1);
    thischecksig_0 = thispktsig(:,thisDataSegTime(1):thisDataSegTime(2));
    thischecksig = lrfh_lpfsig(thischecksig_0,thisDataSegFreqHz,0,LRF_cfg);
    thisdataseg.start = LRF_cfg.lookdist+1;
    tempp = round(([0:maxbitnum-1]/LRF_cfg.BW)*LRF_cfg.samplingrate);
    thisdataseg.smpltime = thisdataseg.start + tempp;

    [GMSKbitvals, GMSKmodvaladj] = lrfh_demod_smbls(thisdataseg.smpltime,thischecksig,0,LRF_cfg);  

    if LRF_cfg.data_demod_use_interf_erasure_flag == 1
        tempp = sum(overlapinfo.interf_flag_mat'); % NOTE: any freq has some overlap is a read flag
        tempp1 = find(tempp);
        tempp1(tempp1 > length(GMSKbitvals)) = [];
        GMSKbitvals(tempp1) = 0;
    elseif LRF_cfg.data_demod_use_interf_erasure_flag == 5 
        % NOTE: packet power estimated with SYNC_WORD coherently. So, have
        % to divide by the length to remove the coherency effect. Have to
        % to divide by the length again to get to the power per sample
        hereadjratio = ones(1, length(GMSKbitvals)); 
        estpower_per_smpl = estpower/length(LRF_cfg.SYNC_vec)/length(LRF_cfg.SYNC_vec)/LRF_cfg.antnum;
        estnoisep = ones(1,length(GMSKbitvals))*LRF_cfg.sim_est_noise_P_per_smpl_after_LPF;
        estsigp = estpower_per_smpl*ones(1,length(GMSKbitvals));
        estinterfp = overlapinfo.invSIR(1:length(GMSKbitvals))*estpower_per_smpl;
        estSNR = estsigp./estnoisep;
        estSINR = estsigp./(estnoisep + estinterfp);
        if CR_de == 3
            thisthresh = LRF_cfg.SINRcap_val(1);
        else
            thisthresh = LRF_cfg.SINRcap_val(2);
        end 
        needtochangeidx = find(estSINR < thisthresh);
        if length(needtochangeidx)
            estSNR(needtochangeidx) = min(thisthresh, estSNR(needtochangeidx));
            hereadjratio(needtochangeidx) = estSINR(needtochangeidx)./estSNR(needtochangeidx);
        end
        GMSKbitvals = GMSKbitvals.*hereadjratio;
    end
    thisdataseg.bits = GMSKbitvals;