//definet the chars of |A|, |I|, |S|
`define CHAR_A 8'h7C
`define CHAR_I 8'hBC
`define CHAR_S 8'hFB
//avaible RS(N,K) is (204,188), (208,192), (255,239), 
//`define RS_N 204
//`define RS_K 188
//`define RS_ENC_DLY 3
//`define RS_DEC_DLY 419
 // `define RS_N 208
 // `define RS_K 192
// `define RS_N 40
// `define RS_K 32
`ifndef RS_QUATUS
	`define RS_N 208
	`define RS_K 192
`else
	`define RS_N 40
	`define RS_K 32
`endif
`ifndef XILINX_RS_IP
    `define RS_ENC_DLY 2
    `define RS_DEC_DLY 266
`else
    `define RS_ENC_DLY 3
    `define RS_DEC_DLY 423
`endif


//20190812 ZDF 
`define FSMC_FRAME_LEN_32bit	16'd256 
`define FSMC_FRAME_LEN_8bit 	16'd1024