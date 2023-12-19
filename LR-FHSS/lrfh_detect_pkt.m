% input: 
%  - LRFHSS_time_sig, LRF_cfg, lrfh_sim_result
%
% output: 
%  - HeaderOutput: all headers passed CRC
%  - FoundDataSeg: the info of each detected data packet

function [HeaderOutput,FoundDataSeg] = lrfh_detect_pkt(lrfh_sim_decode_try_count,LRFHSS_time_sig,lrfh_sim_result,LRF_cfg)

tic
    fprintf(1, 'lrfh sim detecting header ... ')
    [SegCoarseTime, SegCoarseFreqHz, SegCoarseScore] = lrfh_detect_hdr(LRFHSS_time_sig,LRF_cfg);
    fprintf(1, 'done\n')
toc

HeaderOutput_raw = []; 
HeaderOutput = [];
for headeridx=1:size(SegCoarseTime,1)
    thisHdrCoarseTime = SegCoarseTime(headeridx,:);
    thisHdrCoarseFreqHz = SegCoarseFreqHz(headeridx);
    herepassinfo = [];
    thisHeader = lrfh_demodulate_header(LRFHSS_time_sig,thisHdrCoarseTime,thisHdrCoarseFreqHz, herepassinfo, LRF_cfg);
    HeaderOutput_raw{headeridx} = thisHeader;
    HeaderOutput_raw{headeridx}.deint = lrfh_deinterleaving_hdr(HeaderOutput_raw{headeridx}.bits);
    [a,b] = lrfh_decode_hdr(HeaderOutput_raw{headeridx}.deint, LRF_cfg.myTrellis_header);
    HeaderOutput_raw{headeridx}.decode  = a;
    HeaderOutput_raw{headeridx}.info  = b;
    if HeaderOutput_raw{headeridx}.info.CRCpass && HeaderOutput_raw{headeridx}.info.payloadlen <= 16 ...
        && HeaderOutput_raw{headeridx}.info.grid == 1 && HeaderOutput_raw{headeridx}.info.hop == 1 ...
        && isequal(HeaderOutput_raw{headeridx}.info.BW, [0 0 1 0]) ...
        && bi2de(HeaderOutput_raw{headeridx}.info.hopseq(end:-1:1)) < 384
        tempp = length(HeaderOutput);
        HeaderOutput{tempp+1} = HeaderOutput_raw{headeridx}; 
        fprintf(1,'decoding candi header %d, found header %d: idx %d, CR %d, start %d, freq %.2f, power %.2f, cost %.2f\n', headeridx, length(HeaderOutput), ...
            HeaderOutput_raw{headeridx}.info.syncindex, HeaderOutput_raw{headeridx}.info.CR, thisHeader.start, thisHeader.foundfreq, thisHeader.maxsyncval, HeaderOutput_raw{headeridx}.info.min_cost)
    else
        fprintf(1,'decoding candi header %d, FAIL, coarse time %d, coarse freq %.2f\n', headeridx, thisHdrCoarseTime(1), thisHdrCoarseFreqHz);
    end
end

FoundDataSeg = [];
for headeridx=1:length(HeaderOutput)
    thispkt = [];
    thispkt.CRCpass = 0;
    thispkt.CR = HeaderOutput{headeridx}.info.CR;
    thispkt.payload_length_de = HeaderOutput{headeridx}.info.payloadlen;
    if (thispkt.CR ~= 1 && thispkt.CR ~= 3) ...
            || (thispkt.payload_length_de < 8 || thispkt.payload_length_de > 16)
        continue;
    end
    thispkt.payload_length_bits = 8*(thispkt.payload_length_de+2)+6;
    coff = [6/5 3/2 2 3 ];
    thispkt.data_in_bitcount = ceil(thispkt.payload_length_bits*coff(thispkt.CR+1));
    thispkt.num_frags = ceil(thispkt.data_in_bitcount/48);
    thispkt.num_bits_frags = zeros(1,thispkt.num_frags);
    thispkt.num_bits_frags(1:end) = 48;
    thispkt.num_bits_frags(end) = thispkt.data_in_bitcount - 48*(thispkt.num_frags-1);
    
    thispkt.grid = HeaderOutput{headeridx}.info.grid;
    thispkt.enable_hop = HeaderOutput{headeridx}.info.hop;
    thispkt.BW = HeaderOutput{headeridx}.info.BW;
    thispkt.hop_seq_id = HeaderOutput{headeridx}.info.hopseq;
    if thispkt.CR == 1
        header_count = 2;
    elseif thispkt.CR == 3
        header_count = 3;
    else
        header_count = 3; 
    end        
    thispkt.header_count = header_count;
    thispkt.freq_all = calculate_freq_from_hop_seq_id(thispkt.grid, thispkt.enable_hop, header_count, thispkt.BW, thispkt.hop_seq_id, thispkt.num_frags);
    thispkt.freq_header = thispkt.freq_all(1:header_count);
    thispkt.freq = thispkt.freq_all(header_count+1:end);
    thishdridx = header_count - HeaderOutput{headeridx}.info.syncindex;
    if thishdridx <= 0 
        continue;
    end
    freq_mulconst = 0.9537; 
    thispkt.freq_addvalhere = HeaderOutput{headeridx}.foundfreq - thispkt.freq_header(thishdridx)*freq_mulconst;
    thispkt.freq_Hz = thispkt.freq * freq_mulconst + thispkt.freq_addvalhere; 
    if max(abs(thispkt.freq_Hz)) > LRF_cfg.allBW * 0.6 
        continue;
    end

    thispkt.freq_header_Hz = thispkt.freq_header * freq_mulconst + thispkt.freq_addvalhere;
    thispkt.start = HeaderOutput{headeridx}.start + LRF_cfg.staysmplnum_hdr*(header_count-thishdridx+1) - LRF_cfg.lookdist - 1; % NOTE: may need some work
    thispkt.foundwithhdr = thishdridx;
    thispkt.headerinfo = cell(1,header_count); 
    thispkt.headerinfo{thishdridx} = HeaderOutput{headeridx};
    thispkt.maxsyncval = HeaderOutput{headeridx}.maxsyncval;
    thispkt.SegCoarseTime = [];
    for fragmentidx=1:thispkt.num_frags
        thispkt.SegCoarseTime(fragmentidx,1) = thispkt.start + LRF_cfg.staysmplnum_data*(fragmentidx-1);
        if fragmentidx < thispkt.num_frags
            thispkt.SegCoarseTime(fragmentidx,2) = thispkt.SegCoarseTime(fragmentidx,1) + LRF_cfg.staysmplnum_data-1;
        else
            thispkt.SegCoarseTime(fragmentidx,2) = thispkt.SegCoarseTime(fragmentidx,1) + (thispkt.num_bits_frags(end)+1)*LRF_cfg.smblsmplnum;
        end
    end
    
    shouldaddflag = 1;
    for pidx=1:length(FoundDataSeg)
        thatpkt = FoundDataSeg{pidx};
        if lrfh_is_same_detected_pkt(thispkt, thatpkt)
            if thispkt.foundwithhdr > thatpkt.foundwithhdr
                for h=1:thispkt.header_count
                    if ~isempty(thatpkt.headerinfo{h})
                        thispkt.headerinfo{h} = thatpkt.headerinfo{h};
                    end
                end
                FoundDataSeg{pidx} = thispkt;
            end
            shouldaddflag = 0;
            break;
        end
    end

    if shouldaddflag
        tempp = length(FoundDataSeg);
        FoundDataSeg{tempp+1} = thispkt;
    end
end