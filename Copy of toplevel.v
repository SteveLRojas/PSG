module top_level(input wire clk, input wire[7:0] data, input wire[2:0] address, input wire wr, output wire[3:0] ch0_audio, ch1_audio);
reg[9:0] active_sample0;
reg[9:0] active_sample1;
wire[9:0] triangle_sample;
wire[9:0] sawtooth_sample;
wire[9:0] noise_sample;
wire[9:0] ch0_pulse_sample;
wire[9:0] ch1_pulse_sample;
wire channel0_clk;
reg[7:0] ch0_freq;
reg[7:0] ch0_p_vol;
reg[7:0] ch0_duty;
reg[5:0] ch0_ctrl;
reg[7:0] ch1_freq;
reg[7:0] ch1_p_vol;
reg[7:0] ch1_duty;
reg[4:0] ch1_ctrl;

always @(posedge clk)
begin
	if(wr)
	begin
		case(address)
		3'b000: ch0_freq <= data;
		3'b001: ch0_p_vol <= data;
		3'b010: ch0_duty <= data;
		3'b011: ch0_ctrl <= data[5:0];
		3'b100: ch1_freq <= data;
		3'b101: ch1_p_vol <= data;
		3'b110: ch1_duty <= data;
		3'b111: ch1_ctrl <= data[4:0];
		endcase
	end
end

always @(*)
begin
	case(ch0_ctrl[5:4])
	2'b00: active_sample0 = 10'h00;
	2'b01: active_sample0 = triangle_sample;
	2'b10: active_sample0 = noise_sample;
	2'b11: active_sample0 = ch0_pulse_sample;
	endcase
	if(ch1_ctrl[4])
		active_sample1 = sawtooth_sample;
	else
		active_sample1 = ch1_pulse_sample;
end

clock_synth csynth0(.clk(clk), .freq(ch0_freq), .channel_clk(channel0_clk));
DAC DAC0_inst(.sample(active_sample0), .clk(clk), .vol(ch0_ctrl[3:0]), .audio(ch0_audio));
triangle_synth tsynth0(.clk(clk), .t_clk(channel0_clk), .triangle(triangle_sample));
pulse_synth psynth0(.duty(ch0_duty), .triangle(triangle_sample[9:2]), .p_vol(ch0_p_vol), .pulse(ch0_pulse_sample));
noise_synth nsynth0(.clk(clk), .noise_clk(channel0_clk), .noise_sample(noise_sample));

clock_synth cdynth1(.clk(clk), .freq(ch1_freq), .channel_clk(channel1_clk));
DAC DAC1_inst(.sample(active_sample1), .clk(clk), .vol(ch1_ctrl[3:0]), .audio(ch1_audio));
sawtooth_synth ssynth1(.clk(clk), .s_clk(channel1_clk), .sawtooth(sawtooth_sample));
pulse_synth psynth1(.duty(ch1_duty), .triangle(sawtooth_sample[9:2]), .p_vol(ch1_p_vol), .pulse(ch1_pulse_sample));

endmodule

module DAC(input wire[9:0]sample, input wire clk, input wire[3:0] vol, output wire[3:0] audio);
reg[9:0] DAC_counter;
reg comp_out;
assign audio = vol & {4{comp_out}};
always @(posedge clk)
begin
	DAC_counter <= DAC_counter + 10'd1;
end

always @(*)
begin
	comp_out = 1'b0;
	if(sample > DAC_counter)
		comp_out = 1'b1;
end
endmodule

module clock_synth(input wire clk, input wire[7:0] freq, output reg channel_clk);
reg[7:0] clk_count;
always @(posedge clk)
begin
	if(clk_count == freq)
	begin
		channel_clk <= 1'b1;
		clk_count <= 8'h0;
	end
	else
	begin
	channel_clk <= 1'b0;
	clk_count <= clk_count + 8'h1;
	end
end
endmodule

module triangle_synth(input wire clk, input wire t_clk, output reg[9:0] triangle);
reg counter_dir;
always @(posedge clk)
begin
	if(t_clk)
		triangle <= triangle + {10{counter_dir}};
	if(triangle == 10'd1023)
		counter_dir <= 1'b1;
	if(triangle == 10'd1)
		counter_dir <= 1'b0;
end
endmodule

module sawtooth_synth(input wire clk, input wire s_clk, output wire[9:0] sawtooth);
reg[10:0] sawtooth_counter;
always @(posedge clk)
begin
	if(s_clk)
		sawtooth_counter <= sawtooth_counter + 11'd1;
end
assign sawtooth = sawtooth_counter[10:1];
endmodule

module pulse_synth(input wire[7:0] duty, input wire[7:0] triangle, input wire[7:0] p_vol, output wire[9:0] pulse);
assign pulse = (duty > triangle) ? {p_vol, 2'b00} : 10'd0;
endmodule

module noise_synth(input wire clk, input wire noise_clk, output wire[9:0] noise_sample);
wire next_bit;
reg[9:0] s_reg;
assign next_bit = s_reg[3] ^ s_reg[0];
assign noise_sample = s_reg;
always @(posedge clk)
begin
	if(noise_clk)
		s_reg <= {next_bit, s_reg[9:1]};
end
endmodule 
