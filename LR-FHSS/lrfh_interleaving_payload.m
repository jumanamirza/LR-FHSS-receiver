function [data_out]= lrfh_interleaving_payload(data)
data_in_bitcount=length(data);
step = ceil( sqrt( data_in_bitcount ) );
step_v = floor(bitsra(step ,1));
step = bitshift(step ,1);
st_idx = 1;
st_idx_init = 1;
pos=1;
bits_left=data_in_bitcount;
data_out=zeros(length(data),1);
shift=0;
  while bits_left > 0
      in_row_width = bits_left;        
        if in_row_width > 48             
            in_row_width = 48;         
        end     
        for j =1:in_row_width                                     
            data_out(j+shift)= data(pos);             
            pos = pos+ step;            
            if pos > data_in_bitcount                                      
                st_idx = st_idx+ step_v;                
                if st_idx > step                  
                    st_idx_init=st_idx_init+1;                    
                    st_idx = st_idx_init;                   
                end                
                pos = st_idx;            
            end           
        end       
        bits_left = bits_left- 48;           
        shift=shift+48;
  end
data_out=data_out.';
end
