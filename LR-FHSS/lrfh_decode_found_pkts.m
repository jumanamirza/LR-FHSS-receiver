% Copyright (C) 2025 
% Florida State University 
% All Rights Reserved

function [outFoundDataSeg, LRFHSS_recon_time_sig] = lrfh_decode_found_pkts(FoundDataSeg,LRFHSS_time_sig,LRF_cfg)

LRFHSS_recon_time_sig = zeros(size(LRFHSS_time_sig));
save_reconsig_flag = (length(FoundDataSeg) <= 2) && LRF_cfg.check_SIC_flag; 
orig_LRFHSS_time_sig = LRFHSS_time_sig;

allpktpower = zeros(1,length(FoundDataSeg));
for pktidx=1:length(FoundDataSeg)
    % fprintf(1, 'pkt %d: %f\n', pktidx, FoundDataSeg{pktidx}.estpower)
    allpktpower(pktidx) = FoundDataSeg{pktidx}.estpower;
end
[a,decodeorder] = sort(allpktpower, 'descend');
trieddecoding_flag = zeros(1,length(decodeorder));

reconphdrsig = cell(1,length(decodeorder)); % reconphdrsig{pktidx}: hdr sig for packet pktidx
for pktidxidx=1:length(decodeorder)
    thishdrreconsig = zeros(size(LRFHSS_time_sig));
    thisreconstart = size(LRFHSS_time_sig,2);
    thisreconend = 1;
    pktidx = decodeorder(pktidxidx);
    thispkt = FoundDataSeg{pktidx};
    thishdrsdata = zeros(thispkt.header_count,40);
    gotflag = zeros(1,thispkt.header_count);
    gotstate = zeros(1,thispkt.header_count);
    for hdridx=1:thispkt.header_count
        if ~isempty(thispkt.headerinfo{hdridx})
            thishdrsdata(hdridx,:) = thispkt.headerinfo{hdridx}.decode;
            gotflag(hdridx) = 1;
            gotstate(hdridx) = thispkt.headerinfo{hdridx}.info.state-1; 
        end
    end
    if sum(gotflag) < thispkt.header_count
        gotidx = find(gotflag);
        vals = thishdrsdata(gotidx(1),:);
        missidx = find(gotflag == 0);
        for zzz=1:length(missidx)
            thishdridx = missidx(zzz);
            thishdrsdata(thishdridx,:) = vals;
            thishdrrevidx = thispkt.header_count - thishdridx + 1;
            if thishdrrevidx == 3
                syncbits = [1 0];
            elseif thishdrrevidx == 2
                syncbits = [0 1];
            else                
                syncbits = [0 0];
            end
            thishdrsdata(thishdridx,29:30) = syncbits;
            tempp = lrfh_crc8(thishdrsdata(thishdridx,1:32));
            thishdrsdata(thishdridx,33:end) = tempp;
        end
    end
    for hdridx=1:thispkt.header_count
        if hdridx == 1
            hereaddnum = 3;
            hereaddpad = [0 0 0];
            hereaddpad_tail = [0];
        else
            hereaddnum = 0;
            hereaddpad = [];
            hereaddpad_tail = [0];
        end
        thisbgn = thispkt.start - (thispkt.header_count - hdridx + 1) * LRF_cfg.staysmplnum_hdr - LRF_cfg.smblsmplnum * hereaddnum;
        thisend = thisbgn + LRF_cfg.staysmplnum_hdr - 1 + LRF_cfg.smblsmplnum * (hereaddnum+1);
        orig_sig = LRFHSS_time_sig(:, thisbgn:thisend);
        thisreconbits = lrfh_gen_hdr_bits(gotstate(hdridx), thishdrsdata(hdridx,:), LRF_cfg, gotflag(hdridx));
        [thisreconfragsig, thispara] = lrfh_reconsig([hereaddpad,thisreconbits,hereaddpad_tail], orig_sig, thispkt.freq_header_Hz(hdridx), LRF_cfg);
        if hdridx == 1
            thisreconfragsig(:,1:LRF_cfg.smblsmplnum*2) = 0;
        end
        cuttaillen = LRF_cfg.smblsmplnum*1;
        thishdrreconsig(:,thisbgn:thisend-cuttaillen) = thisreconfragsig(:,1:end-cuttaillen);
        thispkt.hdrreconinfo{hdridx} = thispara;
        thisreconstart = min(thisreconstart, thisbgn);
        thisreconend = max(thisreconend, thisend);
    end
    reconphdrsig{pktidx}.start = thisreconstart;
    reconphdrsig{pktidx}.end = thisreconend;
    reconphdrsig{pktidx}.sig = thishdrreconsig(:,thisreconstart:thisreconend);
    LRFHSS_time_sig = LRFHSS_time_sig - thishdrreconsig;
    FoundDataSeg{pktidx} = thispkt;
end

for pktidxidx=1:length(decodeorder)
    pktidx = decodeorder(pktidxidx);
    trieddecoding_flag(pktidx) = 1;

    thispkt = FoundDataSeg{pktidx};
    thispkt.CRCpass = 0;
    thispkt.decoderes = [];

    thisFragment = []; data = []; GMSKdemodvaladj = [];
    thiscolinfo = thispkt.detailedcolinfo;
    for fragmentidx=1:thispkt.num_frags
        thisFrgTime = thispkt.SegCoarseTime(fragmentidx, :);
        herepassoverlapinfo = thispkt.overlapinfo{fragmentidx};
        thisinterfP = zeros(1,length(thispkt.overlapinfo{fragmentidx}.thistimeidx));
        for h=1:length(thiscolinfo)
            if thiscolinfo{h}.own_fgidx == fragmentidx
                pktidx2 =  thiscolinfo{h}.col_pkt_idx;
                pkt2_hdrdataidx = thiscolinfo{h}.col_pkt_hdrorfg; % 1: header, 2: data frag
                pkt2_segidx = thiscolinfo{h}.col_pkt_segidx; 
                pkt2_overlapinthatfgidx = thiscolinfo{h}.col_pkt_symidx; 
                overlapinfgidx = thiscolinfo{h}.overlapinfgidx;
                interP = thiscolinfo{h}.interP; 
                pkt2_para = [];
                if pkt2_hdrdataidx == 1
                    pkt2_para = FoundDataSeg{pktidx2}.hdrreconinfo{pkt2_segidx};
                else
                    if FoundDataSeg{pktidx2}.CRCpass
                        pkt2_para = FoundDataSeg{pktidx2}.datareconinfo{pkt2_segidx};
                    end
                end
                if ~isempty(pkt2_para)
                    if 1 % no differnece, still use this one because morally correct
                        srnvals = pkt2_para.reconsnr(intersect(pkt2_overlapinthatfgidx,[1:length(pkt2_para.reconsnr)]));
                        srnvals(srnvals>10) = 10;
                        usesnr = mean(srnvals);
                        otherP = interP/usesnr; 
                        adjinterP = otherP/LRF_cfg.recon_seg_len_symbol_num; 
                    else
                        adjinterP = interP/LRF_cfg.recon_seg_len_symbol_num;
                    end
                else
                    adjinterP = interP;
                end
                thisinterfP(overlapinfgidx) = thisinterfP(overlapinfgidx) + adjinterP;
            end
            herepassoverlapinfo.invSIR = thisinterfP/thispkt.estpower; % NOTE: just need to update this one, other fields not needed
        end
        [thisFragment{fragmentidx}, GMSKdemodvaladj(fragmentidx)] = lrfh_demodulate_payload(LRFHSS_time_sig, thisFrgTime, thispkt.freq_Hz(fragmentidx), LRF_cfg, thispkt.num_bits_frags(fragmentidx)+1, herepassoverlapinfo, thispkt.estpower, thispkt.CR);
        if length(thisFragment{fragmentidx}.bits) ~= thispkt.num_bits_frags(fragmentidx)+2
            data = [data thisFragment{fragmentidx}.bits(2:end)];
        else
            data = [data thisFragment{fragmentidx}.bits(3:end)]; 
        end
    end
    if ~(length(data) <= 66 &&  thispkt.CR == 3)
        data(isnan(data)) = 0;
        thisdecoderes.bits = data;
        thisdecoderes.deint = lrfh_deinterleaving_payload(thisdecoderes.bits, thispkt.data_in_bitcount);
        [a,b,c] = lrfh_decode_payload(thisdecoderes.deint, thispkt.CR, LRF_cfg);
        thisdecoderes.decode = a;
        thisdecoderes.CRCpass = b;
        thisdecoderes.cost = c;
        thisdecoderes.dewhitening = lrfh_dewhitening_payload(thisdecoderes.decode,length(thisdecoderes.decode)/8);
        tempp = reshape(thisdecoderes.dewhitening,8,length(thisdecoderes.dewhitening)/8)';
        thisdecoderes.foundpayload = bi2de(tempp,"left-msb");
    
        thispkt.CRCpass = thisdecoderes.CRCpass;
        thispkt.decoderes = thisdecoderes;
        thispkt.dataGMSKdemodvaladj = GMSKdemodvaladj;
    end

    if thispkt.CRCpass
        fprintf(1,'pkt %d: CR %d, CRC PASS, cost %.2f, data [', pktidx, thispkt.CR, thispkt.decoderes.cost);
        for h=1:length(thispkt.decoderes.foundpayload)
            fprintf(1, '%.2x', thispkt.decoderes.foundpayload(h));
            if h < length(thispkt.decoderes.foundpayload)
                fprintf(1,', ');
            else
                fprintf(1,'], ');
            end
        end
        fprintf(1,'freq adj header [');
        for h=1:length(thispkt.headerinfo)
            if ~isempty(thispkt.headerinfo{h})
                fprintf(1, '%.2f', thispkt.headerinfo{h}.GMSKdemodvaladj);
            else
                fprintf(1, '-');
            end
            if h < length(thispkt.headerinfo)
                fprintf(1,', ');
            else
                fprintf(1,'], ');
            end
        end
        fprintf(1,'data [');
        for h=1:length(thispkt.dataGMSKdemodvaladj)
            fprintf(1, '%.2f', thispkt.dataGMSKdemodvaladj(h));
            if h < length(thispkt.dataGMSKdemodvaladj)
                fprintf(1,', ');
            else
                fprintf(1,']\n');
            end
        end
    else
        fprintf(1,'pkt %d: CRC FAIL\n', pktidx);
    end

    if thispkt.CRCpass
        reconfrags = lrfh_gen_data_frag_bits(thispkt,LRF_cfg);
        recondatasig = zeros(size(LRFHSS_time_sig,1), length(reconfrags)*LRF_cfg.staysmplnum_data);
        hereaddnum_head = 0; hereaddnum_tail = 0;
        for fgidx=1:length(reconfrags)
            orig_sig = LRFHSS_time_sig(:, thispkt.SegCoarseTime(fgidx,1)-hereaddnum_head*LRF_cfg.smblsmplnum:thispkt.SegCoarseTime(fgidx,2)+hereaddnum_tail*LRF_cfg.smblsmplnum);
            [thisreconfragsig, thispara] = lrfh_reconsig([reconfrags{fgidx}.bits(1:end)], orig_sig, thispkt.freq_Hz(fgidx), LRF_cfg);
            thisbgn = thispkt.SegCoarseTime(fgidx,1)-thispkt.start+1;
            thisend = thisbgn + size(thisreconfragsig,2) - 1;
            recondatasig(:,thisbgn:thisend) = thisreconfragsig;
            thispkt.datareconinfo{fgidx} = thispara;
        end
        thisbgn = thispkt.start - hereaddnum_head*LRF_cfg.smblsmplnum;
        thisend = thisbgn + size(recondatasig,2) - 1;
        thisreconsig = zeros(size(LRFHSS_time_sig));
        thisreconsig(:,thisbgn:thisend) = recondatasig;
        LRFHSS_time_sig = LRFHSS_time_sig - thisreconsig;
        thisreconsig(:,reconphdrsig{pktidx}.start:reconphdrsig{pktidx}.end) = reconphdrsig{pktidx}.sig;
        LRFHSS_recon_time_sig = LRFHSS_recon_time_sig + thisreconsig;
        if save_reconsig_flag
            thispkt.reconsig = thisreconsig;
            thispkt.reconstart = reconphdrsig{pktidx}.start;
            thispkt.reconend = thisend;
        end
    end
    FoundDataSeg{pktidx} = thispkt;

end
outFoundDataSeg = FoundDataSeg;