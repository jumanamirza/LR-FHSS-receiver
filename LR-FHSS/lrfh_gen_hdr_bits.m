function headerbits = lrfh_gen_hdr_bits(state, decoded_header, LRF_cfg, knowinitstate_flag)
    header_enco = lrfh_con_encode_hdr(state,decoded_header,LRF_cfg.myTrellis_header,knowinitstate_flag);
    header_interl = lrfh_interleaving_hdr(header_enco);
    headerbits = [0 header_interl(1:40) LRF_cfg.SYNC_WORD header_interl(41:end)];
end    
