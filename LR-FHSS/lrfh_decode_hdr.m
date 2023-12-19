function [decoded_hdr, decoded_hdr_info]=lrfh_decode_hdr(deint_header, myTrellis)

    decoded_hdr = [];
    decoded_hdr_info.CRCpass = 0;

    decodescores = zeros(myTrellis.numStates,2);
    alltryres = cell(1,myTrellis.numStates);
    for idx=1:myTrellis.numStates
        [this_decoded_hdr,match,min_cost] = vit_decode(idx-1,deint_header,myTrellis);
        decodescores(idx,:) = [match,min_cost];
        alltryres{idx} = this_decoded_hdr;
    end
    allpassidx = find(decodescores(:,1)==1); allfailidx = find(decodescores(:,1)==0);
    if length(allpassidx)
        decodescores(allfailidx,2) = 10000;
        [min_cost_val,min_cost_idx] = min(decodescores(:,2));
        decoded_hdr = alltryres{min_cost_idx};
        decoded_hdr_info.CRCpass = 1;
        decoded_hdr_info.payloadlen =  bi2de(decoded_hdr(1:8),'left-msb');
        decoded_hdr_info.modulation = decoded_hdr(9:11);
        decoded_hdr_info.CR = bi2de(decoded_hdr(12:13),'left-msb');
        decoded_hdr_info.grid = decoded_hdr(14);
        decoded_hdr_info.hop = decoded_hdr(15);
        decoded_hdr_info.BW = decoded_hdr(16:19);
        decoded_hdr_info.hopseq = decoded_hdr(20:28);
        decoded_hdr_info.syncindex = sum(decoded_hdr(29:30).*[2,1]);
        decoded_hdr_info.syncindexbit = decoded_hdr(29:30);
        decoded_hdr_info.futureuse = decoded_hdr(31:32);
        decoded_hdr_info.CRC = decoded_hdr(33:end);
        decoded_hdr_info.state = min_cost_idx;
        decoded_hdr_info.min_cost = min_cost_val;  
    else
        [min_cost_val,min_cost_idx] = min(decodescores(:,2));
        decoded_hdr = alltryres{min_cost_idx};
        decoded_hdr_info.CRCpass = 0;
        decoded_hdr_info.state = min_cost_idx;
        decoded_hdr_info.min_cost = min_cost_val;          
    end
end

function [data_out,match,min_cost]= vit_decode(state,data,myTrellis)
    len = length(data)/2 ;
    cost_string=ones(16,3)*1000; cost_string(state+1,2:3) = 0;
    decoded_string = zeros(16,len);
    new_decoded_string = zeros(16,len);
    outbitsvals = [
     0     0;
     0     1;
     1     0;
     1     1
     ];
    for i=1:len
        thisrcv = data(i*2-1:i*2);
        costvals = zeros(1,4);
        for val=0:3
            costvals(val+1) = cal_Distance(outbitsvals(val+1,:), thisrcv, 1);
        end
        for h=1:8
            for hh=1:2
                t1 = cost_string(h,2) + costvals(myTrellis.outputs(h,hh)+1);
                t2 = cost_string(h+8,2) + costvals(myTrellis.outputs(h+8,hh)+1);
                if t1<t2  
                    newcost = t1;
                    newstr = [decoded_string(h,1:i-1),hh-1];
                else
                    newcost = t2;
                    newstr = [decoded_string(h+8,1:i-1),hh-1];
                end   
                cost_string((h-1)*2+hh,3) = newcost; 
                new_decoded_string((h-1)*2+hh,1:i) = newstr;
            end
        end          
        cost_string(:,2) = cost_string(:,3);
        decoded_string = new_decoded_string;
    end
    [min_cost,ind] = min(cost_string(:,2));
    data_out = decoded_string(ind,:);
    match =0;
    if len==40
        crc = lrfh_crc8(data_out(1:32));
        match = isequal(crc,data_out(33:end));
    end
end
