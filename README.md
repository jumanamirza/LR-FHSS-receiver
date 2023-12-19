Long-Range Frequency Hopping Spread Spectrum (LR-FHSS) receiver that able to decode LR-FHSS packets 
Long Range-Frequency Hopping Spread Spectrum (LR-FHSS) is a new physical layer option that has been recently added to the LoRa family with the promise of achieving much higher network capacity than the previous versions of LoRa.

LR-FHSS-receiver is capable of decoding LR-FHSS packets transmitted by sx126x or lr1110 devices.

This webpage contains the source code of LR-FHSS-receiver written in Matlab. 

To test it, you may download the trace files collected in our experiments and feed the trace to LR-FHSS-receiver as input, or collect and use your own traces. 
Our trace files can be downloaded from “pkttrace” folder.

To run LR-FHSS-receiver, MATLAB R2021b or above is needed, along with the following toolboxes: Communications Toolbox, Signal Processing Toolbox and DSP System Toolbox. 

Our trace files were collected using sx126x device and from two different data rate which are DR 8 and DR 9. For each DR, 100 traces have been uploaded, name of traces range between 1 to 500 for DR8 and between 501 to 1000 for DR9. Each trace file contains 1 packet where the payload length size range between 8-16 bytes.

To run LR-FHSS-receiver, after downloading the source file, there should a directory, named LRFHSS, which is the source code directory. The main file, named lrfh_sim.m, can be found under the LRFHSS directory. The trace data should be downloaded to another directory, which can be called pkttrace and can be at the same level as LRFHSS. You may then simply open Matlab, go to the LRFHSS directory, and type “lrfh_sim” in the command window.

To test different traces, you may open lrfh_sim.m and modify two variables. One is to select the trace, such as: lrfh_sim_config.USE_FILE_IDX = 1; and the other is to set the corresponding Data Rate, such as: lrfh_sim_config.drsel = LRF_cfg.CONST_use_DR8; After the program finishes, the content of packets is printed, such as: [ca, c4, 24, 6a, 92, 36, d4, 58, 20, 08, 10, b4, 36, b2, 8e, 02] 
