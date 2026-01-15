class axi_scoreboard extends uvm_scoreboard;
 
 `uvm_analysis_imp_decl(_in)
 `uvm_analysis_imp_decl(_out)

 `uvm_component_utils(axi_scoreboard);
  
  // create handles for axi transaction
  axi_transaction tx_in;
  axi_transaction tx_out;

  axi_transaction tx_in_d;  // this is for burst transactions
  int axi_size;
  int axi_size_r;
  axi_transaction tx_out_d;
  axi_transaction tx_in_r_d;
  
  bit done_read;
  logic [3:0] w_cnt = 0;
  logic [3:0] r_cnt = 0;
  bit input_got;
  bit output_got;
  logic [31:0] burst_addr;
  logic [31:0] wrap_boundary;
  logic [31:0] wrap_boundary_r;
  logic [31:0] burst_addr_r;

  logic [31:0] comp_addr;
  logic [31:0] wrapping_addr_r;
  logic [31:0] wrapping_addr;

  // implementation of the export from monitor
  uvm_analysis_imp_in #(axi_transaction, axi_scoreboard) in_imp;
  uvm_analysis_imp_out #(axi_transaction, axi_scoreboard) out_imp;
  
  // put the collections from monitor to the FIFO
  uvm_tlm_analysis_fifo #(axi_transaction) in_fifo;
  uvm_tlm_analysis_fifo #(axi_transaction) out_fifo;

  int item_q[*]; // internal associative array to store data with address as index
  int actual_item_q[*]; // internal associative array to store data with address as index
  logic [DATA_WIDTH-1:0] actual_output [10];
  logic [DATA_WIDTH-1:0] expected_output [10];


  function new(string name="axi_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction
  // Scoreboard implementation for AXI
  // Since AXI allows out-of-order transactions should not use queue, use
  // a assocative array
   


  function void build_phase (uvm_phase phase);
    super.build_phase(phase);

	in_fifo = new("in_fifo", this);
	out_fifo = new("out_fifo", this);
    in_imp = new("in_imp", this);
	out_imp = new("out_imp", this);
  endfunction: build_phase
  
  function void write_in (axi_transaction t);
    in_fifo.write(t);
  endfunction: write_in

  function void write_out (axi_transaction t);
    out_fifo.write(t);
  endfunction: write_out

  function void connect_phase (uvm_phase phase);
	super.connect_phase(phase);
	//in_imp.connect(in_fifo.analysis_export);
	//out_imp.connect(out_fifo.analysis_export);	
  endfunction: connect_phase
  

  task run_phase (uvm_phase phase);
    tx_in = new();
	tx_out = new();
	tx_in_d = new();
    tx_in_r_d = new();
    
	//actual_output = new[10];
	//expected_output = new[10];
	
	forever begin //{
	  input_got = 0;
	  output_got = 0;

	  //fork //{ 

	   
		// Process both DUT input and output monitor transaction
	    begin
          in_fifo.get(tx_in);
	     `uvm_info("SCOREBOARD TX IN", $sformatf("%s", tx_in.convert2str()), UVM_HIGH)
		  input_got = 1;
		end
	           
		begin
          out_fifo.get(tx_out);
		 `uvm_info("SCOREBOARD TX OUT", $sformatf("%s", tx_out.convert2str()), UVM_HIGH)
		  output_got = 1;
		end

		begin
		  if (input_got && output_got) begin
		   if (tx_in.READ_WRITE == 1) begin
		     process_aw(tx_in, tx_out);
		     process_w(tx_in, tx_out);
		   end
		  end
		  //process_b();
		end

		begin
          if (input_got && output_got) begin
		    if (tx_in.READ_WRITE == 0 && tx_out.done_read) begin
              process_ar(tx_in, tx_out);
			  process_r(tx_in, tx_out);
			end
		  end
		end

		input_got = 1;
		output_got = 1;

	  //join //}

	  //disable fork;

      if (tx_out.done_read && done_read) begin // wait for read data to be available to the scoreboard {
	   `uvm_info("SCOREBOARD", $sformatf("DONE_READ"), UVM_NONE)
		//if (tx_in.READ_WRITE == 0) begin
		for (int i = 0; i <= tx_in.axi_req_i.ar.len; ++i) begin
		  if (tx_in.axi_req_i.ar.burst == 'b10) // For wrapping burst formulation is different
		    comp_addr = ((tx_in.axi_req_i.ar.addr / wrap_boundary_r) * wrap_boundary_r) +  (tx_in.axi_req_i.ar.addr + ((burst_addr_r * i) % wrap_boundary_r)) % wrap_boundary_r;
          else
		    comp_addr = tx_in.axi_req_i.ar.addr + (burst_addr_r * i);
		 `uvm_info("COMPARISON", $sformatf("Comparison addr = 0x%0h", comp_addr), UVM_LOW)
		  if (item_q[comp_addr] != actual_item_q[comp_addr]) begin
           `uvm_error("SCOREBOARD", $sformatf("MISMATCH ACT=0x%0h EXP=0x%0h", actual_item_q[comp_addr], item_q[comp_addr]))
		  end

		  else begin 
           `uvm_info("SCOREBOARD", $sformatf("DATA READ BACK SUCCESSFULLY ACT=0x%0h EXP=0x%0h", actual_item_q[comp_addr], item_q[comp_addr]), UVM_INFO)
          end
		end
		//end
      end //}
	end //}

  endtask: run_phase
  
  virtual function automatic void process_aw (axi_transaction tx_in, axi_transaction tx_out);
   `uvm_info("FUNC TX IN", $sformatf("%s", tx_in.convert2str()), UVM_HIGH) 
    
	  // In this function calculate the burst increment address for the burst
	 `uvm_info(get_full_name(), $sformatf("Burst type = %0b", tx_in.axi_req_i.aw.burst), UVM_MEDIUM)
	 
      if (tx_in.axi_req_i.aw.burst == 2'b00) begin  //{ fixed burst, single beat
	   `uvm_info(get_full_name(), "Calculating burst addr for fixed address", UVM_MEDIUM)
        burst_addr = 0;
		wrap_boundary = 0;
	   `uvm_info(get_full_name(), $sformatf("burst addr = %d", burst_addr), UVM_LOW)
      end //}

      else if (tx_in.axi_req_i.aw.burst == 'b01) begin //{ incremental burst
	   `uvm_info(get_full_name(), "Calculating burst addr for incremental burst", UVM_MEDIUM)
        burst_addr = (1 << tx_in.axi_req_i.aw.size);
		wrap_boundary = 0;
	   `uvm_info(get_full_name(), $sformatf("burst addr = %d", burst_addr), UVM_LOW)
      end //}

      else if (tx_in.axi_req_i.aw.burst == 'b10) begin //{
	   `uvm_info(get_full_name(), "Calculating burst addr for wrapping burst", UVM_MEDIUM)
	    burst_addr = (1 << tx_in.axi_req_i.aw.size);
	    wrap_boundary = burst_addr * (tx_in.axi_req_i.aw.len + 1);  
	   `uvm_info(get_full_name(), $sformatf("Wrap boundary = %d", wrap_boundary), UVM_LOW)
	   `uvm_info(get_full_name(), $sformatf("Wrapping burst addr = %d", burst_addr), UVM_LOW)

      end //}

	//end

  endfunction

  virtual function automatic void process_w (axi_transaction tx_in, axi_transaction tx_out);
    
	//if (tx_in.axi_req_i.w_valid & tx_out.axi_resp_o.w_ready) begin
	if (tx_in.axi_req_i.aw.burst != 'b10) begin //{
      for (int i = 0; i <= tx_in.axi_req_i.aw.len; ++i) begin //{ 
       `uvm_info(get_full_name(), "Burst writing", UVM_LOW)
       `uvm_info(get_full_name(), $sformatf("Burst data = %p",tx_in.burst_data), UVM_MEDIUM)
       `uvm_info(get_full_name(), $sformatf("Single data = %h",tx_in.burst_data[i]), UVM_MEDIUM)
        item_q[tx_in.axi_req_i.aw.addr + (burst_addr * i)] = tx_in.burst_data[i];
       `uvm_info(get_full_name(), $sformatf("Item Queue = %p", item_q), UVM_MEDIUM)
       `uvm_info(get_full_name(), $sformatf("Item Queue = %h", item_q[tx_in.axi_req_i.aw.addr + (burst_addr * i)]), UVM_MEDIUM)
      end //}
    end //}

	else if (tx_in.axi_req_i.aw.burst == 'b10) begin //{ // wrapping burst
	  for (int i = 0; i <= tx_in.axi_req_i.aw.len; ++i) begin //{ 
       `uvm_info(get_full_name(), "Wrapping burst", UVM_LOW)
	   `uvm_info(get_full_name(), $sformatf("Burst data = %p",tx_in.burst_data), UVM_MEDIUM)
       `uvm_info(get_full_name(), $sformatf("Single data = 0x%0h",tx_in.burst_data[i]), UVM_MEDIUM)
	    wrapping_addr = ((tx_in.axi_req_i.ar.addr / wrap_boundary) * wrap_boundary) +  (tx_in.axi_req_i.aw.addr + ((burst_addr * i) % wrap_boundary)) % wrap_boundary;
	    item_q[wrapping_addr] = tx_in.burst_data[i];
	   `uvm_info(get_full_name(), $sformatf("Addr = 0x%0h", wrapping_addr), UVM_MEDIUM)
	   `uvm_info(get_full_name(), $sformatf("Item Queue = 0x%0h", (item_q[wrapping_addr])), UVM_MEDIUM)
      end //}
	end //}

	//else begin
    // `uvm_info(get_full_name(), $sformatf("Single data = %p", tx_in.axi_req_i.w.data), UVM_MEDIUM)
	//  item_q[tx_in.axi_req_i.aw.addr] = tx_in.axi_req_i.w.data; 
	// `uvm_info(get_full_name(), $sformatf("Item Queue = %p", item_q), UVM_MEDIUM)
    // `uvm_info(get_full_name(), $sformatf("Item Queue = %h", item_q[tx_in.axi_req_i.aw.addr]), UVM_MEDIUM)
    //end

  endfunction

  virtual function automatic void process_ar (axi_transaction tx_in, axi_transaction tx_out);
   `uvm_info("FUNC TX IN", $sformatf("%s", tx_in.convert2str()), UVM_HIGH) 
    
	//if (tx_in.axi_req_i.aw_valid & tx_out.axi_resp_o.aw_ready) begin
	  // In this function calculate the burst increment address for the burst

	 `uvm_info(get_full_name(), $sformatf("Read Burst type = %0b", tx_in.axi_req_i.ar.burst), UVM_MEDIUM)
      if (tx_in.axi_req_i.ar.burst == 2'b00) begin  //{ Fixed
       `uvm_info(get_full_name(), "Calculating Fixed Read burst addr", UVM_MEDIUM)
		burst_addr_r = 0;
		wrap_boundary = 0;
	   `uvm_info(get_full_name(), $sformatf("burst addr = 0x%0h", burst_addr_r), UVM_MEDIUM)
      end //}

      else if (tx_in.axi_req_i.ar.burst == 'b01) begin //{ incremental burst
       `uvm_info(get_full_name(), "Calculating Read incremental burst addr", UVM_MEDIUM)
		burst_addr_r = (1 << tx_in.axi_req_i.ar.size);
		wrap_boundary = 0;
	   `uvm_info(get_full_name(), $sformatf("burst addr = 0x%0h", burst_addr_r), UVM_MEDIUM)
      end //}


      else if (tx_in.axi_req_i.ar.burst == 'b10) begin //{
       `uvm_info(get_full_name(), "Calculating Read wrapping burst addr", UVM_MEDIUM)
		burst_addr_r = (1 << tx_in.axi_req_i.ar.size);
	   `uvm_info(get_full_name(), $sformatf("burst addr = 0x%0h", burst_addr_r), UVM_MEDIUM)
	    wrap_boundary_r = (1 << tx_in.axi_req_i.aw.size) * (tx_in.axi_req_i.aw.len + 1);  
	   `uvm_info(get_full_name(), $sformatf("Wrap boundary = 0x%0h", wrap_boundary_r), UVM_LOW)
	   `uvm_info(get_full_name(), $sformatf("Wrapping burst addr = 0x%0h", burst_addr), UVM_LOW)
      end //}


	//end

  endfunction

  virtual function automatic void process_r (axi_transaction tx_in, axi_transaction tx_out);
    
	//if (tx_in.axi_req_i.w_valid & tx_out.axi_resp_o.w_ready) begin
	//if (tx_in.axi_req_i.w_valid & tx_out.axi_resp_o.w_ready) begin
	if (tx_in.axi_req_i.ar.burst !== 'b10) begin //{
      for (int i = 0; i <= tx_in.axi_req_i.ar.len; ++i) begin //{ 
       `uvm_info(get_full_name(), "Burst reading", UVM_LOW)
       `uvm_info(get_full_name(), $sformatf("Burst data = %p",tx_out.burst_data), UVM_MEDIUM)
       `uvm_info(get_full_name(), $sformatf("Single data = %h",tx_out.burst_data[i]), UVM_MEDIUM)
        actual_item_q[tx_in.axi_req_i.ar.addr + (burst_addr_r * i)] = tx_out.burst_data[i];
       `uvm_info(get_full_name(), $sformatf("Item Queue = %p", actual_item_q), UVM_MEDIUM)
       `uvm_info(get_full_name(), $sformatf("Item Queue = %h", actual_item_q[tx_in.axi_req_i.ar.addr + (burst_addr_r * i)]), UVM_MEDIUM)
      end //}
    end //}	
	
	else if (tx_in.axi_req_i.ar.burst === 'b10) begin
	  for (int i = 0; i <= tx_in.axi_req_i.ar.len; ++i) begin //{ 
       `uvm_info(get_full_name(), "Burst Reading", UVM_LOW)
       `uvm_info(get_full_name(), $sformatf("Burst data = %p", tx_out.burst_data), UVM_MEDIUM)
       `uvm_info(get_full_name(), $sformatf("Single data = %0d", tx_out.burst_data[i]), UVM_MEDIUM)
	   `uvm_info(get_full_name(), $sformatf("Wrap boundary = 0x%0h", wrap_boundary_r), UVM_LOW)
	    wrapping_addr_r = ((tx_in.axi_req_i.ar.addr / wrap_boundary_r) * wrap_boundary_r) +  (tx_in.axi_req_i.ar.addr + ((burst_addr_r * i) % wrap_boundary_r)) % wrap_boundary_r;
	   `uvm_info(get_full_name(), $sformatf("Reading burst Addr = 0x%0h", wrapping_addr_r), UVM_LOW)
        actual_item_q[wrapping_addr_r] = tx_out.burst_data[i];
       `uvm_info(get_full_name(), $sformatf("Item Queue = %p", actual_item_q), UVM_MEDIUM)
       `uvm_info(get_full_name(), $sformatf("Item Queue = %h", actual_item_q[wrapping_addr_r]), UVM_MEDIUM)
      end //}
    end


    done_read = 1;
	//end

  endfunction
  

endclass: axi_scoreboard
