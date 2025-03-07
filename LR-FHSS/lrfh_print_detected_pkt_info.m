% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function [] = lrfh_print_detected_pkt_info(idealFoundDataSeg,FoundDataSeg,lrfh_sim_config) 

pkt_detected_flag = zeros(1,length(idealFoundDataSeg));
for pktidx=1:length(FoundDataSeg)
    thispkt = FoundDataSeg{pktidx};
    maptoidxidx = 0;
    for ipktidx=1:length(idealFoundDataSeg)
        thatpkt = idealFoundDataSeg{ipktidx};
        if lrfh_is_same_detected_pkt(thispkt, thatpkt)
            pkt_detected_flag(ipktidx) = pktidx;
            maptoidxidx = ipktidx;
            break;
        end
    end
    if maptoidxidx > 0
        fprintf(1,'found pkt %d (actual %d, trace %d): ', pktidx, maptoidxidx, lrfh_sim_config.USE_FILE_IDX_array(maptoidxidx));
    else
        fprintf(1,'found pkt %d (do not know which one): ', pktidx);
    end
    fprintf(1,'start %d, numfrags %d, payload %d (b), CR %d,  with header %d, power %.2f, headers [', ...
        thispkt.start, thispkt.num_frags, thispkt.payload_length_bits, thispkt.CR, thispkt.foundwithhdr, thispkt.estpower);
    for h=1:thispkt.header_count
        if ~isempty(FoundDataSeg{pktidx}.headerinfo{h})
            fprintf(1,'Y');
        else
            fprintf(1,'N');
        end
        if h < thispkt.header_count
            fprintf(1,', ');
        else
            fprintf(1,'], ');
        end
    end
    fprintf(1, 'freq_Hz [')
    for fidx=1:thispkt.num_frags
        fprintf(1,'%.2f', thispkt.freq_Hz(fidx));
        if fidx < thispkt.num_frags
            fprintf(1,', ');
        else
            fprintf(1,']\n');
        end
    end
end
for ipktidx=1:length(idealFoundDataSeg)
    if pkt_detected_flag(ipktidx) == 0
        thispkt = idealFoundDataSeg{ipktidx};
        fprintf(1,'(actual %d, trace %d): start %d, numfrags %d, payload %d (b), CR %d -- NOT FOUND!\n', ...
        ipktidx,  lrfh_sim_config.USE_FILE_IDX_array(ipktidx), thispkt.start, thispkt.num_frags, thispkt.payload_length_bits, thispkt.CR);
    end
end