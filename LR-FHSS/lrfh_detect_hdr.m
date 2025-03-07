% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function [SegCoarseTime, SegCoarseFreqHz, SegCoarseScore] = lrfh_detect_hdr(LRFHSS_time_sig,LRF_cfg)

    SegCoarseTime = []; SegCoarseFreqHz = []; SegCoarseScore = [];

    local_print_flag = 1;
    if local_print_flag
        fprintf(1, 'lrfh sim detecting header ...\n')
    end

    % 0. set up
    zvl_sync_peak_thresh_coef = 2; % NOTE: has been 2
    zvl_peak_num_take_max = 100; 
    T = LRF_cfg.sync_scan_step;
    scannsamechanwidth = ceil(LRF_cfg.BW * LRF_cfg.sync_scan_step / LRF_cfg.samplingrate); % NOTE: better be an odd number
    maxpeakconsecutivenum = ceil(LRF_cfg.staytime_hdr*LRF_cfg.samplingrate/T);
    threshpeakconsecutivenum = maxpeakconsecutivenum - 1;
    zvl_fdsigspan_coarse = round(LRF_cfg.BW*0.5*LRF_cfg.sync_scan_seconds); % NOTE: the peak loc does not drift more than 244 Hz
    zvl_fdsigspan_fine = round(LRF_cfg.BW*LRF_cfg.staytime_hdr);
    usewindow = gausswin(scannsamechanwidth);
    usewindow_half = round((scannsamechanwidth-1)/2);
    finescanstep = LRF_cfg.smblsmplnum;
    finesiglen = LRF_cfg.finesiglen;
    local_ant_num = size(LRFHSS_time_sig,1);
    tempp = LRF_cfg.synccheckpeakrangehalf;
    local_check_sync_idx = [T-tempp:T,1:tempp];
    local_check_sync_exclude_idx = setdiff([1:T],local_check_sync_idx);

    % 1. computing the segment FFTs
    sync_sigvec_flat = zeros(1,floor(size(LRFHSS_time_sig,2)/T)*T);
    thisbgn = 1;
    while thisbgn < size(LRFHSS_time_sig,2) - T
        thisend = thisbgn + T - 1;
        sync_sigvec_flat(thisbgn:thisend) = lrfh_cal_fft_squared(LRFHSS_time_sig(:,thisbgn:thisend));
        thisbgn = thisbgn + T;
    end
    sync_sigvec = reshape(sync_sigvec_flat, T, length(sync_sigvec_flat)/T)';
    dbg_save_sync_sigvec = sync_sigvec;
    for h=1:size(sync_sigvec,1)
        tempp = [sync_sigvec(h,:), sync_sigvec(h,1:usewindow_half)];
        tempp1 = filter(usewindow,1,tempp);
        sync_sigvec(h,:) = tempp1(usewindow_half+1:end);
        sync_sigvec(h,local_check_sync_exclude_idx) = 0;
    end
    sync_rcd = cell(1,size(sync_sigvec,1));
    for h=1:length(sync_rcd)
        [a,b] = peakfinder(sync_sigvec(h,:), median(sync_sigvec(h,local_check_sync_idx))*zvl_sync_peak_thresh_coef);
        if length(a)
            [tempp,bb] = sort(b, 'descend'); aa = a(bb);
            takenum = min(length(aa),zvl_peak_num_take_max);
            sync_rcd{h}.peakloc = aa(1:takenum);
            sync_rcd{h}.peakhei = tempp(1:takenum);
        else
            sync_rcd{h}.peakloc = [];
            sync_rcd{h}.peakhei = [];
        end
    end
    save_sync_rcd = sync_rcd;
    if local_print_flag
        fprintf(1, '        1. getting segment FFT done, window size %.3f sec\n', LRF_cfg.sync_scan_seconds)
    end


    % 2. finding initial candidates based only on 5 consecutive peak criterion 
    candiates = [];
    for symidx=1:length(sync_rcd) - maxpeakconsecutivenum*2
        for peakidx=1:length(sync_rcd{symidx}.peakloc)
            thisloc = sync_rcd{symidx}.peakloc(peakidx);
            thishei = sync_rcd{symidx}.peakhei(peakidx);
            thisrange = mod(thisloc + [-zvl_fdsigspan_coarse:zvl_fdsigspan_coarse] - 1, T) + 1;
            hist = zeros(maxpeakconsecutivenum,3);
            hist(1,1) = thisloc; 
            hist(1,2) = thishei; 
            hist(1,3) = peakidx; 
            for ridx=2:maxpeakconsecutivenum
                symidx2 = symidx + ridx - 1;
                for peakidx2=1:length(sync_rcd{symidx2}.peakloc)
                    thatloc = sync_rcd{symidx2}.peakloc(peakidx2);
                    thathei = sync_rcd{symidx2}.peakhei(peakidx2);
                    if length(find(thisrange == thatloc)) > 0
                        hist(ridx,1) = thatloc; 
                        hist(ridx,2) = thathei; 
                        hist(ridx,3) = peakidx2; 
                    end
                end
            end
            if length(find(hist(:,1))) >= threshpeakconsecutivenum
                addidx = length(candiates) + 1;
                candiates{addidx}.bgnsym = symidx;
                candiates{addidx}.range = thisrange;
                candiates{addidx}.peakloc = thisloc;
                candiates{addidx}.hist = hist;
                candiates{addidx}.thisest = (symidx - 1)*T + 1;
                vaildidx = find(hist(:,1));
                alllocs = hist(vaildidx,1);
                tempp = find(alllocs > T/2); 
                alllocs(tempp) = alllocs(tempp) - T;
                thisfreq = mean(alllocs);
                candiates{addidx}.thisfreq_Hz = thisfreq*LRF_cfg.samplingrate/T; 
                % abs(thisfreq - 2115) < 6 && abs(candiates{addidx}.thisest - 409032) < 1000
                
                for ridx=2:2 %maxpeakconsecutivenum 
                    % NOTE: just need to remove the second one to break the
                    % 4-5 run, so that the rest cannnot be identified as a
                    % potential header. better when there is some collision
                    % when some data seg is right before the header
                    symidx2 = symidx + ridx - 1;
                    maskidx = hist(ridx,3);
                    if maskidx > 0
                        sync_rcd{symidx2}.peakloc(maskidx) = [];
                        sync_rcd{symidx2}.peakhei(maskidx) = [];
                    end
                end
            end
        end
    end
    if local_print_flag
        fprintf(1, '        2. finding candidate (at least %d peaks at same loc): got %d candidates\n', threshpeakconsecutivenum, length(candiates));
    end
        
    % 3. sliding window one symbol at a time to check when the energy
    % withint the rage is the highest
    
    if local_print_flag
        fprintf(1, '        3. finding coarse estimates: candi ');
        for h=1:5 fprintf(1, ' '); end
    end
    for candidx=1:length(candiates) 
        if local_print_flag
            if mod(candidx,10) == 0
                for h=1:5 fprintf(1, '\b'); end
                fprintf(1, '%5d', candidx);
            end
        end

        findscanbgn = candiates{candidx}.thisest - T + 1;
        findscanend = candiates{candidx}.thisest + T;
        here_scanlen_sec = (findscanend-findscanbgn+1)/LRF_cfg.samplingrate;
        here_scanlen_num = floor(here_scanlen_sec*LRF_cfg.BW);
        findscanarray = 1+round([0:here_scanlen_num-1]/LRF_cfg.BW*LRF_cfg.samplingrate);

        thisfreq_Hz = candiates{candidx}.thisfreq_Hz;
        SegCoarseTime(candidx,1:2) = [candiates{candidx}.thisest,candiates{candidx}.thisest+finesiglen-1];
        SegCoarseFreqHz(candidx) = thisfreq_Hz;
        SegCoarseScore(candidx) = 0;            
        if ~(findscanbgn > 0 && findscanend < size(LRFHSS_time_sig,2))
            continue;
        end

        thissig = LRFHSS_time_sig(:,findscanbgn:findscanend + finesiglen);
        herepadsmplnum = 8;
        pad_thissig = horzcat(thissig(:,1:herepadsmplnum*LRF_cfg.smblsmplnum),thissig);
        thislpfsig = lrfh_lpfsig(pad_thissig,thisfreq_Hz,0,LRF_cfg);
        thislpfsigp = thislpfsig.*conj(thislpfsig);
        if local_ant_num > 1
            thislpfsigp = sum(thislpfsigp);
        end        
        thislpfsigp = thislpfsigp(:,herepadsmplnum*LRF_cfg.smblsmplnum+1:end);

        segnum = floor(length(thislpfsigp)/finescanstep);
        tempp = thislpfsigp(1:segnum*finescanstep);
        tempp1 = reshape(tempp,finescanstep,segnum);
        segval = sum(tempp1);

        winsegnum = round(finesiglen/finescanstep);
        scores = zeros(1,length(findscanarray));
        for scanidx=1:length(findscanarray)
            scores(scanidx) = sum(segval(scanidx:min(scanidx+winsegnum-1,segnum)));
        end
        [heremaxscore,heremaxloc] = max(scores);

        shouldkeepflag = 1;
        normscores = scores/heremaxscore;
        if mean(abs(normscores-mean(normscores))) < 0.01 
            shouldkeepflag = 0;
        end

        if shouldkeepflag
            SegCoarseTime(candidx,:) = findscanarray(heremaxloc) + findscanbgn + [0,finesiglen-1];
            SegCoarseFreqHz(candidx) = thisfreq_Hz;
            SegCoarseScore(candidx) = heremaxscore;
        end
    end
   
    rmvflag = zeros(1,size(SegCoarseTime,1));
    rmvflag(find(SegCoarseScore==0)) = 1;
    for h=1:size(SegCoarseTime,1)
        tempp1 = abs(SegCoarseTime(h,1) - SegCoarseTime(:,1));
        tempp1(h) = max(tempp1);
        tempp2 = abs(SegCoarseFreqHz(h) - SegCoarseFreqHz);
        tempp2(h) = max(tempp2);
        tempp3 = find(tempp1 < LRF_cfg.smblsmplnum*3);
        tempp4 = find(tempp2 < 10);
        tempp5 = intersect(tempp3, tempp4);
        tempp6 = find(SegCoarseScore < SegCoarseScore(h)*0.999);
        tempp7 = intersect(tempp5, tempp6);
        rmvflag(tempp7) = 1;
    end
    rmvlist = find(rmvflag);
    SegCoarseTime(rmvlist,:) = [];
    SegCoarseFreqHz(rmvlist) = [];
    SegCoarseScore(rmvlist) = [];

    if local_print_flag
        fprintf(1, '\n           found %d headers to further process\n', length(SegCoarseTime));
    end