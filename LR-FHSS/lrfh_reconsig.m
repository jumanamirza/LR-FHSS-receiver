% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function [result, para] = lrfh_reconsig(data, thischecksig_0, thisDataSegFreqHz, LRF_cfg) 

% 0. convert sig to baseband
local_ant_num = size(thischecksig_0,1);
thischecksig = lrfh_lpfsig(thischecksig_0,thisDataSegFreqHz,0,LRF_cfg);
% task 0: about 0.025 sec for hdr on laptop on battery, no way to get better

% 1. get the ideal phase change    
modsig0 = lrfh_gen_ideal_waveform(data,LRF_cfg);
% task 1: very fast

% 2. est the timing error
maxbitnum = min(length(data),floor(size(thischecksig_0,2)/LRF_cfg.smblsmplnum));
smpltime = LRF_cfg.lookdist + 1 + round([0:maxbitnum-1]/LRF_cfg.BW*LRF_cfg.samplingrate);
smplvals = thischecksig(:,smpltime);
sigpower = sum(transpose(thischecksig(:,1:10:end).*conj(thischecksig(:,1:10:end))));
MRCcoeff = sigpower/sum(sigpower);

phasechange = angle(smplvals(:,2:end)./smplvals(:,1:end-1));
movevals = zeros(1,local_ant_num);
for ant=1:local_ant_num
    diff01 = []; diff10 = [];
    for didx=1:length(data)-3 % NOTE: skip some of the paddings 
        if data(didx)==0 && data(didx+1)==1
            diff01 = [diff01, phasechange(ant, didx)];
        elseif data(didx)==1 && data(didx+1)==0
            diff10 = [diff10, phasechange(ant, didx)];
        end
    end
    % NOTE: 
    %  - 01 - and 10 +: sample too early; 
    %  - 01 + and 10 -: sample too late; 
    movdir = 0;
    avg01 = mean(diff01); avg10 = mean(diff10);
    if avg01 < 0 && avg10 > 0
        movdir = 1;  % too early, need to add
    elseif avg01 > 0 && avg10 < 0
        movdir = -1; % too late,  need to sub 
    end
    movphase = mean([abs(avg01), abs(avg10)]);
    movsampnum = round(movphase/2/(pi/2)*LRF_cfg.smblsmplnum);
    movevals(ant) = movdir*movsampnum;
end
estmove = sum(MRCcoeff.*movevals);
estmove = sign(estmove)*min(LRF_cfg.max_SIC_time_off_smpl_num,abs(estmove)); % adding this does not change anything, but keep it here
adjsmpltime = round(smpltime + estmove);
if adjsmpltime(1) > 0 && adjsmpltime(end) < size(thischecksig,2)
    smpltime = adjsmpltime;
end
shifthere = round(LRF_cfg.smblsmplnum/2 - smpltime(1));
if shifthere > 0
    modsig0 = modsig0(shifthere:end);
else
    modsig0 = [zeros(1,-shifthere) modsig0];
end
para.timeadj = estmove;
% fprintf(1,'--- estmove %.4f\n', estmove)
% task 2: about 0.007 sec

uselen = min(size(thischecksig,2),size(modsig0,2));  
modsig = zeros(local_ant_num, size(modsig0,2));

fitseglen_default = round(LRF_cfg.smblsmplnum*LRF_cfg.recon_seg_len_symbol_num); % 10: 587; 16: 574
fitsegnum = floor(uselen/fitseglen_default);
if fitsegnum > 0
    allsmblnum = floor(uselen/LRF_cfg.smblsmplnum);
    eachsegnum = floor(allsmblnum/fitsegnum);
    spillover = allsmblnum - fitsegnum*eachsegnum; 
    fitsegsmblenum = ones(1,fitsegnum)*eachsegnum; 
    fitsegsmblenum(1:spillover) = fitsegsmblenum(1:spillover)+1;
else
    fitsegnum = 1;
    fitsegsmblenum = [floor(uselen/LRF_cfg.smblsmplnum)];
end
fitseglen = round(fitsegsmblenum/LRF_cfg.BW*LRF_cfg.samplingrate);
% NOTE:10 symbols, ~20 ms, one cycle is already off by 50 Hz 
finetuneCFOarray_Hz = [-50:5:50];
usemodsig = zeros(size(modsig));

estgain = zeros(fitsegnum,local_ant_num);
estcfo_Hz = zeros(fitsegnum,local_ant_num);
for fitsegidx=1:fitsegnum
    if fitsegidx == 1
        thesesmblidx_bgn = 1;
    else
        thesesmblidx_bgn = sum(fitsegsmblenum(1:fitsegidx-1))+1;
    end            
    thesesmblidx_end = thesesmblidx_bgn + fitsegsmblenum(fitsegidx) - 1;
    thesesmblidx = [thesesmblidx_bgn:thesesmblidx_end];
    thesesmbllocs = smpltime(thesesmblidx);
    thisidealsmples = exp(1i*modsig0(thesesmbllocs));
    thisrcvsmples = thischecksig(:, thesesmbllocs);

    finetuneCFOarray_cycle_num_seg = finetuneCFOarray_Hz*fitsegsmblenum(fitsegidx)*LRF_cfg.smblsmplnum/LRF_cfg.samplingrate;
    cmplxscores = zeros(local_ant_num,length(finetuneCFOarray_cycle_num_seg));
    for ant=1:local_ant_num
        for fncfoidx=1:length(finetuneCFOarray_cycle_num_seg)
            thiscfoval = finetuneCFOarray_cycle_num_seg(fncfoidx);
            thiswave = exp(1i*2*pi*[0:fitsegsmblenum(fitsegidx)-1]/fitsegsmblenum(fitsegidx)*thiscfoval);
            tempp = thisrcvsmples(ant,:).*conj(thisidealsmples)./thiswave;
            cmplxscores(ant,fncfoidx) = sum(tempp)/length(tempp);
        end
    end
    scores = abs(cmplxscores);
    for ant=1:local_ant_num
        [a,b] = max(scores(ant,:));
        estgain(fitsegidx,ant) = cmplxscores(ant,b);
        estcfo_Hz(fitsegidx,ant) = finetuneCFOarray_Hz(b);
    end
end
para.estgain = estgain;
para.estcfo_Hz = estcfo_Hz;

for ant=1:local_ant_num
    for fitsegidx=1:fitsegnum
        if fitsegidx == 1
            thislongbgn = 1;
        else
            thislongbgn = sum(fitseglen(1:fitsegidx-1))+1;
        end     
        thislongend = thislongbgn + fitseglen(fitsegidx) - 1;
        thisidealsig = exp(1i*modsig0(thislongbgn:thislongend));
        tempp = estcfo_Hz(fitsegidx,ant)*length(thisidealsig)/LRF_cfg.samplingrate;
        thiswave = exp(1i*2*pi*[0:length(thisidealsig)-1]/length(thisidealsig)*tempp);
        usemodsig(ant,thislongbgn:thislongend) = thisidealsig.*thiswave*exp(1i*angle(estgain(fitsegidx,ant)));
    end
end
if fitsegnum > 1
    midvalloc = round(cumsum(fitseglen) - fitseglen(1)/2);
    fitvalloc = [1 midvalloc sum(fitseglen)];
    fitval = [abs(estgain(1,:)); abs(estgain(:,:)); abs(estgain(end,:))];
else
    fitvalloc = [1 sum(fitseglen)];
    fitval = [abs(estgain(1,:)); abs(estgain(end,:))];
end
fitx = [1:sum(fitseglen)];
fitestgainabs = ones(local_ant_num, length(fitx));
for ant=1:local_ant_num
    thisfitval = fitval(:,ant);
    fitestgainabs(ant,:) = interp1(fitvalloc, thisfitval, fitx);
end
usemodsig(:,1:size(fitestgainabs,2)) = usemodsig(:,1:size(fitestgainabs,2)).*fitestgainabs;

uselen = min(size(usemodsig,2),size(thischecksig_0,2));
recondiff = thischecksig(:,1:uselen)-usemodsig(:,1:uselen);
recondiffP = sum((recondiff.*conj(recondiff)),1);
reconsigP = sum((usemodsig(:,1:uselen).*conj(usemodsig(:,1:uselen))),1); % Use recon sig because it has been filtered
para.reconsnr = reconsigP(smpltime)./recondiffP(smpltime);

%5. reapply cfo 
thisCFOwave = repmat(exp(1i*[0:size(thischecksig_0,2)-1]*2*pi/size(thischecksig_0,2)*thisDataSegFreqHz*(size(thischecksig_0,2)/LRF_cfg.samplingrate)),local_ant_num,1);
result = zeros(size(thischecksig_0));
result(:,1:uselen) = usemodsig(:,1:uselen);
result = result .* thisCFOwave; 
% task 5: about 0.01 sec