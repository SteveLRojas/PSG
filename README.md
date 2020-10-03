# PSG
Digital PSG designed to be implemented on a CPLD or FPGA.  
This is a programmable sound generator written in verilog. It has 3 independendent channels and uses 10 bit PWM modules to generate the audio outputs.  
The first channel can generate triangle, pulse, and noise waveforms. The second channel can generate sawtooth and pulse waveforms, and the third cahannel can generate sine waves or play 8 bit samples.  
Each channel has 4 PWM outputs that can be enabled independently as a way of controlling the channel volume.  
NOTE: This design assumes that a global reset will be enabled in the CPLD. The device MUST be reset at startup to ensure correct operation.  
