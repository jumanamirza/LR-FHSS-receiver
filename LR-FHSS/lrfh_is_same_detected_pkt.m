function res = lrfh_is_same_detected_pkt(thispkt, thatpkt)
    res = 0;
    if abs(thispkt.start - thatpkt.start) < 1000 ... 
        && thispkt.data_in_bitcount == thatpkt.data_in_bitcount ...
        && sum(abs(thispkt.hop_seq_id - thatpkt.hop_seq_id)) == 0
        if max(abs(thispkt.freq_Hz - thatpkt.freq_Hz)) < 30 
            res = 1;
        end
    end
