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


function [data_out,match,min_cost]= vit_decode_payload(state,vals,myTrellis,CR)
    vitusesoft_flag = 1;
    vals = vals.';
    
    if CR==3 
        k=3; 
    elseif CR==2 
        k=2; 
    elseif CR==1 
        k=3/2; 
    elseif CR==0 
        k=6/5; 
    end
    
    cost_string = zeros(64,3); cost_string(2:end,2) = 10000; 
    decoded_string = zeros(64,floor(length(vals)/k ));
    new_decoded_string = zeros(64,floor(length(vals)/k));
    
    for i=1:floor(length(vals)/k)
    
        if CR==3 
            r=vals(i*3-2:i*3); sh=0; len=3;
        elseif CR==2 
            r=vals(i*2-1:i*2); sh=1; len=2;
        elseif CR==1 
            if mod(i,2)==1 %odd
                r=vals((i-1)/2*3+1:(i-1)/2*3+2); sh=1; len=2;
            else %even
                r=vals((i-2)/2*3+3); sh=1; len=1;
            end
        elseif CR==0
            if mod(i,5)==0
               r=vals(i/5*6); sh=2; len=1;  
            elseif mod(i,5)==1
               r=vals((i-1)/5*6+1:(i-1)/5*6+2); sh=1; len=2; 
            elseif mod(i,5)==2
               r=vals((i-2)/5*6+3); 
            elseif mod(i,5)==3
               r=vals((i-3)/5*6+4); sh=2; len=1;
            elseif mod(i,5)==4
               r=vals((i-4)/5*6+5);  
            end
        end
    
        for h=1:32
            for hh=1:2
                if (CR==1 && mod(i,2)==0) || (CR==0 && mod(i,5)==2) || (CR==0 && mod(i,5)==4)
                    num=de2bi(myTrellis.outputs(h,hh),3,'left-msb');
                    num=num(2);
                    t1=cost_string(h,2)+cal_Distance( num , r, vitusesoft_flag );
                    num=de2bi(myTrellis.outputs(h+32,hh),3,'left-msb');
                    num=num(2);
                    t2=cost_string(h+32,2)+cal_Distance( num , r, vitusesoft_flag);
                else
                    t1=cost_string(h,2)+cal_Distance(de2bi(floor(bitsra(myTrellis.outputs(h,hh),sh)),len,'left-msb'),r, vitusesoft_flag);
                    t2=cost_string(h+32,2)+cal_Distance(de2bi(floor(bitsra(myTrellis.outputs(h+32,hh),sh)),len,'left-msb'),r, vitusesoft_flag);
                end
                if t1<t2  
                    newcost = t1;
                    newstr = [decoded_string(h,1:i-1), hh-1];
                else
                    newcost = t2;
                    newstr = [decoded_string(h+32,1:i-1), hh-1];
                end
                cost_string((h-1)*2+hh,3) = newcost;
                new_decoded_string((h-1)*2+hh,1:i) = newstr;
            end
        end       
    
        cost_string(:,2)=cost_string(:,3);
        decoded_string = new_decoded_string;
    end
    
    data_out_all = decoded_string(1,1:end-6);
    crc = lrfh_crc16(data_out_all(1:end-16));
    match = isequal(crc,data_out_all(end-15:end));
    data_out = data_out_all(1,1:end-16);
    min_cost = cost_string(1,2);
end