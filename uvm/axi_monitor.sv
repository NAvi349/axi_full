class axi_monitor extends uvm_monitor;
  
 `uvm_component_utils(axi_monitor)
  
  virtual axi_if vif;

  axi_transaction axi_tx;
  axi_transaction axi_tx_out;

  logic [31:0] burst_data[10]; 
  logic [5:0] completed_w_beats = 0;
  logic completed_w_burst = 0;
  logic completed_aw_phase = 0;
  logic completed_write_in = 0;
  logic completed_write_out = 0;

  
  logic [31:0] burst_data_out[10];
  logic [5:0] completed_r_beats = 0;
  logic completed_r_burst = 0;
  logic completed_ar_phase = 0;
  logic completed_read_in = 0;
  logic completed_read_out = 0;

  // analysis ports of monitor to scoreboard
  uvm_analysis_port #(axi_transaction) dut_in_tx_port;
  uvm_analysis_port #(axi_transaction) dut_out_tx_port;

  function new(string name = "axi_monitor", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    
	dut_in_tx_port = new("dut_in_tx_port", this);
	dut_out_tx_port = new("dut_out_tx_port", this);
   
	if (!uvm_config_db #(virtual axi_if)::get(this, "", "axi_if", vif))
	 `uvm_fatal("MONITOR", "Failed to get AXI IF")
  endfunction

  task run_phase(uvm_phase phase);
   
	fork 
	  //monitor DUT inputs
	  begin
	    forever begin
          axi_tx = axi_transaction::type_id::create("axi_tx");
          get_inputs();
	     `uvm_info("INPUT MON", $sformatf("%s", axi_tx.convert2str()), UVM_MEDIUM)
	      @(posedge vif.clock);
		  // collect each beat completed and drive only when completed
		  if (completed_write_in | completed_read_in) begin
		   //`uvm_info("AW_W_MON", "Pushing AW+W to scoreboard", UVM_LOW)
	        //axi_tx.burst_data = burst;
            if (completed_write_in) begin 
			  //if (axi_tx.axi_req_i.aw.burst != 'b00) begin
			    for (int i = 0; i < completed_w_beats; ++i)
		          axi_tx.burst_data[i] = burst_data[i];
			  //end
			  axi_tx.READ_WRITE = 1;
			end

			else if (completed_read_in) begin
              axi_tx.READ_WRITE = 0;
			end

		   `uvm_info("MON_TO_SCOREBOARD", $sformatf("Burst data = %p", axi_tx.burst_data), UVM_HIGH)
		   `uvm_info("MON_TO_SCOREBOARD", $sformatf("Read Write = %d", axi_tx.READ_WRITE), UVM_HIGH)
			dut_in_tx_port.write(axi_tx);
		    completed_aw_phase = 0;
			completed_write_in = 0;
			completed_w_burst = 0;
			completed_w_beats = 0;
			completed_read_in = 0;
		  end

	    end
	  end
	  
	  begin
	    //monitor DUT outputs
        forever begin
          axi_tx_out = axi_transaction::type_id::create("axi_tx_out");
	      get_outputs();
	     `uvm_info("OUTPUT MON", $sformatf("%s", axi_tx_out.convert2str()), UVM_MEDIUM)
	      @(posedge vif.clock);
		  // collect each beat in a array and drive only when completed
	      if (completed_write_out | completed_read_out) begin
		   //`uvm_info("AR_R_MON", "Pushing AR+R to scoreboard", UVM_LOW)
		    if (completed_read_out) begin
			  //if (axi_tx.axi_req_i.ar.burst != 'b00) begin
			    for (int i = 0; i < completed_r_beats; ++i)
		          axi_tx_out.burst_data[i] = burst_data_out[i];
			  //end
			  axi_tx_out.done_read = 1;
			end
	       `uvm_info("R MON", $sformatf("Trans Burst data = %p", axi_tx_out.burst_data), UVM_HIGH)
		    dut_out_tx_port.write(axi_tx_out);
			completed_read_out = 0;
			completed_ar_phase = 0;
			completed_r_burst = 0;
            completed_r_beats = 0;
		    completed_write_out = 0;
		  end
	    end
	  end
    join
  endtask
  
  virtual task automatic get_inputs();
    
	axi_tx.rst_ni = vif.rst_ni;
	axi_tx.axi_req_i = vif.axi_req_i;

    if (vif.axi_req_i.aw_valid && vif.axi_resp_o.aw_ready) begin //{ Address to scoreboard
      completed_aw_phase = 1;
	  axi_tx.READ_WRITE = 1;
	 `uvm_info("AW MON", $sformatf("AW Phase = %b", completed_aw_phase), UVM_MEDIUM)
    end //}
    
    if (vif.axi_req_i.w_valid && vif.axi_resp_o.w_ready) begin //{Data to scoreboard
	  //if (axi_tx.axi_req_i.aw.burst != 'b00) begin
        burst_data[completed_w_beats] = vif.axi_req_i.w.data;
       `uvm_info("W MON", $sformatf("Burst data = %p", burst_data), UVM_HIGH)
	  //end
      //else begin
      //  axi_tx.axi_req_i.w.data = vif.axi_req_i.w.data;
	  // `uvm_info("W MON", $sformatf("Data written to memory = 0x%0h", axi_tx.axi_req_i.w.data), UVM_HIGH)
	  //end
      completed_w_beats += 1;
     `uvm_info("W MON", $sformatf("W Phase beat number = %d", completed_w_beats), UVM_MEDIUM) 
      if (axi_tx.axi_req_i.w.last) begin
        completed_w_burst = 1;
        axi_tx.READ_WRITE = 1;
	   `uvm_info("W MON", $sformatf("W Phase completed = %b", completed_w_burst), UVM_MEDIUM)
      end
    end //}
    
	if (vif.axi_req_i.ar_valid && vif.axi_resp_o.ar_ready) begin // {
      completed_ar_phase = 1;
	end

	completed_write_in = completed_aw_phase && completed_w_burst;
	completed_read_in = completed_ar_phase;
	

  endtask 

  virtual task automatic get_outputs();
  
	axi_tx_out.axi_resp_o = vif.axi_resp_o;
	axi_tx_out.done_read = vif.axi_resp_o.r_valid;
	axi_tx_out.mon_w_valid_o = vif.mon_w_valid_o;
	axi_tx_out.mon_w_data_o = vif.mon_w_data_o;
	axi_tx_out.mon_w_id_o = vif.mon_w_id_o;
	axi_tx_out.mon_w_addr_o = vif.mon_w_addr_o;
	axi_tx_out.mon_w_user_o = vif.mon_w_user_o;
	axi_tx_out.mon_w_beat_count_o = vif.mon_w_beat_count_o;
	axi_tx_out.mon_w_last_o = vif.mon_w_last_o;

	axi_tx_out.mon_r_valid_o = vif.mon_r_valid_o;
	axi_tx_out.mon_r_last_o = vif.mon_r_last_o;
	axi_tx_out.mon_r_addr_o = vif.mon_r_addr_o;
	axi_tx_out.mon_r_data_o = vif.mon_r_data_o;
	axi_tx_out.mon_r_id_o = vif.mon_r_id_o;
	axi_tx_out.mon_r_user_o = vif.mon_r_user_o;
	axi_tx_out.mon_r_beat_count_o = vif.mon_r_beat_count_o;
	axi_tx_out.mon_r_id_o = vif.mon_r_id_o;


    if (vif.axi_req_i.ar_valid && vif.axi_resp_o.ar_ready) begin //{ Address to scoreboard
      completed_ar_phase = 1;
	  axi_tx.READ_WRITE = 0;
	 `uvm_info("AR MON", $sformatf("AR Phase = %b", completed_ar_phase), UVM_MEDIUM)
    end //}
    
    if (vif.axi_resp_o.r_valid && vif.axi_req_i.r_ready) begin //{Data to scoreboard
      //if (axi_tx_out.axi_req_i.ar.burst == 'b00) begin
	  //  axi_tx_out.axi_resp_o.r.data = vif.axi_resp_o.r.data;
	  // `uvm_info("R MON", $sformatf("data read from DUT = 0x%0h", axi_tx_out.axi_resp_o.r.data), UVM_MEDIUM)
	  //end
	  //else begin
	    burst_data_out[completed_r_beats] = vif.axi_resp_o.r.data;
	   `uvm_info("R MON", $sformatf("Burst data = %p", burst_data_out), UVM_MEDIUM)
      //end
 
	  completed_r_beats += 1;
     `uvm_info("R MON", $sformatf("R Phase beat number = %d", completed_r_beats), UVM_MEDIUM) 
      if (completed_r_beats == (vif.axi_req_i.ar.len+1)) begin
        completed_r_burst = 1;

	   `uvm_info("R MON", $sformatf("R Phase completed = %b", completed_r_burst), UVM_MEDIUM)
      end
    end //}

	completed_write_out = completed_aw_phase && completed_w_burst;
    completed_read_out = completed_ar_phase && completed_r_burst;

  endtask

endclass
