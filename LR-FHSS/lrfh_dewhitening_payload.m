function [data_out]=lrfh_dewhitening_payload(data_in,data_in_bytecount)
    lfsr = [1 1 1 1 1 1 1 1];
    for index = 1:data_in_bytecount
        data_out((index-1)*8+1:index*8-4)= data_in((index-1)*8+5:index*8);
        data_out((index-1)*8+5:index*8)  = data_in((index-1)*8+1:index*8-4);
        data_out((index-1)*8+1:index*8) =  bitxor(data_out((index-1)*8+1:index*8), lfsr);
        lfsr = [lfsr(2:8) bitxor(lfsr(1), bitxor(lfsr(3), bitxor(lfsr(4),lfsr(5)) ) )];    
    end
end