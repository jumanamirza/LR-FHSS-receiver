% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function outsig = lrfh_lpfsig(insig, freqinHz, filtoption, LRF_cfg)
    if filtoption == 0
        local_sampling_rate = LRF_cfg.samplingrate;
    else
        local_sampling_rate = LRF_cfg.fastsamplingrate;
    end
    thisnumcycles = freqinHz*(size(insig,2)/local_sampling_rate);
    thiswave = repmat(exp(1i*[0:size(insig,2)-1]*2*pi/size(insig,2)*thisnumcycles),size(insig,1),1);
    insig_dcvt = insig ./ thiswave;
    outsig = zeros(size(insig_dcvt));
    filterchoice = 1;
    % tic
    for ant=1:size(insig,1)
        if filterchoice == 1
            if filtoption == 0
                outsig(ant,:) = filtfilt(LRF_cfg.iir,insig_dcvt(ant,:));
            else
                outsig(ant,:) = filtfilt(LRF_cfg.fast_iir,insig_dcvt(ant,:));
            end
        elseif filterchoice == 2
            outsig(ant,:) = lowpass(insig_dcvt(ant,:), LRF_cfg.lowpassHz, LRF_cfg.samplingrate, ...
                'ImpulseResponse','iir','StopbandAttenuation', 100, 'Steepness', 0.9); 
        elseif filterchoice == 4
            % inaccurate at low snr, faster 
            herehalflen = ceil(length(LRF_cfg.fir)/2);
            tempp0 = insig_dcvt(ant,1:LRF_cfg.DSF:end);
            tempp1 = [tempp0, tempp0(1:herehalflen)];
            tempp2 = filter(LRF_cfg.fir,1,tempp1);
            dsamplfsig = tempp2(herehalflen:herehalflen+length(tempp0)-1);
            tempplfexp = CPMA_interp(dsamplfsig, LRF_cfg.DSF);
            outsig(ant,1:length(tempplfexp)) = tempplfexp;
        end
    end
    % toc
end

