function GMSKbitvals = lrfh_demod_smbls(smpltime,thischecksig,LRF_cfg)
headerphase = angle(thischecksig);
GMSKbitvals = [];
for bidx=1:length(smpltime)
    thissmplloc = smpltime(bidx);
    thisidx = [thissmplloc-LRF_cfg.lookdist:thissmplloc+LRF_cfg.lookdist];
    thissig = thischecksig(:,thisidx);
    
    heredist = floor(size(thissig,2)/(LRF_cfg.demodusenum-1));
    usesamps = thissig(:,1:heredist:end);
    tempp = sum(transpose(usesamps.*conj(usesamps)));
    W = tempp/sum(tempp);

    alldiff_0 = headerphase(:,thissmplloc+LRF_cfg.lookdist) - headerphase(:,thissmplloc-LRF_cfg.lookdist);
    alldiff = alldiff_0;
    for ant=1:size(thischecksig,1)
        if abs(alldiff(ant)) > pi/2
            alldiff(ant) = alldiff(ant) - sign(alldiff(ant))*2*pi;
        end
    end
    alldiff(find(abs(alldiff)> pi/2)) = 0;
    allk = alldiff/length(thisidx);
    
    k = sum(allk.*W');
    GMSKbitvals(bidx) = k/LRF_cfg.phaseslope;
end

caphere = 1.25;
tempp = find(abs(GMSKbitvals)>caphere);
GMSKbitvals(tempp) = sign(GMSKbitvals(tempp))*caphere;

