class axi_monitor extends uvm_monitor;
  
 `uvm_component_utils(axi_monitor)
  
  virtual axi_if vif;

  axi_transaction axi_tx;
  axi_transaction axi_tx_out;

  logic [31:0] burst_data[10] = '{default:32'd0}; 
  logic [5:0] completed_w_beats[10] = '{default:6'd0};
  logic completed_w_burst[10] = '{default:'d0};
  logic completed_aw_phase[10] = '{default:'d0};
  logic completed_write_in[10] = '{default:'d0};

  
  logic [31:0] burst_data_out[10] = '{default:32'd0};
  logic [5:0] completed_r_beats[10] = '{default:6'd0};
  logic completed_r_burst[10] = '{default:'d0};
  logic completed_ar_phase[10] = '{default:'d0};
  logic completed_read_out[10] = '{default:'d0};
 
  int aw_id_q[$]; //for storing AW ID
  int ar_id_q[$]; //for storing AR ID
  
  req_t axi_tx_q[$];
  req_t axi_tx_out_q[$];
  logic completed_in = 0;
  logic completed_out = 0;

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
	     `uvm_info("WRITE_MON", $sformatf("%s", axi_tx.convert2str()), UVM_MEDIUM)
	      @(posedge vif.clock);
		  // collect each beat completed and drive only when completed
		 `uvm_info("WRITE_MON", $sformatf("Completed write_in = %p", completed_write_in), UVM_LOW)

		  if (completed_write_in[aw_id_q[0]]) begin
            if (completed_write_in[aw_id_q[0]]) begin 
		     `uvm_info("WRITE_MON", "Burst data copying", UVM_LOW)
			 `uvm_info("WRITE_MON", $sformatf("%p", completed_w_beats), UVM_LOW)
			  for (int i = 0; i < completed_w_beats[aw_id_q[0]]; ++i)
		        axi_tx.burst_data[i] = burst_data[i];
			  
			  axi_tx.READ_WRITE = 1;
			  axi_tx.axi_req_i.aw.len = axi_tx_q[0].aw.len;
			  axi_tx.axi_req_i.aw.id = axi_tx_q[0].aw.id;
			  axi_tx.axi_req_i.aw.addr = axi_tx_q[0].aw.addr;
			  axi_tx.axi_req_i.aw.size = axi_tx_q[0].aw.size;
			  axi_tx.axi_req_i.aw.burst = axi_tx_q[0].aw.burst;
		      
			  axi_tx_q.pop_front();
			end



		   `uvm_info("WRITE_MON", $sformatf("Burst data = %p", axi_tx.burst_data), UVM_HIGH)
		   `uvm_info("WRITE_MON", $sformatf("Read Write = %d", axi_tx.READ_WRITE), UVM_HIGH)
	       `uvm_info("WRITE_MON", $sformatf("%s", axi_tx.convert2str()), UVM_MEDIUM)
		   `uvm_info("WRITE_MON", $sformatf("Addr=0x%0h", axi_tx.axi_req_i.ar.addr), UVM_MEDIUM)	
			dut_in_tx_port.write(axi_tx);
		    completed_aw_phase[aw_id_q[0]] = 0;
			completed_write_in[aw_id_q[0]] = 0;
			completed_w_burst[aw_id_q[0]] = 0;
			completed_w_beats[aw_id_q[0]] = 0;
			  //aw_id_q.pop_front();  //delete id after its w phase is compeleted
            //completed_in = 1;
			            aw_id_q.pop_front(); // delete write after write is complete

		  end

	    end
	  end
	  
	  begin
	    //monitor DUT outputs
        forever begin
          axi_tx_out = axi_transaction::type_id::create("axi_tx_out");
	      get_outputs();
	     `uvm_info("READ_MON", $sformatf("%s", axi_tx_out.convert2str()), UVM_MEDIUM)
	      @(posedge vif.clock);
		  // collect each beat in a array and drive only when completed
		 `uvm_info("READ_MON", $sformatf("Completed read_out = %p", completed_read_out), UVM_LOW)
	      if (completed_read_out[ar_id_q[0]]) begin
		   
		    if (completed_read_out[ar_id_q[0]]) begin
			  for (int i = 0; i < completed_r_beats[ar_id_q[0]]; ++i)
		          axi_tx_out.burst_data[i] = burst_data_out[i];
			  
			  axi_tx_out.done_read = 1;
			  axi_tx_out.READ_WRITE = 1; 
			  
			  axi_tx_out.axi_req_i.ar.len = axi_tx_out_q[0].ar.len;
			  axi_tx_out.axi_req_i.ar.id = axi_tx_out_q[0].ar.id;
			  axi_tx_out.axi_req_i.ar.addr = axi_tx_out_q[0].ar.addr;
			  axi_tx_out.axi_req_i.ar.size = axi_tx_out_q[0].ar.size;
			  axi_tx_out.axi_req_i.ar.burst = axi_tx_out_q[0].ar.burst;
              
			  axi_tx_out_q.pop_front();
			end
	       `uvm_info("READ_MON", $sformatf("Read Burst data to scoreboard = %p", axi_tx_out.burst_data), UVM_HIGH)
		    dut_out_tx_port.write(axi_tx_out);
			completed_read_out[ar_id_q[0]] = 0;
			completed_ar_phase[ar_id_q[0]] = 0;
			completed_r_burst[ar_id_q[0]] = 0;
            completed_r_beats[ar_id_q[0]] = 0;
			//ar_id_q.pop_front(); // delete ar read id after read is complete
			            ar_id_q.pop_front(); // delete ar read id after read is complete
			//completed_out = 1;
		  end
	    end
	  end
	  
    join
  endtask
  
  virtual task automatic get_inputs();
    
	axi_tx.rst_ni = vif.rst_ni;
	axi_tx.axi_req_i = vif.axi_req_i;

    if (vif.axi_req_i.aw_valid && vif.axi_resp_o.aw_ready) begin //{ Address to scoreboard
	  aw_id_q.push_back(vif.axi_req_i.aw.id);    
     `uvm_info("INPUT_MON", $sformatf("ID queue = %p", aw_id_q), UVM_LOW) 
	  axi_tx_q.push_back(axi_tx.axi_req_i);
      completed_aw_phase[vif.axi_req_i.aw.id] = 1;
	  axi_tx.READ_WRITE = 1;
	 `uvm_info("INPUT_MON", $sformatf("AW Phase = %b", completed_aw_phase[aw_id_q[$-1]]), UVM_MEDIUM)
	 `uvm_info("INPUT_MON", $sformatf("Conpleted AW Phase = %p", completed_aw_phase), UVM_MEDIUM)

    end //}
    
    if (vif.axi_req_i.w_valid && vif.axi_resp_o.w_ready) begin //{Data to scoreboard
	  //if (axi_tx.axi_req_i.aw.burst != 'b00) begin
        burst_data[completed_w_beats[aw_id_q[0]]] = vif.axi_req_i.w.data;
       `uvm_info("INPUT_MON", $sformatf("Burst data = %p", burst_data), UVM_HIGH)
      completed_w_beats[aw_id_q[0]] += 1;
     `uvm_info("INPUT_MON", $sformatf("W Phase beat number = %d", completed_w_beats[aw_id_q[0]]), UVM_MEDIUM) 
      if (axi_tx.axi_req_i.w.last) begin
        completed_w_burst[aw_id_q[0]] = 1;
        axi_tx.READ_WRITE = 1;
	   `uvm_info("INPUT_MON", $sformatf("W Phase completed = %b", completed_w_burst[aw_id_q[0]]), UVM_MEDIUM)
      end


    end //}
    
	if (vif.axi_req_i.ar_valid && vif.axi_resp_o.ar_ready) begin // {
      completed_ar_phase[vif.axi_req_i.ar.id] = 1;
	  	  axi_tx_out_q.push_back(axi_tx.axi_req_i);
	end

	completed_write_in[aw_id_q[0]] = completed_aw_phase[aw_id_q[0]] && completed_w_burst[aw_id_q[0]];
	

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
      ar_id_q.push_back(vif.axi_req_i.ar.id);
	 `uvm_info("READ_MON", $sformatf("AR ID queue = %p", ar_id_q), UVM_LOW) 
	 `uvm_info("READ_MON", $sformatf("completed_ar_phase[%0d] = %0b", ar_id_q[$-1], completed_ar_phase[ar_id_q[$-1]]), UVM_MEDIUM)
	  completed_ar_phase[vif.axi_req_i.ar.id] = 1;
	  axi_tx.READ_WRITE = 0;
	 `uvm_info("READ_MON", $sformatf("AR Phase = %p", completed_ar_phase), UVM_MEDIUM)
	 `uvm_info("MON_ID", $sformatf("AR ID queue 1 = %p", ar_id_q), UVM_MEDIUM)
	 `uvm_info("READ_MON", $sformatf("completed_ar_phase[%0d] = %0b", ar_id_q[$-1], completed_ar_phase[ar_id_q[$-1]]), UVM_MEDIUM)
    end //}
    
    if (vif.axi_resp_o.r_valid && vif.axi_req_i.r_ready) begin //{Data to scoreboard
	  burst_data_out[completed_r_beats[ar_id_q[0]]] = vif.axi_resp_o.r.data;
	 `uvm_info("READ_MON", $sformatf("Burst data = %p", burst_data_out), UVM_MEDIUM)
     
 
	  completed_r_beats[ar_id_q[0]] += 1;
     `uvm_info("READ_MON", $sformatf("R Phase beat number = %d", completed_r_beats[ar_id_q[0]]), UVM_MEDIUM) 
      if (completed_r_beats[ar_id_q[0]] == (vif.axi_req_i.ar.len+1)) begin
        completed_r_burst[ar_id_q[0]] = 1;
       `uvm_info("READ_MON", $sformatf("R Phase completed = %b", completed_r_burst[ar_id_q[0]]), UVM_MEDIUM)
      end
    end //}

   `uvm_info("READ_MON", $sformatf("AR Phase full = %p", completed_ar_phase), UVM_MEDIUM)
   `uvm_info("READ_MON", $sformatf("R Phase full completed = %p", completed_r_burst), UVM_MEDIUM)

    completed_read_out[ar_id_q[0]] = completed_ar_phase[ar_id_q[0]] && completed_r_burst[ar_id_q[0]];

  endtask

endclass
