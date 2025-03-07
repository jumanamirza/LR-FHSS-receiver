function fragment = lrfh_gen_data_frag_bits(thispkt, LRF_cfg)

    payload = thispkt.decoderes.dewhitening;
    CR  = thispkt.CR;
    payload_len = thispkt.payload_length_de;
    payload_whiten = lrfh_whitening_payload(payload,payload_len);
    CRC = lrfh_crc16(payload_whiten); 
    payload_CRC = [payload_whiten CRC 0 0 0 0 0 0];
    payload_enco = lrfh_con_encode(0,payload_CRC,LRF_cfg.myTrellis,CR);
    payload_interl = lrfh_interleaving_payload(payload_enco);
    num_frags = ceil(length(payload_interl)/48);
    num_bits_frags = zeros(1,num_frags);
    num_bits_frags(1:end) = 50;
    num_bits_frags(end) = length(payload_interl) - 48*(num_frags-1)+2;
    leadpadding = [0];
    for idx=1:num_frags
        if idx~=num_frags
            fragment{idx}.bits = [leadpadding payload_interl((idx-1)*48+1:idx*48) 0];
        else
            fragment{num_frags}.bits = [leadpadding payload_interl((idx-1)*48+1:end) 0];
        end
    end