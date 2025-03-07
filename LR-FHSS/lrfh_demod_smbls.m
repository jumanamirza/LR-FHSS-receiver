% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function [GMSKbitvals, GMSKmodvaladj_Hz] = lrfh_demod_smbls(smpltime,thischecksig, demodoption, LRF_cfg)

headerphase = angle(thischecksig);
GMSKbitvals = zeros(1,length(smpltime));
if demodoption == 0
    locallookdist = LRF_cfg.lookdist;
    localphaseslope = LRF_cfg.phaseslope;
else
    locallookdist = LRF_cfg.fastlookdist;
    localphaseslope = LRF_cfg.fastphaseslope;
end
for bidx=1:length(smpltime)
    thissmplloc = smpltime(bidx);

    heredist = round(locallookdist*2/(LRF_cfg.demodusenum-1));
    usesamps = thischecksig(:,thissmplloc-locallookdist:heredist:thissmplloc+locallookdist);
    tempp = sum(transpose(usesamps.*conj(usesamps)));
    W = tempp/sum(tempp);

    alldiff = headerphase(:,thissmplloc+locallookdist) - headerphase(:,thissmplloc-locallookdist);
    tempp = find(abs(alldiff) > pi/2);
    alldiff(tempp) = alldiff(tempp) - sign(alldiff(tempp))*2*pi;
    alldiff(find(abs(alldiff)> pi/2)) = 0;
    allk = alldiff/(locallookdist*2);
    
    k = sum(allk.*W');
    GMSKbitvals(bidx) = k/localphaseslope;
end  

tempp0 = prctile(abs(GMSKbitvals),80);
useidx = find(abs(GMSKbitvals)<tempp0);
adjmeasure = zeros(2,2);
for zzz=1:2
    if zzz == 1
        lookidx0 = find(GMSKbitvals < 0);
    else
        lookidx0 = find(GMSKbitvals >= 0);
    end 
    lookidx = intersect(lookidx0,useidx);
    thisval = mean(GMSKbitvals(lookidx));
    if zzz == 1
        adjmeasure(zzz,:) = [length(lookidx)/length(useidx), thisval+1];
    else
        adjmeasure(zzz,:) = [length(lookidx)/length(useidx), thisval-1];
    end
end
GMSKmodvaladj = sum(adjmeasure(:,1).*adjmeasure(:,2));

if LRF_cfg.adapttofreqdrift_flag
    GMSKbitvals = GMSKbitvals - GMSKmodvaladj;
end
% slope adj, slope amount of phase in one symbol time.
GMSKmodvaladj_Hz = GMSKmodvaladj*localphaseslope/2/pi/LRF_cfg.baudrate;

tempp = find(abs(GMSKbitvals)>LRF_cfg.demod_soft_val_cap);
GMSKbitvals(tempp) = sign(GMSKbitvals(tempp))*LRF_cfg.demod_soft_val_cap;