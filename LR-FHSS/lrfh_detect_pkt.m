% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function [HeaderOutput,FoundDataSeg] = lrfh_detect_pkt(lrfh_sim_decode_try_count,LRFHSS_time_sig,lrfh_sim_result,LRF_cfg)

dbg_test_hdr_decoding_flag = 0;
if dbg_test_hdr_decoding_flag == 0
    [SegCoarseTime, SegCoarseFreqHz, SegCoarseScore] = lrfh_detect_hdr(LRFHSS_time_sig,LRF_cfg);
else
    SegCoarseTime = zeros(length(idealFoundDataSeg{1}.headerinfo),2);
    SegCoarseFreqHz = zeros(1,length(idealFoundDataSeg{1}.headerinfo));
end

if lrfh_sim_decode_try_count > 1 && length(SegCoarseFreqHz) > 0
    % NOTE: run decoding only twice, so just check the last one
    rmvflag = zeros(1, length(SegCoarseFreqHz));
    for lastpktidx=1:length(lrfh_sim_result{lrfh_sim_decode_try_count-1})
        thatpkt = lrfh_sim_result{lrfh_sim_decode_try_count-1}{lastpktidx};
        if thatpkt.CRCpass
            for hdridx=1:thatpkt.header_count
                thishdr = thatpkt.headerinfo{hdridx};
                if ~isempty(thishdr)
                    thishdrctime = thishdr.CoarseTime(1);
                    thishdrcfreq = thishdr.CoarseFreqHz;
                    tempp1 = abs(SegCoarseTime(:,1) - thishdrctime);
                    tempp2 = abs(SegCoarseFreqHz - thishdrcfreq);
                    tempp3 = find(tempp1 < LRF_cfg.smblsmplnum*3);
                    tempp4 = find(tempp2 < 10);
                    tempp5 = intersect(tempp3, tempp4);
                    rmvflag(tempp5) = 1;
                end
            end
        end
    end
    rmvlist = find(rmvflag);
    SegCoarseTime(rmvlist,:) = [];
    SegCoarseFreqHz(rmvlist) = [];
end

HeaderOutput_raw = []; 
HeaderOutput = [];
local_hdr_bypass_till = 0; local_coz_pkt_bypass_bgn = 0; local_coz_pkt_bypass_end = 0;
for headeridx=1:size(SegCoarseTime,1)
    thisHdrCoarseTime = SegCoarseTime(headeridx,:);
    thisHdrCoarseFreqHz = SegCoarseFreqHz(headeridx);
    if dbg_test_hdr_decoding_flag == 0
        herepassinfo = [];
    else
        herepassinfo = idealFoundDataSeg{1}.headerinfo{headeridx};
    end

    if LRF_cfg.for_link_test_flag
        if thisHdrCoarseTime(1) < local_hdr_bypass_till
            continue;
        end
        if thisHdrCoarseTime(1) > local_coz_pkt_bypass_bgn && thisHdrCoarseTime(1) < local_coz_pkt_bypass_end 
            continue;
        end
    end

    HeaderOutput_raw{headeridx} = lrfh_fine_est_header(LRFHSS_time_sig,thisHdrCoarseTime,thisHdrCoarseFreqHz, herepassinfo, LRF_cfg);
    if HeaderOutput_raw{headeridx}.shouldkeepflag == 0
        fprintf(1,'*** sync peak check FAILED *** candi header %d, coarse time %d, coarse freq %.2f\n', headeridx, thisHdrCoarseTime(1), thisHdrCoarseFreqHz);
        continue;
    end
    [HeaderOutput_raw{headeridx}.bits, HeaderOutput_raw{headeridx}.GMSKdemodvaladj] = lrfh_demodulate_header(LRFHSS_time_sig,HeaderOutput_raw{headeridx},LRF_cfg);

    HeaderOutput_raw{headeridx}.deint = lrfh_deinterleaving_hdr(HeaderOutput_raw{headeridx}.bits);
    [a,b] = lrfh_decode_hdr(HeaderOutput_raw{headeridx}.deint, LRF_cfg.myTrellis_header);
    HeaderOutput_raw{headeridx}.decode  = a;
    HeaderOutput_raw{headeridx}.info  = b;
    if LRF_cfg.region == LRF_cfg.region_val_US
        hereshouldaddflag = HeaderOutput_raw{headeridx}.info.CRCpass && HeaderOutput_raw{headeridx}.info.payloadlen <= LRF_cfg.max_payload_byte_num ...
        && HeaderOutput_raw{headeridx}.info.grid == 0 && HeaderOutput_raw{headeridx}.info.hop == 1 ...
        && isequal(HeaderOutput_raw{headeridx}.info.BW, [1 0 0 0]) ...
        && bi2de(HeaderOutput_raw{headeridx}.info.hopseq(end:-1:1)) < 384 ...
        && (HeaderOutput_raw{headeridx}.info.CR == 1 || HeaderOutput_raw{headeridx}.info.CR == 3); 
    elseif LRF_cfg.region == LRF_cfg.region_val_EU
        hereshouldaddflag =  HeaderOutput_raw{headeridx}.info.CRCpass && HeaderOutput_raw{headeridx}.info.payloadlen <= LRF_cfg.max_payload_byte_num ...
        && HeaderOutput_raw{headeridx}.info.grid == 1 && HeaderOutput_raw{headeridx}.info.hop == 1 ...
        && isequal(HeaderOutput_raw{headeridx}.info.BW, [0 0 1 0]) ...
        && bi2de(HeaderOutput_raw{headeridx}.info.hopseq(end:-1:1)) < 384 ...
        && (HeaderOutput_raw{headeridx}.info.CR == 1 || HeaderOutput_raw{headeridx}.info.CR == 3); 
    end
    if hereshouldaddflag 
        thishdr = HeaderOutput_raw{headeridx};
        if thishdr.info.CR == 1
            thishdr.header_count = 2;
        elseif thishdr.info.CR == 3
            thishdr.header_count = 3;
        else
            thishdr.header_count = 3; % NOTE: our trace will not lead to here
        end    
        thishdr.thishdridx = thishdr.header_count - thishdr.info.syncindex;
        thishdr.payload_length_de = thishdr.info.payloadlen;
        thishdr.payload_length_bits = 8*(thishdr.payload_length_de+2)+6;
        coff = [6/5 3/2 2 3 ];
        thishdr.data_in_bitcount = ceil(thishdr.payload_length_bits*coff(thishdr.info.CR+1));
        if LRF_cfg.for_link_test_flag
            local_coz_pkt_bypass_bgn = thishdr.start + LRF_cfg.staysmplnum_hdr*(thishdr.header_count-thishdr.thishdridx+1) - LRF_cfg.lookdist - 1; % NOTE: may need some work
            local_coz_pkt_bypass_end = local_coz_pkt_bypass_bgn + LRF_cfg.smblsmplnum*thishdr.data_in_bitcount - 10000;
            local_hdr_bypass_till = thishdr.start + LRF_cfg.staysmplnum_hdr - 10000;
        end
        HeaderOutput{length(HeaderOutput)+1} = thishdr; 
        fprintf(1,'decoding candi header %d, found header %d: idx %d, CR %d, start %d, freq %.2f, power %.2f, cost %.2f\n', headeridx, length(HeaderOutput), ...
            thishdr.info.syncindex, thishdr.info.CR, thishdr.start, thishdr.foundfreq, thishdr.maxsyncval, thishdr.info.min_cost)
    else
        fprintf(1,'decoding candi header %d, FAIL, coarse time %d, coarse freq %.2f\n', headeridx, thisHdrCoarseTime(1), thisHdrCoarseFreqHz);
    end
end

FoundDataSeg = [];
for headeridx=1:length(HeaderOutput)
    thishdr = HeaderOutput{headeridx};
    thishdridx =  thishdr.thishdridx;
    if thishdridx <= 0 
        continue;
    end
    freq_mulconst = 0.9537; %(HeaderOutput{2}.foundfreq - HeaderOutput{1}.foundfreq)/(freq_header(2)-freq_header(1))
    
    thispkt = [];
    thispkt.CRCpass = 0;
    thispkt.CR = thishdr.info.CR;
    thispkt.payload_length_de = thishdr.payload_length_de;
    thispkt.payload_length_bits = thishdr.payload_length_bits;
    thispkt.data_in_bitcount = thishdr.data_in_bitcount;
    thispkt.num_frags = ceil(thispkt.data_in_bitcount/48);
    thispkt.num_bits_frags = zeros(1,thispkt.num_frags);
    thispkt.num_bits_frags(1:end) = 48;
    thispkt.num_bits_frags(end) = thispkt.data_in_bitcount - 48*(thispkt.num_frags-1);
    thispkt.grid = thishdr.info.grid;
    thispkt.enable_hop = thishdr.info.hop;
    thispkt.BW = thishdr.info.BW;
    thispkt.hop_seq_id = thishdr.info.hopseq;
    thispkt.header_count = thishdr.header_count;
    thispkt.freq_all = calculate_freq_from_hop_seq_id(thispkt.grid, thispkt.enable_hop, thispkt.header_count, thispkt.BW, thispkt.hop_seq_id, thispkt.num_frags);
    thispkt.freq_header = thispkt.freq_all(1:thispkt.header_count);
    thispkt.freq = thispkt.freq_all(thispkt.header_count+1:end);
    thispkt.freq_addvalhere = thishdr.foundfreq - thispkt.freq_header(thishdridx)*freq_mulconst;
    thispkt.freq_Hz = thispkt.freq * freq_mulconst + thispkt.freq_addvalhere; 
    if max(abs(thispkt.freq_Hz)) > LRF_cfg.allBW * 0.8 % NOTE: used to be 0.6
        continue;
        % fprintf(1,'pkt %d: CRC FAIL\n', pktidx);
    end
    thispkt.freq_header_Hz = thispkt.freq_header * freq_mulconst + thispkt.freq_addvalhere;
    thispkt.start = thishdr.start + LRF_cfg.staysmplnum_hdr*(thispkt.header_count-thishdridx+1) - LRF_cfg.lookdist - 1; % NOTE: may need some work
    if thispkt.start - LRF_cfg.staysmplnum_hdr*thispkt.header_count + LRF_cfg.lookdist + 1 <= 0
        continue;
    end
    if thispkt.start + LRF_cfg.staysmplnum_data*thispkt.num_frags > size(LRFHSS_time_sig,2)
        continue;
    end
    thispkt.foundwithhdr = thishdridx;
    thispkt.headerinfo = cell(1,thispkt.header_count); 
    thispkt.headerinfo{thishdridx} = HeaderOutput{headeridx};
    thispkt.SegCoarseTime = [];
    for fragmentidx=1:thispkt.num_frags
        thispkt.SegCoarseTime(fragmentidx,1) = thispkt.start + LRF_cfg.staysmplnum_data*(fragmentidx-1);
        if fragmentidx < thispkt.num_frags
            thispkt.SegCoarseTime(fragmentidx,2) = thispkt.SegCoarseTime(fragmentidx,1) + LRF_cfg.staysmplnum_data-1;
        else
            thispkt.SegCoarseTime(fragmentidx,2) = thispkt.SegCoarseTime(fragmentidx,1) + (thispkt.num_bits_frags(end)+1)*LRF_cfg.smblsmplnum;
        end
    end
    thispkt.hdrpower = zeros(1,thispkt.header_count);
    thispkt.hdrpower(thishdridx) = thishdr.maxsyncval;

    shouldaddflag = 1;
    for pidx=1:length(FoundDataSeg)
        if lrfh_is_same_detected_pkt(thispkt, FoundDataSeg{pidx})
            if max(FoundDataSeg{pidx}.hdrpower) < thispkt.hdrpower(thishdridx)
                for h=1:thispkt.header_count
                    if ~isempty(FoundDataSeg{pidx}.headerinfo{h}) && h ~= thishdridx
                        thispkt.headerinfo{h} = FoundDataSeg{pidx}.headerinfo{h};
                        thispkt.hdrpower(h) = FoundDataSeg{pidx}.hdrpower(h);
                    end
                end
                FoundDataSeg{pidx} = thispkt;
            end
            if FoundDataSeg{pidx}.hdrpower(thishdridx) < thispkt.hdrpower(thishdridx)
                FoundDataSeg{pidx}.headerinfo{thishdridx} = thispkt.headerinfo{thishdridx};
                FoundDataSeg{pidx}.hdrpower(thishdridx) = thispkt.hdrpower(thishdridx);
            end
            shouldaddflag = 0;
            break;
        end
    end
    if lrfh_sim_decode_try_count > 1
        % NOTE: run decoding only twice, so just check the last one
        for lastpktidx=1:length(lrfh_sim_result{lrfh_sim_decode_try_count-1})
            thatpkt = lrfh_sim_result{lrfh_sim_decode_try_count-1}{lastpktidx};
            if lrfh_is_same_detected_pkt(thispkt, thatpkt) && thatpkt.CRCpass
                shouldaddflag = 0;
                break;
            end
        end
    end
    if shouldaddflag
        tempp = length(FoundDataSeg);
        FoundDataSeg{tempp+1} = thispkt;
    end
end

for pktidx=1:length(FoundDataSeg)
    thispkt = FoundDataSeg{pktidx};
    maxsyncval_samples = [];
    for h=1:thispkt.header_count
        if ~isempty(thispkt.headerinfo{h})
            maxsyncval_samples = [maxsyncval_samples, thispkt.headerinfo{h}.maxsyncval];
        end
    end
    FoundDataSeg{pktidx}.estpower = mean(maxsyncval_samples);
end