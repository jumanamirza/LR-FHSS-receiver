% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function [FoundSigGird, outFoundDataSeg] = lrfh_get_overlapinfo(FoundDataSeg,use_grid_time_num,LRF_cfg)

FoundSigGird = zeros(use_grid_time_num,LRF_cfg.use_grid_freq_num);

fprintf(1,'getting overlapping info ... ')
for pktidx=1:length(FoundDataSeg)
    thispkt = FoundDataSeg{pktidx};
    thispkt.hdroverlapinfo = cell(1,thispkt.header_count);
    thispkt.overlapinfo = cell(1,thispkt.num_frags);
    for hdridx=1:thispkt.header_count
        thisbgn = thispkt.start - LRF_cfg.staysmplnum_hdr*(thispkt.header_count-hdridx+1) + LRF_cfg.lookdist + 1;
        thisend = thisbgn + LRF_cfg.staysmplnum_hdr - 1; 
        thistimeidxbgn = ceil(thisbgn/LRF_cfg.use_grid_time_sampnum);
        thistimeidxend = floor(thisend/LRF_cfg.use_grid_time_sampnum);
        thisfreqidx = round(thispkt.freq_header_Hz(hdridx) / LRF_cfg.use_grid_freq_Hz) + LRF_cfg.use_grid_freq_idx_offset + ceil(LRF_cfg.use_grid_freq_num/2); 
        if min(thisfreqidx) > 0 && max(thisfreqidx) <= LRF_cfg.use_grid_freq_num 
            FoundSigGird(thistimeidxbgn:thistimeidxend,thisfreqidx) = FoundSigGird(thistimeidxbgn:thistimeidxend,thisfreqidx) + thispkt.estpower;
        end
        thispkt.hdroverlapinfo{hdridx}.thistimeidx = [thistimeidxbgn:thistimeidxend];
        thispkt.hdroverlapinfo{hdridx}.thisfreqidx = thisfreqidx;
        thispkt.hdroverlapinfo{hdridx}.interf_flag_mat = zeros(length(thispkt.hdroverlapinfo{hdridx}.thistimeidx),length(thispkt.hdroverlapinfo{hdridx}.thisfreqidx));
        if hdridx == 1
            thispkt.firstsmplidx = thistimeidxbgn;
        end
    end
    for fgidx=1:thispkt.num_frags
        thisbgn = thispkt.start + LRF_cfg.staysmplnum_data * (fgidx-1);
        thisend = thisbgn + LRF_cfg.staysmplnum_data - 1; % NOTE: do not know the length of the last fragment, use maximum 
        thistimeidxbgn = round(thisbgn/LRF_cfg.use_grid_time_sampnum);
        thistimeidxend = round(thisend/LRF_cfg.use_grid_time_sampnum);
        thisfreqidx = round(thispkt.freq_Hz(fgidx) / LRF_cfg.use_grid_freq_Hz) + LRF_cfg.use_grid_freq_idx_offset + ceil(LRF_cfg.use_grid_freq_num/2); 
        if min(thisfreqidx) > 0 && max(thisfreqidx) <= LRF_cfg.use_grid_freq_num 
            FoundSigGird(thistimeidxbgn:thistimeidxend,thisfreqidx) = FoundSigGird(thistimeidxbgn:thistimeidxend,thisfreqidx) + thispkt.estpower;
        end
        thispkt.overlapinfo{fgidx}.thistimeidx = [thistimeidxbgn:thistimeidxend];
        thispkt.overlapinfo{fgidx}.thisfreqidx = thisfreqidx;
        thispkt.overlapinfo{fgidx}.interf_flag_mat = zeros(length(thispkt.overlapinfo{fgidx}.thistimeidx),length(thispkt.overlapinfo{fgidx}.thisfreqidx));
        if fgidx == thispkt.num_frags
            thispkt.lastsmplidx = thistimeidxend;
        end
    end
    FoundDataSeg{pktidx} = thispkt;
end

for pktidx=1:length(FoundDataSeg)
    thispkt = FoundDataSeg{pktidx};
    for hdridx=1:thispkt.header_count
        thistimeidx = thispkt.hdroverlapinfo{hdridx}.thistimeidx;
        thisfreqidx = thispkt.hdroverlapinfo{hdridx}.thisfreqidx;
        if min(thisfreqidx) > 0 && max(thisfreqidx) <= LRF_cfg.use_grid_freq_num 
            for tidxidx=1:length(thistimeidx)
                for fidxidx=1:length(thisfreqidx)
                    tidx = thistimeidx(tidxidx);
                    fidx = thisfreqidx(fidxidx);
                    if FoundSigGird(tidx,fidx) > thispkt.estpower * LRF_cfg.interf_alarm_thresh
                        thispkt.hdroverlapinfo{hdridx}.interf_flag_mat(tidxidx,fidxidx) = 1;
                    end
                end
            end
        end
    end
    for fgidx=1:thispkt.num_frags
        thistimeidx = thispkt.overlapinfo{fgidx}.thistimeidx;
        thisfreqidx = thispkt.overlapinfo{fgidx}.thisfreqidx;
        if min(thisfreqidx) > 0 && max(thisfreqidx) <= LRF_cfg.use_grid_freq_num 
            for tidxidx=1:length(thistimeidx)
                for fidxidx=1:length(thisfreqidx)
                    tidx = thistimeidx(tidxidx);
                    fidx = thisfreqidx(fidxidx);
                    if FoundSigGird(tidx,fidx) > thispkt.estpower * LRF_cfg.interf_alarm_thresh
                        thispkt.overlapinfo{fgidx}.interf_flag_mat(tidxidx,fidxidx) = 1;
                    end
                end
            end
        end
    end
    thisdetailedcolinfo = [];
    for fgidx=1:thispkt.num_frags
        thistimeidx = thispkt.overlapinfo{fgidx}.thistimeidx;
        thiscenterf = thispkt.freq_Hz(fgidx);
        thisinterfP = zeros(1,length(thistimeidx));
        for pktidx2=1:length(FoundDataSeg)
            if pktidx == pktidx2 
                continue; 
            end
            thatpkt = FoundDataSeg{pktidx2};
            if thistimeidx(1) > thatpkt.lastsmplidx || thistimeidx(end) < thatpkt.firstsmplidx
                continue; 
            end
            for hdrdataidx=1:2
                for segidx=1:100
                    if hdrdataidx == 1
                        if segidx <= thatpkt.header_count
                            thattimeidx = thatpkt.hdroverlapinfo{segidx}.thistimeidx;
                            thatcenterf = thatpkt.freq_header_Hz(segidx);
                        else
                            break;
                        end
                    else
                        if segidx <= thatpkt.num_frags
                            thattimeidx = thatpkt.overlapinfo{segidx}.thistimeidx;
                            thatcenterf = thatpkt.freq_Hz(segidx);
                        else
                            break;
                        end
                    end
                    overlaptimeidx = intersect(thistimeidx,thattimeidx);
                    interffdist = thatcenterf - thiscenterf;
                    if length(overlaptimeidx) > 0 && interffdist > LRF_cfg.InterfF(1) && interffdist < LRF_cfg.InterfF(end)
                        tempp = interffdist - LRF_cfg.InterfF;
                        [a,interffidx] = min(abs(tempp));
                        overlapinfgidx = overlaptimeidx - thistimeidx(1) + 1;
                        overlapinthatfgidx = overlaptimeidx - thattimeidx(1) + 1;
                        thatpktinterP = LRF_cfg.InterfP(interffidx)*thatpkt.estpower;
                        thisinterfP(overlapinfgidx) = thisinterfP(overlapinfgidx) + thatpktinterP;
                        
                        hereidx = length(thisdetailedcolinfo)+1;
                        thisdetailedcolinfo{hereidx}.own_fgidx = fgidx;
                        thisdetailedcolinfo{hereidx}.col_pkt_idx = pktidx2;
                        thisdetailedcolinfo{hereidx}.col_pkt_hdrorfg = hdrdataidx; % 1: header, 2: data frag
                        thisdetailedcolinfo{hereidx}.col_pkt_segidx = segidx; 
                        thisdetailedcolinfo{hereidx}.col_pkt_symidx = overlapinthatfgidx; 
                        thisdetailedcolinfo{hereidx}.overlapinfgidx = overlapinfgidx;
                        thisdetailedcolinfo{hereidx}.interP = thatpktinterP;
                    end
                end
            end
        end
        thispkt.overlapinfo{fgidx}.invSIR = thisinterfP/thispkt.estpower;
    end
    thispkt.detailedcolinfo = thisdetailedcolinfo;
    FoundDataSeg{pktidx} = thispkt;
end
outFoundDataSeg = FoundDataSeg;
fprintf(1,'done\n')