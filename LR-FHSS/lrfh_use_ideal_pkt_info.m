% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function FoundDataSeg = lrfh_use_ideal_pkt_info(lrfh_sim_config, ALL_PKT_INFO, LRF_cfg)

    USE_FILE_IDX_array = lrfh_sim_config.USE_FILE_IDX_array; 
    lrfh_sim_pkt_start = lrfh_sim_config.pkt_start;
    lrfh_sim_pkt_gird = lrfh_sim_config.pkt_gird;
    lrfh_sim_amp = lrfh_sim_config.amp;

    FoundDataSeg = cell(1,length(USE_FILE_IDX_array));
    for pktidxidx=1:length(USE_FILE_IDX_array)
        pktidx = USE_FILE_IDX_array(pktidxidx);
        thispkt = ALL_PKT_INFO{pktidx};
    
        offsethere = lrfh_sim_pkt_start(pktidxidx) - round(LRF_cfg.pkt_trace_offset/LRF_cfg.pkt_trace_downsampling_factor);
        thispkt.gridsel = lrfh_sim_pkt_gird(pktidxidx);
        thisgridfreq_Hz = (thispkt.gridsel - 1) * LRF_cfg.BW;
        thisaddcfo_Hz = lrfh_sim_config.addpktcfo_Hz(pktidxidx);
        ampmul = lrfh_sim_amp(pktidxidx);
    
        thispkt.start = round(ALL_PKT_INFO{pktidx}.start/LRF_cfg.pkt_trace_downsampling_factor) + offsethere;
        thispkt.SegCoarseTime = thispkt.SegCoarseTime + offsethere;
        thispkt.freq_Hz = thispkt.freq_Hz + thisgridfreq_Hz + thisaddcfo_Hz; 
        thispkt.freq_header_Hz = thispkt.freq_header_Hz + thisgridfreq_Hz + thisaddcfo_Hz';
        %thispkt.maxsyncval = thispkt.maxsyncval * ampmul^2;
    
        for hidx=1:length(thispkt.headerinfo)
            if ~isempty(thispkt.headerinfo{hidx})
                thispkt.headerinfo{hidx}.start = round(thispkt.headerinfo{hidx}.start/LRF_cfg.pkt_trace_downsampling_factor) + offsethere;
                thispkt.headerinfo{hidx}.foundfreq = thispkt.headerinfo{hidx}.foundfreq + thisgridfreq_Hz + thisaddcfo_Hz;
            end
        end
        thispkt.CRCpass = 0;
        FoundDataSeg{pktidxidx} = thispkt;
    end