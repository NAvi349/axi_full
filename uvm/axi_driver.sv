class axi_driver extends uvm_driver #(axi_transaction);
 // Register with factory
 // get the axi_if from config_db
 // in run phase drive the dut
 //
 `uvm_component_utils(axi_driver)

  virtual axi_if axi_if0;

  function new (string name = "axi_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

	if (!uvm_config_db #(virtual axi_if)::get(this, "", "axi_if", axi_if0))
	 `uvm_fatal("DRIVER", "Could not AXI IF from config db")

  endfunction: build_phase
  
  task run_phase(uvm_phase phase);
    
	uvm_sequence_item tx;
	axi_transaction axi_tx;

	int i = 0;
    
	reset_dut();
	forever begin
      seq_item_port.get_next_item(tx);
	  $cast(axi_tx, tx);

	  @(axi_if0.clock);
	  
	  if (axi_tx.READ_WRITE == 0) begin
	    //drive_read(axi_tx);
		drive_burst_read_address(axi_tx);
		drive_burst_read(axi_tx);
	  end

	  else if (axi_tx.READ_WRITE == 1) begin
	    //if (axi_tx.axi_req_i.aw.burst == 0)
	    //  drive_write(axi_tx);
	    drive_burst_write_address(axi_tx);
		axi_tx.first = 0;
	    $display("Writing data channel"); 
		drive_burst_write(axi_tx);
      end

	  seq_item_port.item_done();
	end
  endtask: run_phase
  

  virtual task reset_dut();
    @(axi_if0.clock);
     //axi_if0.axi_req_i <= 0;
	  
	@(axi_if0.clock);
  endtask: reset_dut

  virtual task drive_write(axi_transaction tx);

	  axi_if0.axi_req_i.aw.addr <= tx.axi_req_i.aw.addr;
	  axi_if0.axi_req_i.aw.len <= tx.axi_req_i.aw.len;
	  axi_if0.axi_req_i.aw.id  <= tx.axi_req_i.aw.id;
	  axi_if0.axi_req_i.aw.size <= tx.axi_req_i.aw.size;
	  axi_if0.axi_req_i.w.data <= tx.axi_req_i.w.data;
	  axi_if0.axi_req_i.w.strb <= tx.axi_req_i.w.strb;
      axi_if0.axi_req_i.w.last <= tx.axi_req_i.w.last;
	  //axi_if0.mem_gnt_i        <= '1;
	  // These three should be drive to do proper write
	  axi_if0.axi_req_i.b_ready <= 1'b1;
	  axi_if0.axi_req_i.aw_valid <= 1'b1;
	  axi_if0.axi_req_i.w_valid <= 1'b1;

      while (!axi_if0.axi_resp_o.aw_ready)
	 @(posedge axi_if0.clock);

	 `uvm_info(get_full_name(), "Got AW Ready", UVM_LOW)

	 @(posedge axi_if0.clock);
	  axi_if0.axi_req_i.aw_valid <= 1'b0;

	  while (!axi_if0.axi_resp_o.w_ready)
	 @(posedge axi_if0.clock);

	 `uvm_info(get_full_name(), "Got W Ready", UVM_LOW)
	  axi_if0.axi_req_i.w_valid <= 1'b0;

	  while (!axi_if0.axi_resp_o.b_valid)
	 @(posedge axi_if0.clock);

	 `uvm_info(get_full_name(), "Got B Valid", UVM_LOW)
	 
	 @(posedge axi_if0.clock);
	  axi_if0.axi_req_i <= 1'b0;
	  

  endtask: drive_write

  virtual task drive_read(axi_transaction tx);
    
	axi_if0.axi_req_i.ar.addr <= tx.axi_req_i.ar.addr;
	axi_if0.axi_req_i.r_ready <= 1'b1;
	axi_if0.axi_req_i.ar_valid <= 1'b1;
	axi_if0.axi_req_i.ar.len <= tx.axi_req_i.ar.len;
	axi_if0.axi_req_i.ar.id  <= tx.axi_req_i.ar.id;
	axi_if0.axi_req_i.ar.size <= tx.axi_req_i.ar.size;
	//axi_if0.axi_req_i.w.strb <= tx.axi_req_i.w.strb;
    

    //axi_if0.mem_rvalid_i <= 1'b1;

    while (!axi_if0.axi_resp_o.r_valid)
	@(posedge axi_if0.clock);

    while (!axi_if0.mon_r_valid_o)
	@(posedge axi_if0.clock);
  
   `uvm_info(get_full_name(), $sformatf("Got R Valid"), UVM_LOW)
   `uvm_info(get_full_name(), $sformatf("Read data = %h", axi_if0.axi_resp_o.r.data), UVM_INFO);
    
	axi_if0.axi_req_i.ar_valid <= 1'b0;
	axi_if0.axi_req_i.r_ready <= 1'b0;

  endtask

  virtual task drive_burst_write(axi_transaction tx);
	    axi_if0.axi_req_i.b_ready <= 1'b1;
    for (int i = 0; i <= tx.axi_req_i.aw.len; ++i) begin
	  axi_if0.axi_req_i.w.data <= tx.burst_data[i];
	  axi_if0.axi_req_i.w.strb <= tx.axi_req_i.w.strb;
      axi_if0.axi_req_i.w.last <= (i == (tx.axi_req_i.aw.len));

	  axi_if0.axi_req_i.w_valid <= 1'b1;
     @(posedge axi_if0.clock);

	  while (!axi_if0.axi_resp_o.w_ready)
	 @(posedge axi_if0.clock);

	 `uvm_info(get_full_name(), "Got W Ready", UVM_LOW)
	  axi_if0.axi_req_i.w_valid <= 1'b0;
     @(posedge axi_if0.clock);

	end


	 @(posedge axi_if0.clock);

	 if (axi_if0.axi_req_i.w.last == 1) begin
	   while (!axi_if0.axi_resp_o.b_valid)
	  @(posedge axi_if0.clock);

	 `uvm_info(get_full_name(), "Got B Valid", UVM_LOW)
	  axi_if0.axi_req_i.b_ready <= 1'b0; 
	  @(posedge axi_if0.clock);
	  //axi_if0.axi_req_i <= 1'b0;
	 end
	  

  endtask: drive_burst_write

  virtual task drive_burst_write_address(axi_transaction tx);

	  axi_if0.axi_req_i.aw.addr <= tx.axi_req_i.aw.addr;
	  axi_if0.axi_req_i.aw.len <= tx.axi_req_i.aw.len;
	  axi_if0.axi_req_i.aw.id  <= tx.axi_req_i.aw.id;
	  axi_if0.axi_req_i.aw.size <= tx.axi_req_i.aw.size;
	  axi_if0.axi_req_i.w.data <= 0;
	  axi_if0.axi_req_i.w.strb <= 0;
      axi_if0.axi_req_i.w.last <= 0;
	  axi_if0.axi_req_i.aw.burst <= tx.axi_req_i.aw.burst;
	  //axi_if0.mem_gnt_i        <= '1;
	  // These three should be drive to do proper write
	  axi_if0.axi_req_i.b_ready <= 1'b0;
	  axi_if0.axi_req_i.aw_valid <= 1'b1;
	  axi_if0.axi_req_i.w_valid <= 1'b0;
     @(posedge axi_if0.clock);

      while (!axi_if0.axi_resp_o.aw_ready)
	 @(posedge axi_if0.clock);

	  axi_if0.axi_req_i.aw_valid <= 1'b0;

	 `uvm_info(get_full_name(), "Got AW Ready", UVM_LOW)
      @(posedge axi_if0.clock);


  endtask: drive_burst_write_address

  virtual task drive_burst_read_address(axi_transaction tx);
    
	axi_if0.axi_req_i.ar.addr <= tx.axi_req_i.ar.addr;
	//axi_if0.axi_req_i.r_ready <= 1'b1;
	axi_if0.axi_req_i.ar_valid <= 1'b1;
	axi_if0.axi_req_i.ar.len <= tx.axi_req_i.ar.len;
	axi_if0.axi_req_i.ar.id  <= tx.axi_req_i.ar.id;
	axi_if0.axi_req_i.ar.size <= tx.axi_req_i.ar.size;
	axi_if0.axi_req_i.ar.burst <= tx.axi_req_i.ar.burst;
	//axi_if0.axi_req_i.r.strb <= tx.axi_req_i.r.strb;

    //axi_if0.mem_rvalid_i <= 1'b1;
	@(posedge axi_if0.clock);
	
    while (!axi_if0.axi_resp_o.ar_ready)
	@(posedge axi_if0.clock);
   
   `uvm_info(get_full_name(), $sformatf("Got AR Ready"), UVM_LOW)
	
	axi_if0.axi_req_i.r_ready <= 1'b1; 
 
	axi_if0.axi_req_i.ar_valid <= 1'b0;

	@(posedge axi_if0.clock);

  endtask: drive_burst_read_address

  virtual task drive_burst_read(axi_transaction tx);
    
	//axi_if0.axi_req_i.r_ready <= 1'b1; 
	@(posedge axi_if0.clock);

	for (int i = 0; i <= tx.axi_req_i.ar.len; ++i) begin  
      
     //while (!axi_if0.axi_resp_o.r_valid)
	 //@(posedge axi_if0.clock);
   
     `uvm_info(get_full_name(), $sformatf("Got R Valid"), UVM_LOW)
     `uvm_info(get_full_name(), $sformatf("Read data = %h", axi_if0.axi_resp_o.r.data), UVM_INFO);      
      
	 @(posedge axi_if0.clock);
      	 
	end
    	
    @(posedge axi_if0.clock);
	axi_if0.axi_req_i.r_ready <= 1'b0; 
	
    @(posedge axi_if0.clock);

	

  endtask: drive_burst_read

endclass
