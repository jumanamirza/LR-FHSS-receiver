% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function modsig0 = lrfh_gen_ideal_waveform(data,LRF_cfg)

phasesmbl = [0:LRF_cfg.smblsmplnum-1]*LRF_cfg.phasechange/LRF_cfg.smblsmplnum;
modsig0len = round(length(data)/LRF_cfg.BW*LRF_cfg.samplingrate); 
modsig0smblmid = round([0.5:1:length(data)]/LRF_cfg.BW*LRF_cfg.samplingrate);
modsig0 = zeros(1,modsig0len);
for h=1:length(data)
    if data(h)==0
        thissmbl = -phasesmbl;
    else
        thissmbl = phasesmbl;
    end
    thisbgn = round(modsig0smblmid(h)-LRF_cfg.smblsmplnum/2+1);
    thisend = thisbgn + LRF_cfg.smblsmplnum - 1;
    if h == 1
        initphase = 0;
    else
        initphase = modsig0(thisbgn-1);
    end
    modsig0(thisbgn:thisend) = thissmbl + initphase;  
end
for h=3:length(data)-2
    if data(h-1) ~= data(h) 
        if data(h-1) == 1
            thistransit = LRF_cfg.wave_1to0;
        else
            thistransit = -LRF_cfg.wave_1to0;
        end
        thiscenterloc = round(mean(modsig0smblmid(h-1:h)));
        thisstart = thiscenterloc - floor(length(thistransit)/2);
        modsig0(thisstart:thisstart+length(thistransit)-1) = modsig0(thisstart) + thistransit;
    end
end
tempp = find(modsig0 == 0); tempp(tempp==1) = [];
modsig0(tempp) = modsig0(tempp-1);
