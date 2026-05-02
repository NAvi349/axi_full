module axi_full_uvm_tb_top;
  import uvm_pkg::*;
 `include "uvm_macros.svh"
  import axi_full_pkg::*;
  import axi_full_uvm_pkg::*;
  import axi_full_tb_pkg::*;
    // clk and rst connections from the tb top
    //logic rst_n;

 
	logic clock; // global clock
    req_t  dut_req;
    resp_t dut_resp;

    // AXI full slave signals

	// custom interface of axi protocol
	axi_if vif(.clock(clock));
   
   // Instantiate the AXI interface
   //AXI_BUS #(
   //  .AXI_ADDR_WIDTH(32),
   //  .AXI_DATA_WIDTH(32),   
   //  .AXI_ID_WIDTH(4),      
   //  .AXI_USER_WIDTH(0) axi_if (
   //  .clk(clk_i),
   //  .rst(rst_ni)
   //);
	// connect interface to dut

   
    //axi_lite_regs #(
    //   .RegNumBytes   (REG_NUM_BYTES),
    //   .AxiAddrWidth  (AXI_ADDR_WIDTH),
    //   .AxiDataWidth  (DATA_WIDTH),
    //   .PrivProtOnly  (PrivProtOnly),
    //   .SecuProtOnly  (SecuProtOnly),
    //   .AxiReadOnly   ('0),
    //   .byte_t        (byte_t),
    //   .RegRstVal     (RegRstVal),
    //   .req_lite_t    (req_t),
    //   .resp_lite_t   (resp_t)
    // ) slv_regs (
    //   .clk_i       (clock),
    //   .rst_ni      (vif.rst_ni),
    //   .axi_req_i   (vif.axi_req_i),
    //   .axi_resp_o  (vif.axi_resp_o),
    //   .wr_active_o (vif.wr_active_o),
    //   .rd_active_o (vif.rd_active_o),
    //   .reg_d_i     (vif.reg_d_i),
    //   .reg_load_i  (vif.reg_load_i),
    //   .reg_q_o     (vif.reg_q_o)
    // );
     
    // axi_to_mem #(
    //   .axi_req_t (req_t),
	//   .axi_resp_t (resp_t),
	//   .AddrWidth (ADDR_WIDTH),
	//   .DataWidth (DATA_WIDTH),
	//   .IdWidth   (ID_WIDTH),
	//   .NumBanks  (NUM_BANKS),
	//   .BufDepth  (BUF_DEPTH),
	//   .HideStrb  (HIDE_STRB),
	//   .OutFifoDepth (OUT_FIFO_DEPTH),
	//   .addr_t    (mem_addr_t),
	//   .mem_data_t (mem_data_t),
	//   .mem_strb_t (mem_strb_t)
	// ) slv_mem (
	//   .clk_i (clock),
	//   .rst_ni (vif.rst_ni),
	//   .busy_o (vif.busy_o),
	//   .axi_req_i (vif.axi_req_i),
	//   .axi_resp_o (vif.axi_resp_o),
	//   .mem_req_o (vif.mem_req_o),
	//   .mem_gnt_i (vif.mem_gnt_i),
	//   .mem_addr_o (vif.mem_addr_o),
	//   .mem_wdata_o (vif.mem_wdata_o),
	//   .mem_strb_o (vif.mem_strb_o),
	//   .mem_atop_o (vif.mem_atop_o),
	//   .mem_we_o (vif.mem_we_o),
	//   .mem_rvalid_i (vif.mem_rvalid_i),
	//   .mem_rdata_i (vif.mem_rdata_i)
	//  );

	axi_sim_mem #(
		.AddrWidth (ADDR_WIDTH),
		.DataWidth (DATA_WIDTH),
		.IdWidth (ID_WIDTH),
		.UserWidth (USER_WIDTH),
		.NumPorts (NUM_PORTS),
		.axi_req_t (req_t),
		.axi_rsp_t (resp_t),
		.WarnUninitialized (1),
		.UninitializedData ("zeros"),
		.ClearErrOnAccess (0),
		.ApplDelay (0),
		.AcqDelay (0)
	) axi_slv (
		.clk_i (clock),
		.rst_ni (vif.rst_ni),
		.axi_req_i (vif.axi_req_i),
		.axi_rsp_o (vif.axi_resp_o),
		.mon_w_valid_o (vif.mon_w_valid_o),
		.mon_w_addr_o (vif.mon_w_addr_o),
		.mon_w_data_o (vif.mon_w_data_o),
		.mon_w_id_o (vif.mon_w_id_o),
		.mon_w_user_o (vif.mon_w_user_o),
		.mon_w_beat_count_o (vif.mon_w_beat_count_o),
		.mon_w_last_o (vif.mon_w_last_o),
		.mon_r_valid_o (vif.mon_r_valid_o),
		.mon_r_addr_o (vif.mon_r_addr_o),
		.mon_r_data_o (vif.mon_r_data_o),
		.mon_r_id_o (vif.mon_r_id_o),
		.mon_r_user_o (vif.mon_r_user_o),
		.mon_r_beat_count_o (vif.mon_r_beat_count_o),
		.mon_r_last_o (vif.mon_r_last_o)
		);
	
	 
	 initial begin
	 	//A set() call in a context higher up the component hierarchy takes precedence over a set() call that occurs lower in the hierarchical path.

	 	uvm_config_db#(virtual axi_if)::set(uvm_root::get(), "*", "axi_if", vif);
	 	
	 	// first: context, UVM component object handle
	 	// second: access to specified components, * indicates all
	 	// lookup name string	
	 	// static interface

	 	run_test("axi_full_incr_burst_write_read_test");

	 	// use +UVM_TESTNAME with vsim terminal argument
	 end

     // clock initialization
	 initial begin
	 	clock <= 0;
        vif.rst_ni <= 0;
        vif.axi_req_i <= 0;
		#10ns;

		vif.rst_ni <= 1'b1;
	 	// clock generation
	 	forever #5ns clock = ~clock;

	 end

  // VCD dump 
  initial begin
    //$dumpfile("axi_full_uvm_tb_top.vcd");
    //$dumpvars(0, axi_full_uvm_tb_top);
  end

endmodule
