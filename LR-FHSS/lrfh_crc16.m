function [crc]= lrfh_crc16(decoded)
lr_fhss_payload_crc16_lut = [0, 30043, 60086, 40941, 41015, 54636, 19073, 16346, 13621, 16494, 57219, 43736, 38146, 57433, 32692, 2799, 27242, 7985,  32988, 62855, 51805, 48902, 8427,  21936, 24415, 10756, 46569, 49330, 65384, 35379, 5598,  24709, 54484, 41359, 15970, 19257, 29923, 440,   40533, 60174, 57825, 38074, 2903,  32268, 16854, 13453, 43872, 56891, 48830, 52197, 21512, 8531,  7817,  27602, 62527, 33124, 35723, 65232, 24893, 5222,  11196, 24295, 49418, 46161, 56563, 43432, 13893, 17182, 31940, 2463,  38514, 58153, 59846, 40093, 880,   30251, 18929, 15530, 41799, 54812, 46745, 50114, 23599, 10612, 5806,  25589, 64536, 35139, 33708, 63223, 26906, 7233,  9115,  22208, 51501, 48246, 2087,  32124, 58001, 38858, 43024, 56651, 17062, 14333, 15634, 18505, 55204, 41727, 40229, 59518, 30611, 712, 25165, 5910,  35067, 64928, 49786, 46881, 10444, 23959, 22392, 8739,  48590, 51349, 63311, 33300, 7673,  26786, 52413, 47590, 9739,  21328, 27786, 6609,  34364, 62311, 63880, 36051, 4926,  26213, 22975, 11492, 45833, 50770, 42711, 54156, 19553, 14650, 1760,  29627, 60502, 39181, 37858, 59065, 31060, 3087,  13269, 18062, 55651, 44088, 6249,  27954, 62175, 34692, 47198, 52485, 21224, 10163, 11612, 22535, 51178, 45745, 36203, 63536, 26589, 4742, 29187, 1880,  39093, 60910, 53812, 42863, 14466, 19929, 18230, 12909, 44416, 55515, 59137, 37466, 3511,  30956, 4174,  25877, 64248, 36771, 45177, 50466, 23247, 12180, 9595,  20512, 53197, 47766, 34124, 61463, 28666, 6817, 31268, 3967,  37010, 58825, 55827, 44872, 12453, 17918, 20241, 14922, 42407, 53500, 61222, 39549, 1424,  28875, 50330, 45505, 11820, 23415, 25773, 4598,  36379, 64320, 61871, 34036, 6937,  28226, 20888, 9411,  47918, 52853, 44784, 56235, 17478, 12573, 3783,  31644, 58481, 37162, 39877, 61086, 29043, 1064,  15346, 20137, 53572, 42015 ];

    crc = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
    for k = 0:length(decoded)/8-1
        pos =bi2de( bitxor( crc(1:8) , decoded(k*8+1:k*8+8) ),'left-msb')+1;
        crc        = bitxor( [crc(9:16) 0 0 0 0 0 0 0 0] ,de2bi(lr_fhss_payload_crc16_lut(pos),16,'left-msb'));
    end
end