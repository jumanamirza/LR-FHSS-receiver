% input: 
%  - LRFHSS_time_sig, LRF_cfg, FoundDataSeg
%
% output: 
%  - FoundDataSeg: 
function outFoundDataSeg = lrfh_decode_found_pkts(FoundDataSeg,LRFHSS_time_sig,LRF_cfg)

for pktidx=1:length(FoundDataSeg)
    
    thispkt = FoundDataSeg{pktidx};
    thispkt.CRCpass = 0;
    thispkt.decoderes = [];

    thisFragment = []; data = [];
    for fragmentidx=1:thispkt.num_frags
        thisFrgTime = thispkt.SegCoarseTime(fragmentidx, :);        
        thisFragment{fragmentidx} = lrfh_demodulate_payload(LRFHSS_time_sig, thisFrgTime, thispkt.freq_Hz(fragmentidx), LRF_cfg, thispkt.num_bits_frags(fragmentidx)+1);
        if length(thisFragment{fragmentidx}.bits) ~= thispkt.num_bits_frags(fragmentidx)+2
            data = [data thisFragment{fragmentidx}.bits(2:end)];
        else
            data = [data thisFragment{fragmentidx}.bits(3:end)]; 
        end
    end
    thisdecoderes.bits = data;
    thisdecoderes.deint = lrfh_deinterleaving_payload(thisdecoderes.bits, thispkt.data_in_bitcount);
    [a,b,c] = lrfh_decode_payload(thisdecoderes.deint, thispkt.CR, LRF_cfg);
    thisdecoderes.decode = a;
    thisdecoderes.CRCpass = b;
    thisdecoderes.cost = c;
    thisdecoderes.dewhitening = lrfh_dewhitening_payload(thisdecoderes.decode,length(thisdecoderes.decode)/8);
    tempp = reshape(thisdecoderes.dewhitening,8,length(thisdecoderes.dewhitening)/8)';
    thisdecoderes.foundpayload = bi2de(tempp);

    thispkt.CRCpass = thisdecoderes.CRCpass;
    thispkt.decoderes = thisdecoderes;

    FoundDataSeg{pktidx} = thispkt;

    if thispkt.CRCpass
        fprintf(1,'pkt %d: CR %d, CRC PASS, cost %.2f, data [', pktidx, thispkt.CR, thispkt.decoderes.cost);
        for h=1:length(thispkt.decoderes.foundpayload)
            fprintf(1, '%.2x', thispkt.decoderes.foundpayload(h));
            if h < length(thispkt.decoderes.foundpayload)
                fprintf(1,', ');
            else
                fprintf(1,']\n');
            end
            
        end
    else
        fprintf(1,'pkt %d: CRC FAIL\n', pktidx);
    end
    
end
outFoundDataSeg = FoundDataSeg;
