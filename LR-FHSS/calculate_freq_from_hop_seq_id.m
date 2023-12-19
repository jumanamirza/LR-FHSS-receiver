function [freq] = calculate_freq_from_hop_seq_id(grid, enable_hop, header_count, BW, hop_seq_id, num_frag)
current_hop = 0;
[status,n_grid,lfsr_state,polynomial,xoring_seed,hop_seq_id] = lr_fhss_get_hop_params( grid, BW, hop_seq_id );
if status == 0 %LR_FHSS_STATUS_OK 
    % Skip the hop frequencies inside the set [0, 4 - header_count): 
    if enable_hop ~= 0 
        for i = 0:4-header_count-1
            [hop, lfsr_state]=lr_fhss_get_next_state(lfsr_state, n_grid,polynomial,xoring_seed );
            
        end
    end
    freq=[];
    for idx=1:num_frag+header_count
        [next_freq_in_pll_steps,lfsr_state] = sx126x_lr_fhss_get_next_freq_in_pll_steps( lfsr_state, grid, n_grid, enable_hop, polynomial, xoring_seed, hop_seq_id,current_hop, header_count )  ; 
        freq = [ freq next_freq_in_pll_steps ];
        current_hop=current_hop+1;
    end
    
end
end
%------------------------------------------
function [status,n_grid,initial_state,polynomial,xoring_seed,hop_sequence_id_de]=lr_fhss_get_hop_params( grid, bw, hop_sequence_id )
lr_fhss_channel_count =[ 80, 176, 280, 376, 688, 792, 1480, 1584, 3120, 3224 ];
lr_fhss_lfsr_poly1 = [ 33, 45, 48, 51, 54, 57 ];
lr_fhss_lfsr_poly2 = [ 65, 68, 71, 72 ];
lr_fhss_lfsr_poly3 = [ 142, 149 ];

channel_count = lr_fhss_channel_count(bi2de( bw,'left-msb')+1);

if grid == 1
    n_grid = channel_count / 8;
else
    n_grid = channel_count / 52;
end

hop_sequence_id_de=bi2de( hop_sequence_id,'left-msb');
xoring_seed=zeros(1,16);
switch n_grid 
    case {10, 22, 28, 30, 35, 47}
        initial_state          = 6;
        polynomial  = lr_fhss_lfsr_poly1( bi2de( hop_sequence_id(1:3),'left-msb') +1 );
        xoring_seed(end-5:end) = hop_sequence_id(4:9);
        status= 0;%LR_FHSS_STATUS_OK;
        if hop_sequence_id_de >= 384 
            status= 3;%LR_FHSS_STATUS_ERROR;
        end       
    case {60, 62}
        initial_state          = 56;
        polynomial  = lr_fhss_lfsr_poly1( bi2de( hop_sequence_id(1:3),'left-msb') +1 );
        xoring_seed(end-5:end) = hop_sequence_id(4:9);
        status= 0;%LR_FHSS_STATUS_OK;
        if hop_sequence_id_de >= 384 
            status= 3;%LR_FHSS_STATUS_ERROR;
        end  
    case {86, 99}
        initial_state          = 6;
        polynomial  = lr_fhss_lfsr_poly2( bi2de( hop_sequence_id(1:2),'left-msb') +1 );
        xoring_seed(end-6:end) = hop_sequence_id(3:9);
        status= 0;%LR_FHSS_STATUS_OK;
    case {185, 198}
        initial_state          = 6;
        polynomial  = lr_fhss_lfsr_poly3( bi2de( hop_sequence_id(1),'left-msb') +1 );
        xoring_seed(end-7:end) = hop_sequence_id(2:9);
        status= 0;%LR_FHSS_STATUS_OK;
    case {390, 403}
        initial_state          = 6;
        polynomial  = 264;
        xoring_seed(end-8:end) = hop_sequence_id;
        status= 0;%LR_FHSS_STATUS_OK;
    otherwise
        status= 3;%LR_FHSS_STATUS_ERROR;
end

initial_state=de2bi(initial_state,16,'left-msb');
polynomial=de2bi(polynomial,16,'left-msb');
end
%------------------------------------------
function [hop, lfsr_state]= lr_fhss_get_next_state(lfsr_state, n_grid, polynomial, xoring_seed)
    while 1
        lsb = bitand(lfsr_state(end), 1);
        lfsr_state(2:end)=lfsr_state(1:end-1);
        lfsr_state(1)=0;
        if lsb
            lfsr_state =bitxor(lfsr_state,polynomial);
        end
        hop = xoring_seed;
        if ~isequal(hop, lfsr_state) 
            hop =bitxor(hop, lfsr_state);
        end
        if bi2de( hop,'left-msb') <= n_grid 
            break;
        end
    end
    
    hop= bi2de( hop,'left-msb') - 1;
end
%------------------------------------------
function [freq, lfsr_state]= sx126x_lr_fhss_get_next_freq_in_pll_steps(lfsr_state, grid, n_grid, enable_hop, polynomial, xoring_seed, hop_sequence_id,current_hop, header_count )

[freq_table,lfsr_state] =lr_fhss_get_next_freq_in_grid(enable_hop, lfsr_state, n_grid, polynomial, xoring_seed, hop_sequence_id );
    
if grid ==1
    nb_channel_in_grid = 8;
else
    nb_channel_in_grid = 52;
end
grid_offset = (1 + mod(n_grid, 2 )) * ( nb_channel_in_grid / 2 );
center_freq_in_pll_steps= 910163968; 
grid_in_pll_steps = sx126x_lr_fhss_get_grid_in_pll_steps( grid );
freq = - freq_table * grid_in_pll_steps -( 0 + grid_offset ) * 512;
    
               
if 1
    % Perform frequency correction for every other sync header
    if enable_hop && ( current_hop < header_count ) 
        if  mod( ( header_count - current_hop ) , 2 ) == 0 
            freq = freq + 256;
        end
    end
end

end

%------------------------------------------
function [PLL_STEPS] = sx126x_lr_fhss_get_grid_in_pll_steps( grid )
if grid ==1
    PLL_STEPS = 4096;
else
    PLL_STEPS = 26624;
end
end
%------------------------------------------
function [n_i,lfsr_state]= lr_fhss_get_next_freq_in_grid(enable_hop, lfsr_state, n_grid, polynomial, xoring_seed, hop_sequence_id )
    sign=0;
    if enable_hop
        [n_i, lfsr_state] = lr_fhss_get_next_state( lfsr_state, n_grid, polynomial, xoring_seed );
    else
        n_i = mod(hop_sequence_id, n_grid);
    end

    t = de2bi(n_grid,8,'left-msb'); 
    if n_i >= bi2de( t(1:end-1),'left-msb')
        n_i = n_i - n_grid; 
    end
end
%------------------------------------------
