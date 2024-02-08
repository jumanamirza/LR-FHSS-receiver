function [decoded_pay,match,min_cost]=lrfh_decode_payload(deint_payload,CR_de, LRF_cfg)
    deint_payload(deint_payload<-1)=-1;
    deint_payload(deint_payload>1)=1;
    deint_payload_quant = min(127,round(128.0*deint_payload))+128;
    
    tbdepth = 66;
    if CR_de == 3
        decoded_pay = vitdec(deint_payload_quant,LRF_cfg.myTrellis,tbdepth,'term','soft',8);
    elseif CR_de == 1
        puncpat = [1 1 0 0 1 0];
        decoded_pay = vitdec(deint_payload_quant,LRF_cfg.myTrellis,tbdepth,'term','soft',8,puncpat);
    end

    crc=lrfh_crc16(decoded_pay(1:end-16-6).');
    match=isequal(crc.',decoded_pay(end-15-6:end-6));  
    decoded_pay = decoded_pay(1:end-16-6);
    min_cost = 0;

end
