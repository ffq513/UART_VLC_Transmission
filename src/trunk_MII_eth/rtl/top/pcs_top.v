// File               : pcs_top.v
// Author             : Tao Wu
// Created On         : 2017-06-22 14:01
// Last Modified      : 2018-05-29 16:17
// Description        : 
//  This is the top of the visible light pcs top
//  two sides:
//  one side is RGMII interface, provide standard connection with external PHY
//  with the same interface (32bit)
//  other side is parallel interface for pma (10bit * 4)
                        

module PCS_TOP(
    input               i_pon_rst_n        //the external async reset, reset all the internal modules

/* `ifdef GMAC_RGMII
    //RGMII 
    ,input              i_rgmii_tx_clk        //clock
    ,input              i_rgmii_tx_180_clk    //clock
    ,output [3:0]       o_rgmii_txd    
    ,output             o_rgmii_tx_ctl  

    ,input              i_rgmii_rx_clk        //clock
    ,input              i_rgmii_rx_180_clk    //clock
    ,input  [3:0]       i_rgmii_rxd     
    ,input              i_rgmii_rx_ctl  
`elsif GMAC_GMII 
    ,input              i_rgmii_tx_clk        //clock
    ,output [7:0]       o_gmii_txd    
    ,output             o_gmii_tx_en
    ,output             o_gmii_tx_er

    ,input              i_rgmii_rx_clk        //clock
    ,input  [7:0]       i_gmii_rxd     
    ,input              i_gmii_rx_dv  
    ,input              i_gmii_rx_er
    ,input              i_gmii_crs
    ,input              i_gmii_col

    ,output             o_gclk_sel      //select clock for gmii tx 0: 10/100M, 1000: 1000M
`elsif GMAC_MII
    ,input              i_rgmii_tx_clk        //clock
    ,output [3:0]       o_gmii_txd    
    ,output             o_gmii_tx_en
    ,output             o_gmii_tx_er

    ,input              i_rgmii_rx_clk        //clock
    ,input  [3:0]       i_gmii_rxd     
    ,input              i_gmii_rx_dv  
    ,input              i_gmii_rx_er
    ,input              i_gmii_crs
    ,input              i_gmii_col

    ,output             o_gclk_sel      //select clock for gmii tx 0: 10/100M, 1000: 1000M
`endif

    //MDIO interface
    ,output             o_gmii_mdc       // GMII/MII management clock.
    ,input              i_gmii_mdi       // GMII/MII mgmt data input. 
    ,output             o_gmii_mdo       // GMII/MII mgmt data output.
    ,output             o_gmii_mdo_oe     // GMII/MII mgmt data o/p enable. */

    ,input              i_vl_tx_rst_n   
	
    ,input              i_serial_tx_clk
    //visible light interface
    ,input              i_vl_tx_clk            //clock
    ,output				o_serial_tx_data     
    // ,output  [9:0]      o_vl_tx_0_data     
    // ,output  [9:0]      o_vl_tx_1_data     
    // ,output  [9:0]      o_vl_tx_2_data     
    // ,output  [9:0]      o_vl_tx_3_data     

    ,input              i_serial_rx_rst_n 
    ,input              i_serial_rx_clk          //clock
    ,input         		i_serial_rx_data     
    // ,input              i_vl_rx_0_clk          //clock
    // ,input              i_vl_rx_1_clk          //clock
    // ,input              i_vl_rx_2_clk          //clock
    // ,input              i_vl_rx_3_clk          //clock
    // ,input   [9:0]      i_vl_rx_0_data     
    // ,input   [9:0]      i_vl_rx_1_data     
    // ,input   [9:0]      i_vl_rx_2_data     
    // ,input   [9:0]      i_vl_rx_3_data     

    //speed control 
    // ,input              i_speed_sel_ext
    // ,output             o_speed_sel
    
    //manchest control
    // ,output             o_manchest_en

    //config interface
/*     ,input              i_cfg_clk                                     
    ,input              i_cfg_rst_n                                  
    ,input       [15:0] i_cfg_addr                   
    ,input              i_cfg_wr_en                  
    ,input       [15:0] i_cfg_wr_data                
    ,input              i_cfg_rd_en                  
    ,output      [15:0] o_cfg_rd_data   */


	//avalon st
	,input             		i_ari_val           
	,input             		i_ari_sof           
	,input             		i_ari_eof           
	,input   [1:0]     		i_ari_be            
	,input   [31:0]    		i_ari_data          
	,output  	    		o_ari_ack           
	,input   [15:0] 		i_ari_frame_len     
	,input             		i_ari_frame_len_val 
	
	,output            		o_ati_val           
	,output            		o_ati_sof           
	,output            		o_ati_eof           
	,output		[1:0]  		o_ati_be            
	,output		[31:0] 		o_ati_data          
	,input         			i_ati_rdy     

	 ,input	[15:0]		i_threshold

	
);

    //clock and resets
    wire                c_rgmii_tx_rst_n;
    wire                c_rgmii_rx_rst_n;
    wire                c_rgmii_tx_180_rst_n;
    wire                c_rgmii_rx_180_rst_n;

    wire                c_vl_rx_1_rst_n ;
    wire                c_vl_rx_2_rst_n ;
    wire                c_vl_rx_3_rst_n ;
    wire                c_cfg_rst_n ;

    //for fifo connection
    wire    [`TX_FIFO_PTR_WIDTH-1:0]    ctx_wr_addr                         ;
    wire                                ctx_wr_csn                          ;
    wire    [`FIFO_DATA_WIDTH-1:0]      ctx_wr_data                         ;
    wire                                ctx_wr_en                           ;                                         
    wire    [`TX_FIFO_PTR_WIDTH-1:0]    ctx_rd_addr                         ;
    wire                                ctx_rd_csn                          ;
    wire    [`FIFO_DATA_WIDTH-1:0]      ctx_rd_data                         ;
    wire                                ctx_rd_en                           ;
    wire    [`RX_FIFO_PTR_WIDTH-1:0]    crx_wr_addr                         ;
    wire                                crx_wr_csn                          ;
    wire                                crx_wr_en                           ;
    wire    [`FIFO_DATA_WIDTH-1:0]      crx_wr_data                         ;                                          
    wire    [`RX_FIFO_PTR_WIDTH-1:0]    crx_rd_addr                         ;
    wire                                crx_rd_csn                          ;
    wire    [`FIFO_DATA_WIDTH-1:0]      crx_rd_data                         ;
    wire    [`MAX_FRAME_CNT_WIDTH-2:0]  c_rwc_len_wr_addr ;                  
    wire                                c_rwc_len_wr_en   ;                  
    wire                                c_rwc_len_wr_csn  ;                  
    wire                                c_rwc_err_frame   ;                  
    wire    [`MAX_FRAME_CNT_WIDTH-2:0]  c_rrc_len_rd_addr ;
    wire                                c_rrc_len_rd_csn  ;
    wire    [`FRAME_LEN_FIFO_WIDTH-1:0] c_rrc_len_rd_data ;
    wire                                c_rrc_len_rd_en   ;

    //mtl interface

    wire                c_ari_val           ; 
    wire                c_ari_sof           ;
    wire                c_ari_eof           ;
    wire [1:0]          c_ari_be            ;
    wire                c_ari_rxstatus_val  ;
    wire [31:0]         c_ari_data          ;
    wire                c_ari_ack           ;
    wire    [14:0]      c_ari_frame_len     ;
    wire                c_ari_frame_len_val ;
    wire                c_ati_val    ;  
    wire                c_ati_sof    ;  
    wire                c_ati_eof    ;  
    wire  [1:0]         c_ati_be     ;  
    wire  [31:0]        c_ati_data   ;  
    wire                c_ati_rdy    ;  

    //gmii
`ifdef GMAC_MII
    wire    [3:0]       c_phy_txd_o;
    wire    [3:0]       c_phy_rxd_i;
`else //GMAC_GMII, GMAC_RGMII
    wire    [7:0]       c_phy_txd_o;
    wire    [7:0]       c_phy_rxd_i;
`endif

    //rx control and status
    wire     [4:0]      c_rxld_half_thres            ;
    wire     [7:0]      c_rxld_align_det_thres       ;
    wire     [7:0]      c_rxld_align_los_thres       ;
    wire    [3:0]       c_vl_rx_disp_err             ;
    wire    [3:0]       c_vl_rx_comma_aligned        ;
    wire     [3:0]      c_vl_rx_rxld_overflow        ;      
    wire     [3:0]      c_vl_rx_0_rxld_underflow     ;          
    wire                c_vl_rx_0_rxld_aligned       ;
    wire    [3:0]       c_vl_rx_0_rs_fail            ;
    wire    [3:0]       c_vl_rx_0_rs_found       ;
    wire    [19:0]      c_vl_rx_0_rs_err_num         ;

    //cfg
    wire                            c_soft_pcs_rst                          ;
    wire                            c_soft_tx_rst                           ;
    wire                            c_soft_rx_rst                           ;
    wire                            c_tx_x1_mode                            ;
    wire                            c_rx_x1_mode                            ;
    wire                            c_tx_rs_en                              ;
    wire                            c_rx_rs_en                              ;
    wire                            c_vl_rx_0_disp_err_l0_clr           ;
    wire                            c_vl_rx_0_disp_err_l0               ;
    wire                            c_vl_rx_1_disp_err_l1_clr           ;
    wire                            c_vl_rx_1_disp_err_l1               ;
    wire                            c_vl_rx_2_disp_err_l2_clr           ;
    wire                            c_vl_rx_2_disp_err_l2               ;
    wire                            c_vl_rx_3_disp_err_l3_clr           ;
    wire                            c_vl_rx_3_disp_err_l3               ;
    wire                            c_vl_rx_0_rxld_overflow_l0_clr      ;
    wire                            c_vl_rx_0_rxld_overflow_l0          ;
    wire                            c_vl_rx_1_rxld_overflow_l1_clr      ;
    wire                            c_vl_rx_1_rxld_overflow_l1          ;
    wire                            c_vl_rx_2_rxld_overflow_l2_clr      ;
    wire                            c_vl_rx_2_rxld_overflow_l2          ;
    wire                            c_vl_rx_3_rxld_overflow_l3_clr      ;
    wire                            c_vl_rx_3_rxld_overflow_l3          ;
    wire                            c_vl_rx_0_rxld_underflow_l0_clr     ;
    wire                            c_vl_rx_0_rxld_underflow_l0         ;
    wire                            c_vl_rx_0_rxld_underflow_l1_clr     ;
    wire                            c_vl_rx_0_rxld_underflow_l1         ;
    wire                            c_vl_rx_0_rxld_underflow_l2_clr     ;
    wire                            c_vl_rx_0_rxld_underflow_l2         ;
    wire                            c_vl_rx_0_rxld_underflow_l3_clr     ;
    wire                            c_vl_rx_0_rxld_underflow_l3         ;
    wire                            c_vl_rx_0_rs_fail_l0_clr            ;
    wire                            c_vl_rx_0_rs_fail_l0                ;
    wire                            c_vl_rx_0_rs_fail_l1_clr            ;
    wire                            c_vl_rx_0_rs_fail_l1                ;
    wire                            c_vl_rx_0_rs_fail_l2_clr            ;
    wire                            c_vl_rx_0_rs_fail_l2                ;
    wire                            c_vl_rx_0_rs_fail_l3_clr            ;
    wire                            c_vl_rx_0_rs_fail_l3                ;
    wire                            c_vl_rx_0_rs_found_l0_clr            ;
    wire                            c_vl_rx_0_rs_found_l0                ;
    wire                            c_vl_rx_0_rs_found_l1_clr            ;
    wire                            c_vl_rx_0_rs_found_l1                ;
    wire                            c_vl_rx_0_rs_found_l2_clr            ;
    wire                            c_vl_rx_0_rs_found_l2                ;
    wire                            c_vl_rx_0_rs_found_l3_clr            ;
    wire                            c_vl_rx_0_rs_found_l3                ;
    wire  [13:0]                    c_csr_mci_addr                          ;
    wire  [31:0]                    c_csr_mci_wdata                         ;
    wire                            c_csr_mci_val                           ;
    wire                            c_csr_mci_rdwn                          ;
    wire  [3:0]                     c_csr_mci_be                            ;
    wire                            c_csr_mci_ack                           ;
    wire                            c_csr_mci_intr                          ;
    wire [31:0]                     c_csr_mci_rdata                         ;
    wire                            c_csr_mci_owner                 ;
    
    wire                            c_mac_mci_val               ;
    wire   [13:0]                   c_mac_mci_addr              ;
    wire                            c_mac_mci_rdwrn             ;
    wire   [31:0]                   c_mac_mci_wdata             ;
    wire   [3:0]                    c_mac_mci_be                ;
    wire                            c_mac_mci_ack               ;
    wire   [31:0]                   c_mac_mci_rdata             ;
    wire                            c_mac_mci_intr              ;

    wire                            c_msc_mci_val               ;
    wire   [13:0]                   c_msc_mci_addr              ;
    wire                            c_msc_mci_rdwrn             ;
    wire   [31:0]                   c_msc_mci_wdata             ;
    wire   [3:0]                    c_msc_mci_be                ;
    wire                            c_msc_mci_ack               ;
    wire   [31:0]                   c_msc_mci_rdata             ;

    wire                            c_csr_speed_sel_ow  ;
    wire                            c_csr_speed_sel  ;

    wire                            c_csr_pol_adj_en         ;   
    wire                            c_csr_pol_cont_adj       ;
    wire                            c_csr_pol_ow_l0          ;
    wire                            c_csr_pol_ow_l1          ;
    wire                            c_csr_pol_ow_l2          ;
    wire                            c_csr_pol_ow_l3          ;
    wire                            c_csr_pol_ow_val_l0      ;
    wire                            c_csr_pol_ow_val_l1      ;
    wire                            c_csr_pol_ow_val_l2      ;
    wire                            c_csr_pol_ow_val_l3      ;
    wire                            c_vl_rx_0_rxpol_done_l0  ;
    wire                            c_vl_rx_1_rxpol_done_l1  ;
    wire                            c_vl_rx_2_rxpol_done_l2  ;
    wire                            c_vl_rx_3_rxpol_done_l3  ;
    wire                            c_vl_rx_0_rxpol_status_l0;
    wire                            c_vl_rx_1_rxpol_status_l1;
    wire                            c_vl_rx_2_rxpol_status_l2;
    wire                            c_vl_rx_3_rxpol_status_l3;

    wire                            c_vl_rx_0_rs_fail_cnt_l0_clr      ;
    reg    [15:0]                   r_vl_rx_0_rs_fail_cnt_l0          ;
    wire                            c_vl_rx_0_rs_fail_cnt_l1_clr      ;
    reg    [15:0]                   r_vl_rx_0_rs_fail_cnt_l1          ;
    wire                            c_vl_rx_0_rs_fail_cnt_l2_clr      ;
    reg    [15:0]                   r_vl_rx_0_rs_fail_cnt_l2          ;
    wire                            c_vl_rx_0_rs_fail_cnt_l3_clr      ;
    reg    [15:0]                   r_vl_rx_0_rs_fail_cnt_l3          ;
    wire                            c_vl_rx_0_rs_err_num_cnt_l0_clr   ;
    reg    [15:0]                   r_vl_rx_0_rs_err_num_cnt_l0       ;
    wire                            c_vl_rx_0_rs_err_num_cnt_l1_clr   ;
    reg    [15:0]                   r_vl_rx_0_rs_err_num_cnt_l1       ;
    wire                            c_vl_rx_0_rs_err_num_cnt_l2_clr   ;
    reg    [15:0]                   r_vl_rx_0_rs_err_num_cnt_l2       ;
    wire                            c_vl_rx_0_rs_err_num_cnt_l3_clr   ;
    reg    [15:0]                   r_vl_rx_0_rs_err_num_cnt_l3       ;

//================================================================================
//Function  : speed sel overwrites
//================================================================================
    //assign o_speed_sel = c_csr_speed_sel_ow ? c_csr_speed_sel : i_speed_sel_ext;

//================================================================================
//Function  : clock and reset
//================================================================================
    // CLK_RST m_clk_rst(
         // .i_pon_rst_n         (i_pon_rst_n     )
        // ,.c_soft_tx_rst_n     (~c_soft_tx_rst  )
        // ,.c_soft_rx_rst_n     (~c_soft_rx_rst  )
        // ,.c_soft_pcs_rst_n    (~c_soft_pcs_rst )
        // ,.i_rgmii_tx_clk      (i_rgmii_tx_clk  )
        // ,.i_rgmii_rx_clk      (i_rgmii_rx_clk  )
        // ,.i_rgmii_tx_180_clk  (i_rgmii_tx_180_clk  )
        // ,.i_rgmii_rx_180_clk  (i_rgmii_rx_180_clk  )
        // ,.i_vl_tx_clk         (i_vl_tx_clk     )
        // ,.i_vl_rx_0_clk       (i_vl_rx_0_clk   )
        // ,.i_vl_rx_1_clk       (1'b0   )
        // ,.i_vl_rx_2_clk       (1'b0   )
        // ,.i_vl_rx_3_clk       (1'b0   )
        // ,.i_cfg_clk           (i_cfg_clk)   
        // ,.o_rgmii_tx_rst_n    (c_rgmii_tx_rst_n)
        // ,.o_rgmii_rx_rst_n    (c_rgmii_rx_rst_n)
        // ,.o_rgmii_tx_180_rst_n(c_rgmii_tx_180_rst_n)
        // ,.o_rgmii_rx_180_rst_n(c_rgmii_rx_180_rst_n)
        // ,.o_vl_tx_rst_n       (c_vl_tx_rst_n   )
        // ,.o_vl_rx_0_rst_n     (c_vl_rx_0_rst_n )
        // ,.o_vl_rx_1_rst_n     ( )
        // ,.o_vl_rx_2_rst_n     ( )
        // ,.o_vl_rx_3_rst_n     ( )
        // ,.o_cfg_rst_n         (c_cfg_rst_n)
    // );


//================================================================================
//Function  : gmac
//================================================================================
/*    DWC_gmac_top  m_gmac(
  // Clocks and resets
    .clk_tx_i                       (i_rgmii_tx_clk        ),
    .clk_rx_i                       (i_rgmii_rx_clk        ),
    .rst_clk_tx_n                   (c_rgmii_tx_rst_n      ),
    .rst_clk_rx_n                   (c_rgmii_rx_rst_n      ),      
    // Application Input Clock & Reset
    .clk_app_i                      (i_vl_tx_clk          ),
    .rst_clk_app_n                  (c_vl_tx_rst_n    ),
    // MTL Transmit Application Interface
    .ati_val_i                      (c_ati_val          ), 
    .ati_sof_i                      (c_ati_sof          ), 
    .ati_eof_i                      (c_ati_eof          ), 
    .ati_data_i                     (c_ati_data         ), 
    .ati_be_i                       (c_ati_be           ), 
    .ati_rdy_o                      (c_ati_rdy          ), 
    .ati_pbl_i                      (11'h08              ), 
    .ati_tx_watermark_o             (                   ), 
    // MTL Transmit Control and Status Interface           
    .ati_dispad_i                   (1'b1               ), 
    .ati_discrc_i                   (1'b1               ), 
    .ati_txstatus_val_o             (                   ), 
    .ati_txstatus_o                 (                   ), 
    .ati_ack_i                      (1'b1               ), 
    // MTL Receive Application interface.                  
    // ari_rxstatus_val is added to the ack logic to prevent the gmac tx stuck
    .ari_ack_i                      ( (c_ari_ack || c_ari_rxstatus_val)   ),    
    .ari_val_o                      (c_ari_val          ), 
    .ari_sof_o                      (c_ari_sof          ), 
    .ari_eof_o                      (c_ari_eof          ), 
    .ari_data_o                     (c_ari_data         ), 
    .ari_be_o                       (c_ari_be           ), 
    .ari_rxstatus_val_o             (c_ari_rxstatus_val ), 
    .ari_frameflush_i               (1'b0               ), 
    .ari_pbl_i                      (12'h08              ), 
    .ari_rx_watermark_o             (                   ), 
    .ari_rxfifo_frm_cnt_o           (                   ), 
    .ari_frame_len_o                (c_ari_frame_len[13:0]    ), 
    .ari_frame_len_val_o            (c_ari_frame_len_val), 
    .ari_err_frame_o                (                   ), 
    // MTL <-> TxData FIFO Write Interface
    .twc_wr_addr_o                  (ctx_wr_addr            ),
    .twc_wr_csn_o                   (ctx_wr_csn             ),
    .twc_wr_data_o                  (ctx_wr_data            ),
    .twc_wr_en_o                    (ctx_wr_en              ),
    // MTL <-> TxData FIFO Read Interface                 
    .trc_rd_addr_o                  (ctx_rd_addr            ),
    .trc_rd_csn_o                   (ctx_rd_csn             ),
    .trc_rd_data_i                  (ctx_rd_data            ),
    .trc_rd_en_o                    (ctx_rd_en              ),
    // MTL <-> RxData FIFO Write Interface                  
    .rwc_wr_addr_o                  (crx_wr_addr            ),
    .rwc_wr_csn_o                   (crx_wr_csn             ),
    .rwc_wr_en_o                    (crx_wr_en              ),
    .rwc_wr_data_o                  (crx_wr_data            ),
    // MTL <-> Rx Frame Length FIFO write interface
    .rwc_len_wr_addr_o              (c_rwc_len_wr_addr      ),
    .rwc_len_wr_en_o                (c_rwc_len_wr_en        ),
    .rwc_len_wr_csn_o               (c_rwc_len_wr_csn       ),
    .rwc_err_frame_o                (c_rwc_err_frame        ),  
    // MTL <-> RxData FIFO Read Interface.                 
    .rrc_rd_addr_o                  (crx_rd_addr            ),
    .rrc_rd_csn_o                   (crx_rd_csn             ),
    .rrc_rd_data_i                  (crx_rd_data            ),
    .rrc_rd_en_o                    (crx_rd_en              ),
`ifdef GMAC_RGMII
    .clk_tx_180_i                   (i_rgmii_tx_180_clk           ),
    .rst_clk_tx_180_n               (c_rgmii_tx_180_rst_n         ),
    .clk_rx_180_i                   (i_rgmii_rx_180_clk           ),
    .rst_clk_rx_180_n               (c_rgmii_rx_180_rst_n         ),
`else   //GMAC_GMII GMAC_MII
    .mac_speed_o                    (),
`endif
     // MTL <-> Rx Frame Length FIFO read interface
    .rrc_len_rd_addr_o              (c_rrc_len_rd_addr      ),
    .rrc_len_rd_csn_o               (c_rrc_len_rd_csn       ),
    .rrc_len_rd_data_i              (c_rrc_len_rd_data      ),
    .rrc_len_rd_en_o                (c_rrc_len_rd_en        ),
    // MAC Control Interface(MCI)                           
    .mci_val_i                      (c_mac_mci_val    )  ,
    .mci_addr_i                     (c_mac_mci_addr   )  ,
    .mci_rdwrn_i                    (c_mac_mci_rdwrn  )  ,
    .mci_wdata_i                    (c_mac_mci_wdata  )  ,
    .mci_be_i                       (c_mac_mci_be     )  ,
    .mci_ack_o                      (c_mac_mci_ack    )  ,
    .mci_rdata_o                    (c_mac_mci_rdata  )  ,
    .mci_intr_o                     (c_mac_mci_intr   )  ,
    // MDIO interface
    .gmii_mdc_o                     (o_gmii_mdc     ),
    .gmii_mdi_i                     (i_gmii_mdi    ),
    .gmii_mdo_o                     (o_gmii_mdo    ),
    .gmii_mdo_o_e                   (o_gmii_mdo_oe ),

    // PHY Interface                                       
`ifdef GMAC_RGMII
    .mac_portselect_o               (                       ),
    .phy_intf_sel_i                 (3'b001                 ),
    .phy_txen_o                     (o_rgmii_tx_ctl   ),
    .phy_txer_o                     (), //not used for rgmii
    .phy_crs_i                      (1'b0    ), //not used for rgmii
    .phy_col_i                      (1'b0                   ),
    .phy_rxdv_i                     (i_rgmii_rx_ctl      ),
    .phy_rxer_i                     (1'b0             ),    //not used for rgmii
`else   //GMAC_GMII GMAC_MII
    .phy_txen_o                     (o_gmii_tx_en   ),
    .phy_txer_o                     (o_gmii_tx_er), //not used for rgmii
    .phy_crs_i                      (i_gmii_crs), //not used for rgmii
    .phy_col_i                      (i_gmii_col),
    .phy_rxdv_i                     (i_gmii_rx_dv  ),
    .phy_rxer_i                     (i_gmii_rx_er ),    //not used for rgmii
`endif
    .phy_txd_o                      (c_phy_txd_o            ),
    .phy_rxd_i                      (c_phy_rxd_i )
    );

`ifdef GMAC_RGMII
    assign o_rgmii_txd = c_phy_txd_o[3:0];
    assign c_phy_rxd_i = {4'h0, i_rgmii_rxd};
`else   // GMAC_GMII GMAC_MII
    assign o_gmii_txd = c_phy_txd_o;
    assign c_phy_rxd_i = i_gmii_rxd;
`endif

   defparam tx_ram.APTR_WIDTH = `TX_FIFO_PTR_WIDTH ;
   defparam tx_ram.DATA_WIDTH = `FIFO_DATA_WIDTH   ;
    dpram tx_ram(
    // Inputs
    .clk1           (i_vl_tx_clk          ),                           
    .clk2           (i_rgmii_tx_clk        ),
    .a1             (ctx_wr_addr        ),
    .a2             (ctx_rd_addr        ),
    .d1             (ctx_wr_data        ),
    .d2             (35'h0              ),
    .csn1           (ctx_wr_csn         ),
    .csn2           (ctx_rd_csn         ),
    .wen1           (ctx_wr_en          ),
    .oen1           (1'h0               ),
    .wen2           (1'h0               ),
    .oen2           (ctx_rd_en          ),
    // Output                           
    .q1             (                   ),
    .q2             (ctx_rd_data        )
  );

   defparam rx_ram.APTR_WIDTH = `RX_FIFO_PTR_WIDTH ;
   defparam rx_ram.DATA_WIDTH = `FIFO_DATA_WIDTH   ;
    dpram rx_ram(
    // Inputs
    .clk1           (i_rgmii_rx_clk        ),                           
    .clk2           (i_vl_tx_clk          ),
    .a1             (crx_wr_addr        ),
    .a2             (crx_rd_addr        ),
    .d1             (crx_wr_data        ),
    .d2             (35'h0              ),
    .csn1           (crx_wr_csn         ),
    .csn2           (crx_rd_csn         ),
    .wen1           (crx_wr_en          ),
    .oen1           (1'h0               ),
    .wen2           (1'h0               ),
    .oen2           (crx_rd_en          ),
    // Output                           
    .q1             (                   ),
    .q2             (crx_rd_data        )
  ); 
 
 
   defparam rx_frame_ram.APTR_WIDTH = `MAX_FRAME_CNT_WIDTH-1;
   defparam rx_frame_ram.DATA_WIDTH = `FRAME_LEN_FIFO_WIDTH;  
    dpram rx_frame_ram(
    // Inputs
    .clk1           (i_rgmii_rx_clk        ),                           
    .clk2           (i_vl_tx_clk          ),
    .a1             (c_rwc_len_wr_addr  ),
    .a2             (c_rrc_len_rd_addr  ),
    .d1             ({c_rwc_err_frame,crx_wr_data[`FRAME_LEN_FIFO_WIDTH-2+16:16]}),
    .d2             (15'h0              ),
    .csn1           (c_rwc_len_wr_csn   ),
    .csn2           (c_rrc_len_rd_csn   ),
    .wen1           (c_rwc_len_wr_en    ),
    .oen1           (1'h0               ),
    .wen2           (1'h0               ),
    .oen2           (c_rrc_len_rd_en    ),
    // Output                           
    .q1             (                   ),
    .q2             (c_rrc_len_rd_data  )
  );     */
    

//================================================================================
//Function  : tx top
//================================================================================
    TX_TOP m_tx_top (
         .i_vl_tx_clk            (i_vl_tx_clk           )
        ,.i_serial_tx_clk        (i_serial_tx_clk         )
        ,.i_vl_tx_rst_n          (i_vl_tx_rst_n         )
        ,.i_ari_val              (i_ari_val             )
        ,.i_ari_sof              (i_ari_sof             )
        ,.i_ari_eof              (i_ari_eof             )
        ,.i_ari_be               (i_ari_be              )
        ,.i_ari_data             (i_ari_data            )
        ,.o_ari_ack              (o_ari_ack             )
        ,.i_ari_frame_len        (i_ari_frame_len       )
        ,.i_ari_frame_len_val    (i_ari_frame_len_val   )
        ,.o_vl_tx_data_0         (o_serial_tx_data        )
        // ,.o_vl_tx_data_1         (o_vl_tx_1_data        )
        // ,.o_vl_tx_data_2         (o_vl_tx_2_data        )
        // ,.o_vl_tx_data_3         (o_vl_tx_3_data        )
        ,.i_rs_en                (1'b1)     
`ifdef X1_ONLY_MODE
        ,.i_x1_mode              (1'b1)     
`else
        ,.i_x1_mode              (c_tx_x1_mode)     
`endif
        ,.i_pol_adj_en           (1'b1)
    );
    //assign c_ari_frame_len[14] = 1'b0;

//================================================================================
//Function  : rx top
//================================================================================
    RX_TOP//#(i_threshold) 
	 m_rx_top(
         .i_vl_tx_clk                   (i_vl_tx_clk        )
        ,.i_vl_tx_rst_n                 (i_vl_tx_rst_n      )
        ,.o_ati_val                     (o_ati_val )
        ,.o_ati_sof                     (o_ati_sof )
        ,.o_ati_eof                     (o_ati_eof )
        ,.o_ati_be                      (o_ati_be  )
        ,.o_ati_data                    (o_ati_data)
        ,.i_ati_rdy                     (i_ati_rdy )
		
        ,.i_serial_rx_clk               (i_serial_rx_clk)
        ,.i_serial_rx_rst_n             (i_serial_rx_rst_n)
        ,.i_serial_rx_data              (i_serial_rx_data)
        ,.i_rs_en                       (1'b1)
`ifdef X1_ONLY_MODE
        ,.i_x1_mode                     (1'b1)     
        //,.i_vl_rx_1_clk                 (1'b0)
        //,.i_vl_rx_2_clk                 (1'b0)
        //,.i_vl_rx_3_clk                 (1'b0)
        //,.i_vl_rx_1_rst_n               (1'b0)
        //,.i_vl_rx_2_rst_n               (1'b0)
        //,.i_vl_rx_3_rst_n               (1'b0)
        //,.i_vl_rx_1_data                (10'h0)
        //,.i_vl_rx_2_data                (10'h0)
        //,.i_vl_rx_3_data                (10'h0)
`else
        ,.i_x1_mode                     (c_rx_x1_mode)     
        //,.i_vl_rx_1_clk                 (i_vl_rx_1_clk)
        //,.i_vl_rx_2_clk                 (i_vl_rx_2_clk)
        //,.i_vl_rx_3_clk                 (i_vl_rx_3_clk)
        //,.i_vl_rx_1_rst_n               (c_vl_rx_1_rst_n)
        //,.i_vl_rx_2_rst_n               (c_vl_rx_2_rst_n)
        //,.i_vl_rx_3_rst_n               (c_vl_rx_3_rst_n)
        //,.i_vl_rx_1_data                (i_vl_rx_1_data)
        //,.i_vl_rx_2_data                (i_vl_rx_2_data)
        //,.i_vl_rx_3_data                (i_vl_rx_3_data)
`endif
        ,.i_rxld_half_thres             (5'd8       )
        ,.i_rxld_align_det_thres        (8'd4  )
        ,.i_rxld_align_los_thres        (8'd8  )
        ,.i_pol_adj_en                  (1'b1)  //c_csr_pol_adj_en 
        ,.i_pol_cont_adj                (1'b1)
        ,.i_pol_ow                      ({1'b0,1'b0,1'b0,1'b0})
        ,.i_pol_ow_val                  ({1'b0,1'b0,1'b0,1'b0})
        //,.o_pol_done                    ({c_vl_rx_3_rxpol_done_l3,c_vl_rx_2_rxpol_done_l2,c_vl_rx_1_rxpol_done_l1,c_vl_rx_0_rxpol_done_l0})
        //,.o_pol_status                  ({c_vl_rx_3_rxpol_status_l3, c_vl_rx_2_rxpol_status_l2, c_vl_rx_1_rxpol_status_l1, c_vl_rx_0_rxpol_status_l0})
        //,.o_vl_rx_disp_err              (c_vl_rx_disp_err        )
        //,.o_vl_rx_comma_aligned         (c_vl_rx_comma_aligned   )
        //,.o_vl_rx_rxld_overflow         (c_vl_rx_rxld_overflow   )      
        //,.o_vl_rx_0_rxld_underflow      (c_vl_rx_0_rxld_underflow)          
        //,.o_vl_rx_0_rxld_aligned        (c_vl_rx_0_rxld_aligned  )
        ,.o_vl_rx_0_rs_fail             (c_vl_rx_0_rs_fail       )
        ,.o_vl_rx_0_rs_err_found        (c_vl_rx_0_rs_found  )
        ,.o_vl_rx_0_rs_err_num          (c_vl_rx_0_rs_err_num    ) 
		  
		  ,.i_threshold							(i_threshold)

    );

//================================================================================
//Function  : MAC speed control
//================================================================================
    //use the same clock as clk_app of GMAC
    //MAC_SPEED_CRTL_TOP m_mac_speed_ctrl(
    //     .i_clk         (i_vl_tx_clk   )
    //    ,.i_rst_n       (c_vl_tx_rst_n )
    //    ,.o_mci_val	    (c_msc_mci_val    )
    //    ,.o_mci_wdata	(c_msc_mci_wdata  )
    //    ,.o_mci_be	    (c_msc_mci_be  )
    //    ,.o_mci_addr	(c_msc_mci_addr  )
    //    ,.o_mci_rdwn	(c_msc_mci_rdwrn    )
    //    ,.i_mci_ack	    (c_msc_mci_ack    )
    //    ,.i_mci_rdata	(c_msc_mci_rdata  )
    //    ,.o_gclk_sel    (o_gclk_sel)
    //);
    assign o_gclk_sel = 1'b0;


//================================================================================
//Function  : MCI interface mux
//================================================================================
    assign c_csr_mci_owner = 1'b1;
    assign c_mac_mci_val    = c_csr_mci_owner ? c_csr_mci_val    : c_msc_mci_val  ;
    assign c_mac_mci_addr   = c_csr_mci_owner ? c_csr_mci_addr   : c_msc_mci_addr ;
    assign c_mac_mci_rdwrn  = c_csr_mci_owner ? c_csr_mci_rdwn   : c_msc_mci_rdwrn;
    assign c_mac_mci_wdata  = c_csr_mci_owner ? c_csr_mci_wdata  : c_msc_mci_wdata;
    assign c_mac_mci_be     = c_csr_mci_owner ? c_csr_mci_be     : c_msc_mci_be   ;

    assign c_msc_mci_ack = c_csr_mci_owner ? 1'b0 : c_mac_mci_ack;
    assign c_msc_mci_rdata = c_mac_mci_rdata;

    assign c_csr_mci_ack = c_csr_mci_owner ? c_mac_mci_ack : 1'b0;
    assign c_csr_mci_rdata = c_mac_mci_rdata;
    assign c_csr_mci_intr = c_mac_mci_intr;
    
//================================================================================
//Function  : configuration
//================================================================================
/*     CFG m_cfg(
         .i_cfg_clk                                         (i_cfg_clk                          )
        ,.i_cfg_rst_n                                       (c_cfg_rst_n                        )
        ,.i_cfg_addr                                        (i_cfg_addr                         )
        ,.i_cfg_wr_en                                       (i_cfg_wr_en                        )
        ,.i_cfg_wr_data                                     (i_cfg_wr_data                      )
        ,.i_cfg_rd_en                                       (i_cfg_rd_en                        )
        ,.o_cfg_rd_data                                     (o_cfg_rd_data                      )
        ,.i_vl_rx_2_clk                                     (i_vl_rx_2_clk                      )
        ,.i_vl_rx_2_rst_n                                   (c_vl_rx_2_rst_n                    )
        ,.i_vl_rx_3_clk                                     (i_vl_rx_3_clk                      )
        ,.i_vl_rx_3_rst_n                                   (c_vl_rx_3_rst_n                    )
        ,.i_vl_rx_1_clk                                     (i_vl_rx_1_clk                      )
        ,.i_vl_rx_1_rst_n                                   (c_vl_rx_1_rst_n                    )
        ,.i_vl_rx_0_clk                                     (i_vl_rx_0_clk                      )
        ,.i_vl_rx_0_rst_n                                   (c_vl_rx_0_rst_n                    )
        ,.o_csr_soft_pcs_rst                                (c_soft_pcs_rst                 )
        ,.o_csr_soft_tx_rst                                 (c_soft_tx_rst                  )
        ,.o_csr_soft_rx_rst                                 (c_soft_rx_rst                  )
        ,.o_csr_rw_scratch                                  ()
        ,.o_csr_tx_x1_mode_en                               (c_tx_x1_mode                )
        ,.o_csr_rx_x1_mode_en                               (c_rx_x1_mode                )
        ,.o_csr_tx_rs_en                                    (c_tx_rs_en                     )
        ,.o_csr_rx_rs_en                                    (c_rx_rs_en                     )
        ,.i_vl_rx_0_comma_aligned_l0                    (c_vl_rx_comma_aligned[0]     )
        ,.i_vl_rx_1_comma_aligned_l1                    (c_vl_rx_comma_aligned[1]    )
        ,.i_vl_rx_2_comma_aligned_l2                    (c_vl_rx_comma_aligned[2]    )
        ,.i_vl_rx_3_comma_aligned_l3                    (c_vl_rx_comma_aligned[3]    )
        ,.o_vl_rx_0_disp_err_l0_clr                     (c_vl_rx_0_disp_err_l0_clr      )
        ,.i_vl_rx_0_disp_err_l0                         (c_vl_rx_0_disp_err_l0          )
        ,.o_vl_rx_1_disp_err_l1_clr                     (c_vl_rx_1_disp_err_l1_clr      )
        ,.i_vl_rx_1_disp_err_l1                         (c_vl_rx_1_disp_err_l1          )
        ,.o_vl_rx_2_disp_err_l2_clr                     (c_vl_rx_2_disp_err_l2_clr      )
        ,.i_vl_rx_2_disp_err_l2                         (c_vl_rx_2_disp_err_l2          )
        ,.o_vl_rx_3_disp_err_l3_clr                     (c_vl_rx_3_disp_err_l3_clr      )
        ,.i_vl_rx_3_disp_err_l3                         (c_vl_rx_3_disp_err_l3          )
        ,.o_csr_rxld_half_thres                         (c_rxld_half_thres              )
        ,.o_csr_rxld_align_det_thres                    (c_rxld_align_det_thres         )
        ,.o_csr_rxld_align_los_thres                    (c_rxld_align_los_thres         )
        ,.o_vl_rx_0_rxld_overflow_l0_clr                (c_vl_rx_0_rxld_overflow_l0_clr )
        ,.i_vl_rx_0_rxld_overflow_l0                    (c_vl_rx_0_rxld_overflow_l0     )
        ,.o_vl_rx_1_rxld_overflow_l1_clr                (c_vl_rx_1_rxld_overflow_l1_clr )
        ,.i_vl_rx_1_rxld_overflow_l1                    (c_vl_rx_1_rxld_overflow_l1     )
        ,.o_vl_rx_2_rxld_overflow_l2_clr                (c_vl_rx_2_rxld_overflow_l2_clr )
        ,.i_vl_rx_2_rxld_overflow_l2                    (c_vl_rx_2_rxld_overflow_l2     )
        ,.o_vl_rx_3_rxld_overflow_l3_clr                (c_vl_rx_3_rxld_overflow_l3_clr )
        ,.i_vl_rx_3_rxld_overflow_l3                    (c_vl_rx_3_rxld_overflow_l3     )
        ,.o_vl_rx_0_rxld_underflow_l0_clr               (c_vl_rx_0_rxld_underflow_l0_clr)
        ,.i_vl_rx_0_rxld_underflow_l0                   (c_vl_rx_0_rxld_underflow_l0    )
        ,.o_vl_rx_0_rxld_underflow_l1_clr               (c_vl_rx_0_rxld_underflow_l1_clr)
        ,.i_vl_rx_0_rxld_underflow_l1                   (c_vl_rx_0_rxld_underflow_l1    )
        ,.o_vl_rx_0_rxld_underflow_l2_clr               (c_vl_rx_0_rxld_underflow_l2_clr)
        ,.i_vl_rx_0_rxld_underflow_l2                   (c_vl_rx_0_rxld_underflow_l2    )
        ,.o_vl_rx_0_rxld_underflow_l3_clr               (c_vl_rx_0_rxld_underflow_l3_clr)
        ,.i_vl_rx_0_rxld_underflow_l3                   (c_vl_rx_0_rxld_underflow_l3    )
        ,.i_vl_rx_0_rxld_aligned                        (c_vl_rx_0_rxld_aligned         )
        ,.o_vl_rx_0_rs_fail_l0_clr                      (c_vl_rx_0_rs_fail_l0_clr       )
        ,.i_vl_rx_0_rs_fail_l0                          (c_vl_rx_0_rs_fail_l0           )
        ,.i_vl_rx_0_rs_found_l0                         (c_vl_rx_0_rs_found_l0          )
        ,.o_vl_rx_0_rs_found_l0_clr                     (c_vl_rx_0_rs_found_l0_clr          )
        ,.o_vl_rx_0_rs_fail_l1_clr                      (c_vl_rx_0_rs_fail_l1_clr       )
        ,.i_vl_rx_0_rs_fail_l1                          (c_vl_rx_0_rs_fail_l1           )
        ,.i_vl_rx_0_rs_found_l1                         (c_vl_rx_0_rs_found_l1          )
        ,.o_vl_rx_0_rs_found_l1_clr                     (c_vl_rx_0_rs_found_l1_clr          )
        ,.o_vl_rx_0_rs_fail_l2_clr                      (c_vl_rx_0_rs_fail_l2_clr       )
        ,.i_vl_rx_0_rs_fail_l2                          (c_vl_rx_0_rs_fail_l2           )
        ,.i_vl_rx_0_rs_found_l2                         (c_vl_rx_0_rs_found_l2          )
        ,.o_vl_rx_0_rs_found_l2_clr                     (c_vl_rx_0_rs_found_l2_clr          )
        ,.o_vl_rx_0_rs_fail_l3_clr                      (c_vl_rx_0_rs_fail_l3_clr       )
        ,.i_vl_rx_0_rs_fail_l3                          (c_vl_rx_0_rs_fail_l3           )
        ,.i_vl_rx_0_rs_found_l3                         (c_vl_rx_0_rs_found_l3          )
        ,.o_vl_rx_0_rs_found_l3_clr                     (c_vl_rx_0_rs_found_l3_clr          )
        ,.o_vl_rx_0_rs_fail_cnt_l0_clr                  (c_vl_rx_0_rs_fail_cnt_l0_clr   )
        ,.i_vl_rx_0_rs_fail_cnt_l0                      (r_vl_rx_0_rs_fail_cnt_l0       )
        ,.o_vl_rx_0_rs_fail_cnt_l1_clr                  (c_vl_rx_0_rs_fail_cnt_l1_clr   )
        ,.i_vl_rx_0_rs_fail_cnt_l1                      (r_vl_rx_0_rs_fail_cnt_l1       )
        ,.o_vl_rx_0_rs_fail_cnt_l2_clr                  (c_vl_rx_0_rs_fail_cnt_l2_clr   )
        ,.i_vl_rx_0_rs_fail_cnt_l2                      (r_vl_rx_0_rs_fail_cnt_l2       )
        ,.o_vl_rx_0_rs_fail_cnt_l3_clr                  (c_vl_rx_0_rs_fail_cnt_l3_clr   )
        ,.i_vl_rx_0_rs_fail_cnt_l3                      (r_vl_rx_0_rs_fail_cnt_l3       )
        ,.o_vl_rx_0_rs_err_num_cnt_l0_clr               (c_vl_rx_0_rs_err_num_cnt_l0_clr)
        ,.i_vl_rx_0_rs_err_num_cnt_l0                   (r_vl_rx_0_rs_err_num_cnt_l0    )
        ,.o_vl_rx_0_rs_err_num_cnt_l1_clr               (c_vl_rx_0_rs_err_num_cnt_l1_clr)
        ,.i_vl_rx_0_rs_err_num_cnt_l1                   (r_vl_rx_0_rs_err_num_cnt_l1    )
        ,.o_vl_rx_0_rs_err_num_cnt_l2_clr               (c_vl_rx_0_rs_err_num_cnt_l2_clr)
        ,.i_vl_rx_0_rs_err_num_cnt_l2                   (r_vl_rx_0_rs_err_num_cnt_l2    )
        ,.o_vl_rx_0_rs_err_num_cnt_l3_clr               (c_vl_rx_0_rs_err_num_cnt_l3_clr)
        ,.i_vl_rx_0_rs_err_num_cnt_l3                   (r_vl_rx_0_rs_err_num_cnt_l3    )
        ,.o_csr_speed_sel_ow                            (c_csr_speed_sel_ow)
        ,.o_csr_speed_sel                               (c_csr_speed_sel)
        ,.o_csr_manchest_en                             (o_manchest_en)
        ,.o_csr_pol_adj_en                              (c_csr_pol_adj_en           )
        ,.o_csr_pol_cont_adj                            (c_csr_pol_cont_adj         )
        ,.o_csr_pol_ow_l0                               (c_csr_pol_ow_l0            )
        ,.o_csr_pol_ow_l1                               (c_csr_pol_ow_l1            )
        ,.o_csr_pol_ow_l2                               (c_csr_pol_ow_l2            )
        ,.o_csr_pol_ow_l3                               (c_csr_pol_ow_l3            )
        ,.o_csr_pol_ow_val_l0                           (c_csr_pol_ow_val_l0        )
        ,.o_csr_pol_ow_val_l1                           (c_csr_pol_ow_val_l1        )
        ,.o_csr_pol_ow_val_l2                           (c_csr_pol_ow_val_l2        )
        ,.o_csr_pol_ow_val_l3                           (c_csr_pol_ow_val_l3        )
        ,.i_vl_rx_0_rxpol_done_l0                       (c_vl_rx_0_rxpol_done_l0    )
        ,.i_vl_rx_1_rxpol_done_l1                       (c_vl_rx_1_rxpol_done_l1    )
        ,.i_vl_rx_2_rxpol_done_l2                       (c_vl_rx_2_rxpol_done_l2    )
        ,.i_vl_rx_3_rxpol_done_l3                       (c_vl_rx_3_rxpol_done_l3    )
        ,.i_vl_rx_0_rxpol_status_l0                     (c_vl_rx_0_rxpol_status_l0  )
        ,.i_vl_rx_1_rxpol_status_l1                     (c_vl_rx_1_rxpol_status_l1  )
        ,.i_vl_rx_2_rxpol_status_l2                     (c_vl_rx_2_rxpol_status_l2  )
        ,.i_vl_rx_3_rxpol_status_l3                     (c_vl_rx_3_rxpol_status_l3  )
        ,.o_csr_mci_addr                                    (c_csr_mci_addr                     )
        ,.o_csr_mci_wdata                                   (c_csr_mci_wdata                )
        ,.o_vl_rx_0_mci_val                                 (c_csr_mci_val                      )
        ,.o_vl_rx_0_mci_rdwn                                (c_csr_mci_rdwn                     )
        ,.o_csr_mci_be                                      (c_csr_mci_be                       )
        ,.i_vl_rx_0_mci_ack                                 (c_csr_mci_ack                      )
        ,.i_csr_mci_intr                                    (c_csr_mci_intr                     )
        ,.i_csr_mci_rdata                                   (c_csr_mci_rdata                )
        ,.o_vl_rx_0_mci_owner                               ()//(c_csr_mci_owner                )
    ); */


/*     //stalls
    STALL m_stall_disp_err_l0(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_disp_err[0]),
        .i_clr     (c_vl_rx_0_disp_err_l0_clr),
        .o_stall   (c_vl_rx_0_disp_err_l0));

    STALL m_stall_disp_err_l1(
        .i_clk     (i_vl_rx_1_clk),
        .i_rst_n   (c_vl_rx_1_rst_n),
        .i_signal  (c_vl_rx_disp_err[1]),
        .i_clr     (c_vl_rx_1_disp_err_l1_clr),
        .o_stall   (c_vl_rx_1_disp_err_l1));

    STALL m_stall_disp_err_l2(
        .i_clk     (i_vl_rx_2_clk),
        .i_rst_n   (c_vl_rx_2_rst_n),
        .i_signal  (c_vl_rx_disp_err[2]),
        .i_clr     (c_vl_rx_2_disp_err_l2_clr),
        .o_stall   (c_vl_rx_2_disp_err_l2));

    STALL m_stall_disp_err_l3(
        .i_clk     (i_vl_rx_3_clk),
        .i_rst_n   (c_vl_rx_3_rst_n),
        .i_signal  (c_vl_rx_disp_err[3]),
        .i_clr     (c_vl_rx_3_disp_err_l3_clr),
        .o_stall   (c_vl_rx_3_disp_err_l3));

    STALL m_stall_rxld_overflow_l0(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_rxld_overflow[0]),
        .i_clr     (c_vl_rx_0_rxld_overflow_l0_clr),
        .o_stall   (c_vl_rx_0_rxld_overflow_l0));

    STALL m_stall_rxld_overflow_l1(
        .i_clk     (i_vl_rx_1_clk),
        .i_rst_n   (c_vl_rx_1_rst_n),
        .i_signal  (c_vl_rx_rxld_overflow[1]),
        .i_clr     (c_vl_rx_1_rxld_overflow_l1_clr),
        .o_stall   (c_vl_rx_1_rxld_overflow_l1));

    STALL m_stall_rxld_overflow_l2(
        .i_clk     (i_vl_rx_2_clk),
        .i_rst_n   (c_vl_rx_2_rst_n),
        .i_signal  (c_vl_rx_rxld_overflow[2]),
        .i_clr     (c_vl_rx_2_rxld_overflow_l2_clr),
        .o_stall   (c_vl_rx_2_rxld_overflow_l2));

    STALL m_stall_rxld_overflow_l3(
        .i_clk     (i_vl_rx_3_clk),
        .i_rst_n   (c_vl_rx_3_rst_n),
        .i_signal  (c_vl_rx_rxld_overflow[3]),
        .i_clr     (c_vl_rx_3_rxld_overflow_l3_clr),
        .o_stall   (c_vl_rx_3_rxld_overflow_l3));

    STALL m_stall_rxld_underflow_l0(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rxld_underflow[0]),
        .i_clr     (c_vl_rx_0_rxld_underflow_l0_clr),
        .o_stall   (c_vl_rx_0_rxld_underflow_l0));

    STALL m_stall_rxld_underflow_l1(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rxld_underflow[1]),
        .i_clr     (c_vl_rx_0_rxld_underflow_l1_clr),
        .o_stall   (c_vl_rx_0_rxld_underflow_l1));

    STALL m_stall_rxld_underflow_l2(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rxld_underflow[2]),
        .i_clr     (c_vl_rx_0_rxld_underflow_l2_clr),
        .o_stall   (c_vl_rx_0_rxld_underflow_l2));

    STALL m_stall_rxld_underflow_l3(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rxld_underflow[3]),
        .i_clr     (c_vl_rx_0_rxld_underflow_l3_clr),
        .o_stall   (c_vl_rx_0_rxld_underflow_l3));

    STALL m_stall_rs_fail_l0(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rs_fail[0]),
        .i_clr     (c_vl_rx_0_rs_fail_l0_clr),
        .o_stall   (c_vl_rx_0_rs_fail_l0));

    STALL m_stall_rs_fail_l1(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rs_fail[1]),
        .i_clr     (c_vl_rx_0_rs_fail_l1_clr),
        .o_stall   (c_vl_rx_0_rs_fail_l1));

    STALL m_stall_rs_fail_l2(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rs_fail[2]),
        .i_clr     (c_vl_rx_0_rs_fail_l2_clr),
        .o_stall   (c_vl_rx_0_rs_fail_l2));

    STALL m_stall_rs_fail_l3(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rs_fail[3]),
        .i_clr     (c_vl_rx_0_rs_fail_l3_clr),
        .o_stall   (c_vl_rx_0_rs_fail_l3));
    
    STALL m_stall_rs_found_l0(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rs_found[0]),
        .i_clr     (c_vl_rx_0_rs_found_l0_clr),
        .o_stall   (c_vl_rx_0_rs_found_l0));

    STALL m_stall_rs_found_l1(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rs_found[1]),
        .i_clr     (c_vl_rx_0_rs_found_l1_clr),
        .o_stall   (c_vl_rx_0_rs_found_l1));

    STALL m_stall_rs_found_l2(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rs_found[2]),
        .i_clr     (c_vl_rx_0_rs_found_l2_clr),
        .o_stall   (c_vl_rx_0_rs_found_l2));

    STALL m_stall_rs_found_l3(
        .i_clk     (i_vl_rx_0_clk),
        .i_rst_n   (c_vl_rx_0_rst_n),
        .i_signal  (c_vl_rx_0_rs_found[3]),
        .i_clr     (c_vl_rx_0_rs_found_l3_clr),
        .o_stall   (c_vl_rx_0_rs_found_l3)); */
    


//================================================================================
//Function  : rs fail counters and err_num counters
//================================================================================
/*     always@(posedge i_vl_rx_0_clk or negedge c_vl_rx_0_rst_n) begin
        if (~c_vl_rx_0_rst_n) begin
            r_vl_rx_0_rs_fail_cnt_l0 <= `DELAY 16'd0;
        end
        else begin
            if(c_vl_rx_0_rs_fail_cnt_l0_clr)
                r_vl_rx_0_rs_fail_cnt_l0 <= `DELAY 16'd0;
            else if(c_vl_rx_0_rs_fail[0])
                r_vl_rx_0_rs_fail_cnt_l0 <= `DELAY r_vl_rx_0_rs_fail_cnt_l0 + 16'd1;
        end
    end
    always@(posedge i_vl_rx_0_clk or negedge c_vl_rx_0_rst_n) begin
        if (~c_vl_rx_0_rst_n) begin
            r_vl_rx_0_rs_fail_cnt_l1 <= `DELAY 16'd0;
        end
        else begin
            if(c_vl_rx_0_rs_fail_cnt_l1_clr)
                r_vl_rx_0_rs_fail_cnt_l1 <= `DELAY 16'd0;
            else if(c_vl_rx_0_rs_fail[1])
                r_vl_rx_0_rs_fail_cnt_l1 <= `DELAY r_vl_rx_0_rs_fail_cnt_l1 + 16'd1;
        end
    end
    always@(posedge i_vl_rx_0_clk or negedge c_vl_rx_0_rst_n) begin
        if (~c_vl_rx_0_rst_n) begin
            r_vl_rx_0_rs_fail_cnt_l2 <= `DELAY 16'd0;
        end
        else begin
            if(c_vl_rx_0_rs_fail_cnt_l2_clr)
                r_vl_rx_0_rs_fail_cnt_l2 <= `DELAY 16'd0;
            else if(c_vl_rx_0_rs_fail[2])
                r_vl_rx_0_rs_fail_cnt_l2 <= `DELAY r_vl_rx_0_rs_fail_cnt_l2 + 16'd1;
        end
    end
    always@(posedge i_vl_rx_0_clk or negedge c_vl_rx_0_rst_n) begin
        if (~c_vl_rx_0_rst_n) begin
            r_vl_rx_0_rs_fail_cnt_l3 <= `DELAY 16'd0;
        end
        else begin
            if(c_vl_rx_0_rs_fail_cnt_l3_clr)
                r_vl_rx_0_rs_fail_cnt_l3 <= `DELAY 16'd0;
            else if(c_vl_rx_0_rs_fail[3])
                r_vl_rx_0_rs_fail_cnt_l3 <= `DELAY r_vl_rx_0_rs_fail_cnt_l3 + 16'd1;
        end
    end
    always@(posedge i_vl_rx_0_clk or negedge c_vl_rx_0_rst_n) begin
        if (~c_vl_rx_0_rst_n) begin
            r_vl_rx_0_rs_err_num_cnt_l0 <= `DELAY 16'd0;
        end
        else begin
            if(c_vl_rx_0_rs_err_num_cnt_l0_clr)
                r_vl_rx_0_rs_err_num_cnt_l0 <= `DELAY 16'd0;
            else  
                r_vl_rx_0_rs_err_num_cnt_l0 <= `DELAY r_vl_rx_0_rs_err_num_cnt_l0 + c_vl_rx_0_rs_err_num[4:0];
        end
    end
    always@(posedge i_vl_rx_0_clk or negedge c_vl_rx_0_rst_n) begin
        if (~c_vl_rx_0_rst_n) begin
            r_vl_rx_0_rs_err_num_cnt_l1 <= `DELAY 16'd0;
        end
        else begin
            if(c_vl_rx_0_rs_err_num_cnt_l1_clr)
                r_vl_rx_0_rs_err_num_cnt_l1 <= `DELAY 16'd0;
            else  
                r_vl_rx_0_rs_err_num_cnt_l1 <= `DELAY r_vl_rx_0_rs_err_num_cnt_l1 + c_vl_rx_0_rs_err_num[9:5];
        end
    end
    always@(posedge i_vl_rx_0_clk or negedge c_vl_rx_0_rst_n) begin
        if (~c_vl_rx_0_rst_n) begin
            r_vl_rx_0_rs_err_num_cnt_l2 <= `DELAY 16'd0;
        end
        else begin
            if(c_vl_rx_0_rs_err_num_cnt_l2_clr)
                r_vl_rx_0_rs_err_num_cnt_l2 <= `DELAY 16'd0;
            else  
                r_vl_rx_0_rs_err_num_cnt_l2 <= `DELAY r_vl_rx_0_rs_err_num_cnt_l2 + c_vl_rx_0_rs_err_num[14:10];
        end
    end
    always@(posedge i_vl_rx_0_clk or negedge c_vl_rx_0_rst_n) begin
        if (~c_vl_rx_0_rst_n) begin
            r_vl_rx_0_rs_err_num_cnt_l3 <= `DELAY 16'd0;
        end
        else begin
            if(c_vl_rx_0_rs_err_num_cnt_l3_clr)
                r_vl_rx_0_rs_err_num_cnt_l3 <= `DELAY 16'd0;
            else  
                r_vl_rx_0_rs_err_num_cnt_l3 <= `DELAY r_vl_rx_0_rs_err_num_cnt_l3 + c_vl_rx_0_rs_err_num[19:15];
        end
    end */
endmodule
