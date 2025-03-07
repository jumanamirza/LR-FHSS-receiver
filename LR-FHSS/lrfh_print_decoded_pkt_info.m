% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

%{
sta_decoded_flag:

1. detected in round
2. detected as packet
3. decoded in round
4. decoded as packet
5. decode cost
6. found header number
7. packet trace index
%}

function [sta_decoded_flag, drinfo] = lrfh_print_decoded_pkt_info(idealFoundDataSeg, lrfh_sim_result, lrfh_sim_config)

drinfo  = zeros(2);
if lrfh_sim_config.use_ursp_flag == 0

    sta_decoded_flag = zeros(length(lrfh_sim_config.USE_FILE_IDX_array),7);
    for ipktidx=1:length( lrfh_sim_config.USE_FILE_IDX_array)
        traceidx =  lrfh_sim_config.USE_FILE_IDX_array(ipktidx);
        sta_decoded_flag(ipktidx,7) = traceidx;
        thispkt = idealFoundDataSeg{ipktidx};
        for try_count=1:length(lrfh_sim_result)
            FoundDataSeg = lrfh_sim_result{try_count};
            for pktidx=1:length(FoundDataSeg)
                thatpkt = FoundDataSeg{pktidx};
                if lrfh_is_same_detected_pkt(thispkt, thatpkt) && sta_decoded_flag(ipktidx,1) == 0
                    sta_decoded_flag(ipktidx,1) = try_count; 
                    sta_decoded_flag(ipktidx,2) = pktidx;
                    tempp = 0;
                    for uuu=1:thatpkt.header_count
                        if ~isempty(thatpkt.headerinfo{uuu})
                            tempp = tempp + 1;
                        end
                    end
                    sta_decoded_flag(ipktidx,6) = tempp;
                    break;
                end
            end
            for pktidx=1:length(FoundDataSeg)
                thatpkt = FoundDataSeg{pktidx};
                if thatpkt.CRCpass && lrfh_is_same_detected_pkt(thispkt, thatpkt)
                    if length(thispkt.decoderes.dewhitening) == length(thatpkt.decoderes.dewhitening)
                        if sum(abs(thispkt.decoderes.dewhitening - thatpkt.decoderes.dewhitening)) == 0 ...
                            && sta_decoded_flag(ipktidx,3) == 0
                            sta_decoded_flag(ipktidx,3) = try_count; 
                            sta_decoded_flag(ipktidx,4) = pktidx;
                            sta_decoded_flag(ipktidx,5) = thatpkt.decoderes.cost;
                            maptoidxidx = ipktidx;
                            break;
                        end
                    end
                end
            end
        end
        fprintf(1,'pkt %d -- CR %d, traceidx %d -- ', ipktidx, thispkt.CR, traceidx);
        if sta_decoded_flag(ipktidx, 1) == 0
            fprintf(1,'NOT DETECTED -- ');
        else
            fprintf(1,'detected in attempt %d as pkt %d -- ', ...
                sta_decoded_flag(ipktidx,1), sta_decoded_flag(ipktidx,2));
        end
        if sta_decoded_flag(ipktidx, 3) == 0
            fprintf(1,'NOT DECODED\n');
        else
            fprintf(1,'decoded in attempt %d as pkt %d cost %.2f\n', ...
                sta_decoded_flag(ipktidx,3), sta_decoded_flag(ipktidx,4), sta_decoded_flag(ipktidx,5));
        end
    end
    dr8idx = find(sta_decoded_flag(:,7) <= 500);
    dr9idx = find(sta_decoded_flag(:,7) > 500);
    dr8gotnum = length(find(sta_decoded_flag(dr8idx,3)));
    dr9gotnum = length(find(sta_decoded_flag(dr9idx,3)));
    
    if length(dr8idx)
        fprintf(1, 'DR8 PRR %.2f (%d / %d)\n', dr8gotnum/length(dr8idx), dr8gotnum, length(dr8idx));
    end
    if length(dr9idx)
        fprintf(1, 'DR9 PRR %.2f (%d / %d)\n', dr9gotnum/length(dr9idx), dr9gotnum, length(dr9idx));
    end
    drinfo = [length(dr8idx), dr8gotnum; length(dr9idx), dr9gotnum];
else
    sta_decoded_flag = [];
    FoundDataSeg = lrfh_sim_result{1};
    FoundDataSeg_2 = lrfh_sim_result{2};
    for pktidx=1:length(FoundDataSeg_2)
        FoundDataSeg{length(FoundDataSeg)+1} = FoundDataSeg_2{pktidx};
    end   
    tokeeplag = ones(1,length(FoundDataSeg));
    for pktidx=1:length(FoundDataSeg)
        thispkt = FoundDataSeg{pktidx};
        if thispkt.CRCpass == 0 
            tokeeplag(pktidx) = 0;
        end
    end
    for pktidx=1:length(FoundDataSeg)-1
        thispkt = FoundDataSeg{pktidx};
        if tokeeplag(pktidx) == 0 
            continue; 
        end
        for pktidx2=pktidx+1:length(FoundDataSeg)
            thatpkt = FoundDataSeg{pktidx2};
            if tokeeplag(pktidx2) == 0 
                continue; 
            end
            if thispkt.CR == thatpkt.CR && thispkt.payload_length_bits == thatpkt.payload_length_bits
                tempp = thispkt.decoderes.foundpayload - thatpkt.decoderes.foundpayload;
                if sum(abs(tempp))==0
                    tokeeplag(pktidx2) = 0;
                end
            end
        end
    end
    fprintf(1, '\n\nProcessing USRP packets. Decoded %d unique packets.\n\n', sum(tokeeplag));
end