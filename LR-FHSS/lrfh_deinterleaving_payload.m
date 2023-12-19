function [deint_payload]= lrfh_deinterleaving_payload(payload,data_in_bitcount)
y = 0;
while y * y < data_in_bitcount 
    y = y + 1;
end
step=y;
t = de2bi(step,8,'left-msb'); 
step_v = bi2de( t(1:end-1),'left-msb');
step = bitshift(step ,1);
st_idx = 0;
st_idx_init = 0;
pos=0;
deint_payload=zeros(length(payload),1);
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