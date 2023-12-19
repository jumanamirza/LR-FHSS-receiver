function outsig = lrfh_lpfsig(insig,freqinHz,LRF_cfg)
    thisnumcycles = freqinHz*(size(insig,2)/LRF_cfg.samplingrate);
    thiswave = repmat(exp(1i*[0:size(insig,2)-1]*2*pi/size(insig,2)*thisnumcycles),size(insig,1),1);
    insig_dcvt = insig ./ thiswave;
    outsig = zeros(size(insig_dcvt));
    % tic
    for ant=1:size(insig,1)  
        outsig(ant,:) = filtfilt(LRF_cfg.iir,insig_dcvt(ant,:)); 
    end
    % toc
end

