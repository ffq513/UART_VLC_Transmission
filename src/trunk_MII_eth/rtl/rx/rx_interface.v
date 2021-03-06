// File               : rx_interface.v
// Author             : Tao Wu
// Created On         : 2017-06-23 14:41
// Last Modified      : 2017-07-05 14:15
// Description        : 
// replace the sof frame len with the preamble
// generate eof signal
                        
module RX_INTERFACE#(
     parameter FIFO_ADD_WIDTH = 6      
)
(
    //rx clk domain
    input               i_rx_clk
    ,input              i_rx_rst_n
    ,input  [31:0]      i_rx_data
    ,input              i_rx_data_valid
    ,input              i_rx_sof

    //for GMAC MTL interface
    ,input              i_ati_clk
    ,input              i_ati_rst_n
    ,output             o_ati_val       
    ,output             o_ati_sof       
    ,output             o_ati_eof       
    ,output  [1:0]      o_ati_be        
    ,output  [31:0]     o_ati_data      
    ,input              i_ati_rdy        

    //control
    ,input              i_x1_mode
	,output				o_rx_9600_or_115200
);
    reg  [31:0]         r_rx_data_x1;
    reg                 r_rx_data_valid_x1;
    reg                 r_rx_sof_x1;
    wire    [7:0]      c_rx_data_x1x4;
    wire                c_rx_data_valid_x1x4;
    wire                c_rx_sof_x1x4;
    
    wire                c_rx_fifo_full;
    wire                c_ati_fifo_empty;
    wire    [7:0]      c_ati_fifo_rd_data;
    //wire    [31:0]      c_ati_fifo_rd_data;
    wire                c_ati_fifo_rd_sof;
    wire                c_ati_fifo_rd_en;
    wire                c_rx_fifo_wr_en;

    localparam  IDLE        = 3'd0,
                SOF         = 3'd1,
                FRAME_LEN_1  = 3'd2,
                FRAME_LEN_2   = 3'd3, // two bytes used to describe the fram len
                DATA        = 3'd4,
                EOF         = 3'd5;

    reg     [2:0]       r_ati_state;
    reg     [2:0]       c_ati_state_next;

    reg     [15:0]      r_ati_pkt_len_cnt;

    reg                 r_ati_val       ;
    reg                 r_ati_sof       ;
    reg                 r_ati_eof       ;
    reg      [1:0]      r_ati_be        ;
    reg      [31:0]     r_ati_data      ;

    reg     [1:0]       r_x1_byte_sel;

//================================================================================
//Function  : combine 4 byte into 1 word for x1 mode on the write side of FIFO
//================================================================================
    //byte sel
    always@(posedge i_rx_clk or negedge i_rx_rst_n) begin
        if (~i_rx_rst_n) begin
            r_x1_byte_sel <= `DELAY 2'd0;
        end
        else begin
            if(i_rx_sof)
                r_x1_byte_sel <= `DELAY 2'd1;
            else if(i_rx_data_valid)
                r_x1_byte_sel <= `DELAY r_x1_byte_sel + 2'd1;
        end
    end

    always@(posedge i_rx_clk or negedge i_rx_rst_n) begin
        if (~i_rx_rst_n) begin
            r_rx_data_x1 <= `DELAY 32'h0;
        end
        else begin
            if(i_rx_data_valid) begin
                if(r_x1_byte_sel == 2'd0)
                    r_rx_data_x1[7:0] <= `DELAY i_rx_data[7:0];
                else if(r_x1_byte_sel == 2'd1)
                    r_rx_data_x1[15:8] <= `DELAY i_rx_data[7:0];
                else if(r_x1_byte_sel == 2'd2)
                    r_rx_data_x1[23:16] <= `DELAY i_rx_data[7:0];
                else 
                    r_rx_data_x1[31:24] <= `DELAY i_rx_data[7:0];
            end
        end
    end

    //extend sof for 4 bytes
    always@(posedge i_rx_clk or negedge i_rx_rst_n) begin
        if (~i_rx_rst_n) begin
            r_rx_sof_x1 <= `DELAY 1'b0;
        end
        else begin
            if(i_rx_sof)
                r_rx_sof_x1 <= `DELAY 1'b1;
            else if((i_rx_data_valid) && (r_x1_byte_sel == 2'd0))
                r_rx_sof_x1 <= `DELAY 1'b0;
        end
    end
    //assert rx_data_valid_x1 every 4 bytes
    always@(posedge i_rx_clk or negedge i_rx_rst_n) begin
        if (~i_rx_rst_n) begin
            r_rx_data_valid_x1 <= `DELAY 1'b0;
        end
        else begin
            r_rx_data_valid_x1 <= `DELAY i_rx_data_valid && (r_x1_byte_sel == 2'd3);
        end
    end

    assign c_rx_data_x1x4 = 		i_rx_data[7:0];
    //assign c_rx_data_x1x4 = i_x1_mode ? r_rx_data_x1 : i_rx_data;
    assign c_rx_data_valid_x1x4 = 	i_rx_data_valid;
    //assign c_rx_data_valid_x1x4 = i_x1_mode ? r_rx_data_valid_x1 : i_rx_data_valid;
    assign c_rx_sof_x1x4 = 			i_rx_sof;
    //assign c_rx_sof_x1x4 = i_x1_mode ? r_rx_sof_x1 : i_rx_sof;
//================================================================================
//Function  : fsm
//================================================================================
    always@(posedge i_ati_clk or negedge i_ati_rst_n) begin
        if (~i_ati_rst_n) begin
            r_ati_state <= `DELAY IDLE;
        end
        else begin
            r_ati_state <= `DELAY c_ati_state_next;
        end
    end

    //whenever and sof tag is read out from fifo, we will send a packet from
    //beginning, even the previous packet is not finished
    //this is useful when packet data is lost due to fifo full
    //it will insure at most two packets are crupted by this
	
	// 20190811 ZDF the function above is turned off to ensure that a fix length of packet to the following part
    always@( * ) begin
        c_ati_state_next = r_ati_state;
        case(r_ati_state)
            IDLE     : begin
                //sof detected
                //if(c_ati_fifo_rd_en && c_ati_fifo_rd_sof && (c_ati_fifo_rd_data==32'h55555555))
                if(c_ati_fifo_rd_en && c_ati_fifo_rd_sof && ((c_ati_fifo_rd_data==8'h55) || (c_ati_fifo_rd_data==8'hAA)))
                    c_ati_state_next = SOF;
                else
                    c_ati_state_next = IDLE;
            end
            SOF      : begin
                if((c_ati_fifo_rd_en) )// && (~c_ati_fifo_rd_sof))
                    c_ati_state_next = FRAME_LEN_1;
                else
                    c_ati_state_next = SOF;
            end
            FRAME_LEN_1: begin
                if(c_ati_fifo_rd_en) begin
                    // if(c_ati_fifo_rd_sof)
                        // c_ati_state_next = SOF;
                    // else
                        c_ati_state_next = FRAME_LEN_2;
                end
                else
                    c_ati_state_next = FRAME_LEN_1;
            end
            FRAME_LEN_2: begin
                if(c_ati_fifo_rd_en) begin
                    // if(c_ati_fifo_rd_sof)
                        // c_ati_state_next = SOF;
                    // else
                        c_ati_state_next = DATA;
                end
                else
                    c_ati_state_next = FRAME_LEN_2;
            end
            DATA     : begin
                if(c_ati_fifo_rd_en) begin
                    // if(c_ati_fifo_rd_sof)
                        // c_ati_state_next = SOF;
                    // else begin
                        if(r_ati_pkt_len_cnt <= 1)
                            c_ati_state_next = EOF; 
                        else
                            c_ati_state_next = DATA;
                    // end
                end
                else
                    c_ati_state_next = DATA;
            end
            EOF      : begin
                if(i_ati_rdy)
                    c_ati_state_next = IDLE;
                else
                    c_ati_state_next = EOF;
            end
        endcase
    end

//================================================================================
//Function  : buad rate choose
//================================================================================
	reg r_rx_9600_or_115200;
    always@(posedge i_ati_clk or negedge i_ati_rst_n) begin
        if (~i_ati_rst_n) begin
            r_rx_9600_or_115200 <= `DELAY 1'd0;
        end
        else begin
            if(c_ati_fifo_rd_en && c_ati_fifo_rd_sof && ((c_ati_fifo_rd_data==8'h55))) begin
				r_rx_9600_or_115200 <= 1'b1;
            end
			else if (c_ati_fifo_rd_en && c_ati_fifo_rd_sof && ((c_ati_fifo_rd_data==8'hAA))) begin
				r_rx_9600_or_115200 <= 1'b0;
            end
        end
    end
	assign o_rx_9600_or_115200 = r_rx_9600_or_115200;
//================================================================================
//Function  : packet len counter
//================================================================================
    always@(posedge i_ati_clk or negedge i_ati_rst_n) begin
        if (~i_ati_rst_n) begin
            r_ati_pkt_len_cnt <= `DELAY 16'd0;
        end
        else begin
            if(c_ati_fifo_rd_en) begin
                if(c_ati_state_next == FRAME_LEN_1)
                    r_ati_pkt_len_cnt[7:0] <= `DELAY c_ati_fifo_rd_data;
                else if(c_ati_state_next == FRAME_LEN_2)
                    r_ati_pkt_len_cnt[15:8] <= `DELAY c_ati_fifo_rd_data;
                else if (r_ati_pkt_len_cnt>0) //20191012 no need counting when  state == idle
                    r_ati_pkt_len_cnt <= `DELAY r_ati_pkt_len_cnt - 16'd1;
            end
        end
    end

//================================================================================
//Function  : fifo
//================================================================================
    //fifo rd en
    // new data is read from fifo when
    // 1. fifo is not empty
    // 2. MTL interface is ready to accept new data
    // 3. MTL interface not outputing EOF
    assign c_ati_fifo_rd_en = (~c_ati_fifo_empty) && i_ati_rdy && (r_ati_state!=EOF);
    // !!!Note: when fifo full, the received data may be dropped
    //  this may cause packet loss 
    assign c_rx_fifo_wr_en = c_rx_data_valid_x1x4 && (~c_rx_fifo_full);


    //instance
    //ASYNCFIFOGA #(.DSIZE(33), .ASIZE(FIFO_ADD_WIDTH)) m_asyncfifo (
    ASYNCFIFOGA #(.DSIZE(9), .ASIZE(FIFO_ADD_WIDTH)) m_asyncfifo (
        .wrst_n (i_rx_rst_n),
        .wclk   (i_rx_clk),
        .winc   (c_rx_fifo_wr_en),
        .wdata  ({c_rx_sof_x1x4, c_rx_data_x1x4}),
        .wfull  (c_rx_fifo_full),      
        .rrst_n (i_ati_rst_n),
        .rclk   (i_ati_clk),
        .rinc   (c_ati_fifo_rd_en),
        .rdata  ({c_ati_fifo_rd_sof, c_ati_fifo_rd_data}),
        .rempty (c_ati_fifo_empty)); 

//================================================================================
//Function  : reset on fifo flow 
//================================================================================
    assign c_rx_fifo_oflow = c_rx_fifo_full & c_rx_data_valid_x1x4;
    assign c_ati_fifo_uflow = c_ati_fifo_empty & c_ati_fifo_rd_en;

//================================================================================
//Function  : MTL interface
//================================================================================
    //ati_val
    always@(posedge i_ati_clk or negedge i_ati_rst_n) begin
        if (~i_ati_rst_n) begin
            r_ati_val <= `DELAY 1'b0;
        end
        else begin
            //drop the sof and frame len as preamble
            if((c_ati_state_next == DATA) || (c_ati_state_next == EOF)) begin
                if(c_ati_fifo_rd_en)
                    r_ati_val <= `DELAY 1'b1;
                //ati is ready for new data but we don't have data in fifo,
                //deassert ati_val
                else if(c_ati_fifo_empty && i_ati_rdy)
                    r_ati_val <= `DELAY 1'b0;
                //else means ati_rdy is low, keep val
            end
            else begin
                //keep val high if rdy is not high
                if(i_ati_rdy)
                    r_ati_val <= `DELAY 1'b0;
            end
        end
    end
    assign o_ati_val = r_ati_val;

    //ati_sof
    always@(posedge i_ati_clk or negedge i_ati_rst_n) begin
        if (~i_ati_rst_n) begin
            r_ati_sof <= `DELAY 1'b0;
        end
        else begin
            if( (r_ati_state == FRAME_LEN_2) && (c_ati_state_next == DATA) )
                r_ati_sof <= `DELAY 1'b1;
            else if(i_ati_rdy)
                r_ati_sof <= `DELAY 1'b0;
        end
    end
    assign o_ati_sof = r_ati_sof;

    //ati_eof
    always@(posedge i_ati_clk or negedge i_ati_rst_n) begin
        if (~i_ati_rst_n) begin
            r_ati_eof <= `DELAY 1'b0;
        end
        else begin
            r_ati_eof <= `DELAY (c_ati_state_next == EOF);
        end
    end
    assign o_ati_eof = r_ati_eof;
    
    //ati_be
    always@(posedge i_ati_clk or negedge i_ati_rst_n) begin
        if (~i_ati_rst_n) begin
            r_ati_be <= `DELAY 2'b11;
        end
        else begin
            if(c_ati_state_next == EOF) begin
                if(c_ati_fifo_rd_en) begin
                    case(r_ati_pkt_len_cnt)
                        16'd1:  r_ati_be <= `DELAY 2'd0;
                        16'd2:  r_ati_be <= `DELAY 2'd1;
                        16'd3:  r_ati_be <= `DELAY 2'd2;
                        16'd4:  r_ati_be <= `DELAY 2'd3;
                        default: r_ati_be <= `DELAY 2'd3;       //should not be 0 or >4
                    endcase
                end
            end
            else
                r_ati_be <= `DELAY 2'b11;
        end
    end
    assign o_ati_be = ~r_ati_be;  //20190222 ZDF modified for the empty signal in avalon-st

    //ati_data
    always@(posedge i_ati_clk or negedge i_ati_rst_n) begin
        if (~i_ati_rst_n) begin
            r_ati_data <= `DELAY 32'h0;
        end
        else begin
            if(c_ati_fifo_rd_en) begin
                //r_ati_data <= `DELAY c_ati_fifo_rd_data;
                r_ati_data[7:0] <= `DELAY c_ati_fifo_rd_data;
            end
        end
    end
    assign o_ati_data = r_ati_data;

endmodule

