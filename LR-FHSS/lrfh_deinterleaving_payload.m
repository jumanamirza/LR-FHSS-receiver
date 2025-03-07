function [deint_payload]= lrfh_deinterleaving_payload(payload,data_in_bitcount)
%payload=[0 12 24 3 15 27 6 18 30 9 21 33 1 13 25 4 16 28 7 19 31 10 22 34 2 14 26 5 17 29 8 20 32 11 23 35];
%data_in_bitcount = 36;
%payload=[0 14 28 42 3 17 31 45 6 20 34 48 9 23 37 51 12 26 40 1 15 29 43 4 18 32 46 7 21 35 49 10 24 38 52 13 27 41 2 16 30 44 5 19 33 47 8 22 36 50 11 25 39 53];
%data_in_bitcount = 54;
%payload=[0 14 28 42 3 17 31 45 6 20 34 48 9 23 37 51 12 26 40 54 1 15 29 43 4 18 32 46 7 21 35 49 10 24 38 52 13 27 41 55 2 16 30 44 5 19 33 47 8 22 36 50 11 25 39 53 ];
%data_in_bitcount = 56;
%step = floor( sqrt( data_in_bitcount ) );
y = 0;
while y * y < data_in_bitcount 
    y = y + 1;
end
step=y;
step_v = floor(bitsra(step ,1));
step = bitshift(step ,1);
st_idx = 0;
st_idx_init = 0;
pos=0;
deint_payload=zeros(length(payload),1);
%deint_payload(1)=payload(1);
for i=2:length(payload)
    pos=pos+step;
    if pos >= data_in_bitcount 
       st_idx = st_idx + step_v;
       if st_idx >= step        
          st_idx_init=st_idx_init+1;
          st_idx = st_idx_init;
       end
       pos = st_idx;
    end
    deint_payload(pos)=payload(i);
end
deint_payload(2:end)=deint_payload(1:end-1);
deint_payload(1)=payload(1);
end