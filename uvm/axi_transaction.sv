// Input transaction

class axi_transaction extends uvm_sequence_item;
  // declare the dut ports items
  // DUT inputs

  logic rst_ni;
  req_t axi_req_i;

  logic READ_WRITE;
  logic [1:0] addr_data;
  logic first_read;
  
  logic [31:0] burst_data[10];


  // DUT outputs
  resp_t axi_resp_o;
  logic done_read;

  logic [NUM_PORTS-1:0]                 mon_w_valid_o;
  logic [NUM_PORTS-1:0][ADDR_WIDTH-1:0] mon_w_addr_o;
  logic [NUM_PORTS-1:0][DATA_WIDTH-1:0] mon_w_data_o;
  logic [NUM_PORTS-1:0][ID_WIDTH-1:0]   mon_w_id_o;
  logic [NUM_PORTS-1:0][USER_WIDTH-1:0] mon_w_user_o;
  axi_pkg::len_t [NUM_PORTS-1:0]        mon_w_beat_count_o;
  logic [NUM_PORTS-1:0]                 mon_w_last_o;
  logic [NUM_PORTS-1:0]                 mon_r_valid_o;
  logic [NUM_PORTS-1:0][ADDR_WIDTH-1:0] mon_r_addr_o;
  logic [NUM_PORTS-1:0][DATA_WIDTH-1:0] mon_r_data_o;
  logic [NUM_PORTS-1:0][ID_WIDTH-1:0]   mon_r_id_o;
  logic [NUM_PORTS-1:0][USER_WIDTH-1:0] mon_r_user_o;
  axi_pkg::len_t [NUM_PORTS-1:0]        mon_r_beat_count_o;
  logic [NUM_PORTS-1:0]                 mon_r_last_o;

  // register with factory and macros
  `uvm_object_utils_begin(axi_transaction)
  `uvm_field_int(rst_ni, UVM_ALL_ON)
	`uvm_field_int(axi_req_i, UVM_ALL_ON)	
	`uvm_field_int(axi_resp_o, UVM_ALL_ON)
	`uvm_field_int(READ_WRITE, UVM_ALL_ON)
	`uvm_field_int(done_read, UVM_ALL_ON)
	`uvm_field_sarray_int(addr_data, UVM_ALL_ON)
	`uvm_field_int(first_read, UVM_ALL_ON)
    `uvm_field_sarray_int(burst_data, UVM_ALL_ON)
  // Write monitor signals
  `uvm_field_sarray_int(mon_w_valid_o,       UVM_ALL_ON)
  `uvm_field_sarray_int(mon_w_last_o,        UVM_ALL_ON)
  `uvm_field_sarray_int(mon_w_addr_o,        UVM_ALL_ON)   // [NUM_PORTS][ADDR_WIDTH]
  `uvm_field_sarray_int(mon_w_data_o,        UVM_ALL_ON)   // [NUM_PORTS][DATA_WIDTH]
  `uvm_field_sarray_int(mon_w_id_o,          UVM_ALL_ON)   // [NUM_PORTS][ID_WIDTH]
  `uvm_field_sarray_int(mon_w_user_o,        UVM_ALL_ON)   // [NUM_PORTS][USER_WIDTH]
  `uvm_field_sarray_int(mon_w_beat_count_o,  UVM_ALL_ON)

  // Read monitor signals
  `uvm_field_sarray_int(mon_r_valid_o,       UVM_ALL_ON)
  `uvm_field_sarray_int(mon_r_last_o,        UVM_ALL_ON)
  `uvm_field_sarray_int(mon_r_addr_o,        UVM_ALL_ON)
  `uvm_field_sarray_int(mon_r_data_o,        UVM_ALL_ON)
  `uvm_field_sarray_int(mon_r_id_o,          UVM_ALL_ON)
  `uvm_field_sarray_int(mon_r_user_o,        UVM_ALL_ON)
  `uvm_field_sarray_int(mon_r_beat_count_o,  UVM_ALL_ON)  

  `uvm_object_utils_end

  // new constructor
  function new (string name = "axi_transaction");
    super.new(name);
  endfunction

  virtual function string convert2str();
    string s;
  
    // Monitor signals
    s = $sformatf(
      "\n%-20s | %0b\n%-20s | %0d\n%-20s | %0h\n%-20s | %0h\n%-20s | %0d\n%-20s | %0b\n%-20s | %0h\n%-20s | %0h\n",
      "mon_w_valid_o",    mon_w_valid_o,
      "mon_w_beat_count", mon_w_beat_count_o,
      "mon_w_data_o",     mon_w_data_o,
      "mon_w_addr_o",     mon_w_addr_o,
      "mon_r_last_o",     mon_r_last_o,
      "mon_r_valid_o",    mon_r_valid_o,
      "mon_r_data_o",     mon_r_data_o,
      "mon_r_addr_o",     mon_r_addr_o
    );
  
    // AW channel
    s = {s, $sformatf(
      "\n%-20s | %0h\n%-20s | %0d\n%-20s | %0d\n%-20s | %0d\n%-20s | %0d\n%-20s | %0d\n%-20s | %0d\n%-20s | %0d\n%-20s | %0b\n%-20s | %0b\n",
      "AW.addr",   axi_req_i.aw.addr,
      "AW.id",     axi_req_i.aw.id,
      "AW.len",    axi_req_i.aw.len,
      "AW.size",   axi_req_i.aw.size,
      "AW.burst",  axi_req_i.aw.burst,
      "AW.lock",   axi_req_i.aw.lock,
      "AW.cache",  axi_req_i.aw.cache,
      "AW.prot",   axi_req_i.aw.prot,
      "AW.valid",  axi_req_i.aw_valid,
      "AW.ready",  axi_resp_o.aw_ready
    )};
  
    // W channel
    s = {s, $sformatf(
      "\n%-20s | %0h\n%-20s | %0h\n%-20s | %0b\n%-20s | %0b\n",
      "W.data",    axi_req_i.w.data,
      "W.strb",    axi_req_i.w.strb,
      "W.last",    axi_req_i.w.last,
      "W.valid",   axi_req_i.w_valid
    )};
  
    // AR channel
    s = {s, $sformatf(
      "\n%-20s | %0h\n%-20s | %0d\n%-20s | %0d\n%-20s | %0d\n%-20s | %0d\n%-20s | %0d\n%-20s | %0d\n%-20s | %0d\n%-20s | %0b\n%-20s | %0b\n",
      "AR.addr",   axi_req_i.ar.addr,
      "AR.id",     axi_req_i.ar.id,
      "AR.len",    axi_req_i.ar.len,
      "AR.size",   axi_req_i.ar.size,
      "AR.burst",  axi_req_i.ar.burst,
      "AR.lock",   axi_req_i.ar.lock,
      "AR.cache",  axi_req_i.ar.cache,
      "AR.prot",   axi_req_i.ar.prot,
      "AR.valid",  axi_req_i.ar_valid,
      "AR.ready",  axi_resp_o.ar_ready
    )};
  
    // B channel
    s = {s, $sformatf(
      "\n%-20s | %0d\n%-20s | %0d\n%-20s | %0b\n%-20s | %0b\n",
      "B.id",      axi_resp_o.b.id,
      "B.resp",    axi_resp_o.b.resp,
      "B.valid",   axi_resp_o.b_valid,
      "B.ready",   axi_req_i.b_ready
    )};
  
    // R channel
    s = {s, $sformatf(
      "\n%-20s | %0d\n%-20s | %0h\n%-20s | %0d\n%-20s | %0b\n%-20s | %0b\n%-20s | %0b\n",
      "R.id",      axi_resp_o.r.id,
      "R.data",    axi_resp_o.r.data,
      "R.resp",    axi_resp_o.r.resp,
      "R.last",    axi_resp_o.r.last,
      "R.valid",   axi_resp_o.r_valid,
      "R.ready",   axi_req_i.r_ready
    )};
  
    return s;
  endfunction





endclass: axi_transaction

typedef uvm_sequencer #(axi_transaction) axi_sequencer;

class axi_write_sequence extends uvm_sequence #(axi_transaction);
  
  axi_transaction axi_write_trans;
 
 `uvm_object_utils(axi_write_sequence)

  function new (string name = "axi_write_sequence");
    super.new(name);
  endfunction: new

  virtual task body ();
    
	//repeat () begin
      axi_write_trans = axi_transaction::type_id::create("axi_write_trans");

      //drive payload
	  start_item(axi_write_trans);
	  //assert(axi_write_trans.axi_req_i.randomize());
     `uvm_info("WRITE_SEQ", "Generating Write sequence", UVM_LOW)
	  axi_write_trans.axi_req_i.aw.addr = 'h01;
	  axi_write_trans.axi_req_i.w.data = 'h101;
	  axi_write_trans.axi_req_i.w.strb = '1;
	  axi_write_trans.READ_WRITE = 'b1; 
	  finish_item(axi_write_trans);
	//end

  endtask

endclass: axi_write_sequence

class axi_read_sequence extends uvm_sequence #(axi_transaction);

  axi_transaction axi_read_trans;

 `uvm_object_utils(axi_read_sequence)

  function new (string name = "axi_read_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    
	axi_read_trans = axi_transaction::type_id::create("axi_read_trans");
	//assert(axi_read_trans.axi_req_i.randomize());
	
	start_item(axi_read_trans);	
   `uvm_info("READ_SEQ", "Generating Read sequence: ", UVM_LOW)	
	axi_read_trans.axi_req_i.ar.addr = 'h01;
    axi_read_trans.READ_WRITE = 'b0;
	finish_item(axi_read_trans);
  endtask

endclass: axi_read_sequence


class axi_write_read_sequence extends uvm_sequence #(axi_transaction);

  axi_transaction axi_write_read_trans;

 `uvm_object_utils(axi_write_read_sequence)

  function new (string name = "axi_write_read_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    
	axi_write_read_trans = axi_transaction::type_id::create("axi_write_read_trans");
	//assert(axi_read_trans.axi_req_i.randomize());
	
	start_item(axi_write_read_trans);	
   `uvm_info("WRITE_SEQ", "Generating Single Write sequence", UVM_LOW)
    axi_write_read_trans.axi_req_i.aw.len  = 'h0; 
    axi_write_read_trans.axi_req_i.aw.id   = 'h0;
    axi_write_read_trans.axi_req_i.aw.addr = 'h04; 
    axi_write_read_trans.axi_req_i.aw.size = 'h2;
    axi_write_read_trans.axi_req_i.aw.burst = 'b0;
	axi_write_read_trans.axi_req_i.w.data  = 32'h00000301;
	axi_write_read_trans.burst_data        = {32'h301, 32'hDA02, 32'hCE03, 32'h9B04, 0, 0, 0, 0, 0, 0};
    axi_write_read_trans.axi_req_i.w.strb  = 4'b1111;
    axi_write_read_trans.axi_req_i.w.last  = 1'b1;
    axi_write_read_trans.READ_WRITE        = 1'b1;
	axi_write_read_trans.addr_data = 'h0;
	finish_item(axi_write_read_trans);

	
	axi_write_read_trans = axi_transaction::type_id::create("axi_write_read_trans");

    start_item(axi_write_read_trans);
   `uvm_info("READ_SEQ", "Generating Single Read sequence: ", UVM_LOW)	
	axi_write_read_trans.axi_req_i.ar.addr = 'h04;
    axi_write_read_trans.axi_req_i.ar.len = 'h0;
	axi_write_read_trans.axi_req_i.ar.id = 'h0;
	axi_write_read_trans.axi_req_i.ar.size = 'h2;
	axi_write_read_trans.axi_req_i.ar.burst = 'h00;
    axi_write_read_trans.READ_WRITE = 'b0;
	axi_write_read_trans.addr_data = 'h0;
    finish_item(axi_write_read_trans);

  endtask

endclass: axi_write_read_sequence


class axi_incr_burst_write_read_sequence extends uvm_sequence #(axi_transaction);

  axi_transaction axi_write_read_trans;

 `uvm_object_utils(axi_incr_burst_write_read_sequence)

  function new (string name = "axi_write_read_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    
	axi_write_read_trans = axi_transaction::type_id::create("axi_write_read_trans");
	//assert(axi_read_trans.axi_req_i.randomize());
	
	start_item(axi_write_read_trans);	
   `uvm_info("WRITE_SEQ", "Generating Burst Incrementing Write sequence", UVM_LOW)
    axi_write_read_trans.axi_req_i.aw.len  = 'h3; 
    axi_write_read_trans.axi_req_i.aw.id   = 'h0;
    axi_write_read_trans.axi_req_i.aw.addr = 'h04; 
    axi_write_read_trans.axi_req_i.aw.size = 'h2;   
	axi_write_read_trans.axi_req_i.aw.burst = 'b01;
	axi_write_read_trans.axi_req_i.w.data  = 0;
    axi_write_read_trans.axi_req_i.w.strb  = 4'b1111;
    axi_write_read_trans.axi_req_i.w.last  = 1'b0;
    axi_write_read_trans.READ_WRITE        = 1'b1;
	axi_write_read_trans.addr_data = 'h0;
	axi_write_read_trans.burst_data        = {32'hFE1, 32'hDA02, 32'hCE03, 32'h9B04, 0, 0, 0, 0, 0, 0};
	finish_item(axi_write_read_trans);

    start_item(axi_write_read_trans);
   `uvm_info("READ_SEQ", "Generating Burst Incrementing Read sequence: ", UVM_LOW)	
	axi_write_read_trans.axi_req_i.ar.addr = 'h04;
    axi_write_read_trans.axi_req_i.ar.len = 'h3;
	axi_write_read_trans.axi_req_i.ar.id = 'h0;
	axi_write_read_trans.axi_req_i.ar.size = 'h2;
	axi_write_read_trans.axi_req_i.ar.burst = 'h01;
	axi_write_read_trans.addr_data = 'h0;
	axi_write_read_trans.addr_data = 'h0;
    axi_write_read_trans.READ_WRITE = 'b0;
    finish_item(axi_write_read_trans);


  endtask

endclass: axi_incr_burst_write_read_sequence


class axi_wrap_burst_write_read_sequence extends uvm_sequence #(axi_transaction);

  axi_transaction axi_write_read_trans;

 `uvm_object_utils(axi_wrap_burst_write_read_sequence)

  function new (string name = "axi_wrap_burst_write_read_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    
	axi_write_read_trans = axi_transaction::type_id::create("axi_write_read_trans");
	//assert(axi_read_trans.axi_req_i.randomize());
	
	start_item(axi_write_read_trans);	
   `uvm_info("WRITE_SEQ", "Generating Wrap Burst Write sequence", UVM_LOW)
    axi_write_read_trans.axi_req_i.aw.len  = 'h3; 
    axi_write_read_trans.axi_req_i.aw.id   = 'h0;
    axi_write_read_trans.axi_req_i.aw.addr = 'h04; 
    axi_write_read_trans.axi_req_i.aw.size = 'h2;   
	axi_write_read_trans.axi_req_i.aw.burst = 'b10;
	axi_write_read_trans.axi_req_i.w.data  = 0;
    axi_write_read_trans.axi_req_i.w.strb  = 4'b1111;
    axi_write_read_trans.axi_req_i.w.last  = 1'b0;
    axi_write_read_trans.READ_WRITE        = 1'b1;
	axi_write_read_trans.addr_data = 'h0;
	axi_write_read_trans.burst_data        = {32'hFE1, 32'hDA02, 32'hCE03, 32'h9B04, 0, 0, 0, 0, 0, 0};
	finish_item(axi_write_read_trans);

    start_item(axi_write_read_trans);
   `uvm_info("READ_SEQ", "Generating Wrap Burst Read sequence: ", UVM_LOW)	
	axi_write_read_trans.axi_req_i.ar.addr = 'h04;
    axi_write_read_trans.axi_req_i.ar.len = 'h3;
	axi_write_read_trans.axi_req_i.ar.id = 'h0;
	axi_write_read_trans.axi_req_i.ar.size = 'h2;
	axi_write_read_trans.axi_req_i.ar.burst = 'b10;
	axi_write_read_trans.addr_data = 'h0;
    axi_write_read_trans.READ_WRITE = 'b0;
    finish_item(axi_write_read_trans);

  endtask

endclass: axi_wrap_burst_write_read_sequence

class axi_full_multi_id_write_read_sequence extends uvm_sequence #(axi_transaction);

  axi_transaction axi_write_read_trans;

 `uvm_object_utils(axi_full_multi_id_write_read_sequence)

  function new (string name = "axi_full_multi_id_write_read_sequence");
    super.new(name);
  endfunction: new

  virtual task body();
    
	axi_write_read_trans = axi_transaction::type_id::create("axi_write_read_trans");
	//assert(axi_read_trans.axi_req_i.randomize());
	


	start_item(axi_write_read_trans);
   `uvm_info("WRITE_SEQ", "Generating Multi-ID Address Write sequence, 2", UVM_LOW)
    axi_write_read_trans.axi_req_i.aw.len  = 'h3;
    axi_write_read_trans.axi_req_i.aw.id   = 'h1;
	axi_write_read_trans.axi_req_i.aw.addr = 'h0; 
    axi_write_read_trans.axi_req_i.aw.size = 'h2;   
	axi_write_read_trans.axi_req_i.aw.burst = 'b10;
	axi_write_read_trans.READ_WRITE        = 1'b1;
	axi_write_read_trans.addr_data = 'h1;
	finish_item(axi_write_read_trans);

	start_item(axi_write_read_trans);	
   `uvm_info("WRITE_SEQ", "Generating Multi-ID Address Write sequence, 1", UVM_LOW)
    axi_write_read_trans.axi_req_i.aw.len  = 'h3;
    axi_write_read_trans.axi_req_i.aw.id   = 'h0;
    axi_write_read_trans.axi_req_i.aw.addr = 'h24; 
    axi_write_read_trans.axi_req_i.aw.size = 'h2;   
	axi_write_read_trans.axi_req_i.aw.burst = 'b10;
	axi_write_read_trans.addr_data = 'h1;
	axi_write_read_trans.READ_WRITE        = 1'b1;
	finish_item(axi_write_read_trans);

	start_item(axi_write_read_trans);	
   `uvm_info("WRITE_SEQ", "Generating Multi-ID Write sequence, 2", UVM_LOW)
	axi_write_read_trans.axi_req_i.w.data  = 0;
    axi_write_read_trans.axi_req_i.w.strb  = 4'b1111;
    axi_write_read_trans.axi_req_i.w.last  = 1'b0;
    axi_write_read_trans.READ_WRITE        = 1'b1;
	axi_write_read_trans.addr_data         = 'h2;
	axi_write_read_trans.burst_data        = {32'hCE2, 32'h8FC5, 32'hABCD, 32'h64A2, 0, 0, 0, 0, 0, 0};
	finish_item(axi_write_read_trans);

    start_item(axi_write_read_trans);
   `uvm_info("WRITE_SEQ", "Generating Multi-ID Write sequence, 1", UVM_LOW)
	axi_write_read_trans.axi_req_i.w.data  = 0;
    axi_write_read_trans.axi_req_i.w.strb  = 4'b1111;
    axi_write_read_trans.axi_req_i.w.last  = 1'b0;
    axi_write_read_trans.READ_WRITE        = 1'b1;
	axi_write_read_trans.addr_data         = 'h2;
	axi_write_read_trans.burst_data        = {32'hFE1, 32'hDA02, 32'hCE03, 32'h9B04, 0, 0, 0, 0, 0, 0};
	finish_item(axi_write_read_trans);

    start_item(axi_write_read_trans);
   `uvm_info("READ_SEQ", "Generating Multi-ID Read sequence 1: ", UVM_LOW)	
    axi_write_read_trans.axi_req_i.ar.addr = 'h24;
    axi_write_read_trans.axi_req_i.ar.len = 'h3;
    axi_write_read_trans.axi_req_i.ar.id = 'h0;
    axi_write_read_trans.axi_req_i.ar.size = 'h2;
    axi_write_read_trans.axi_req_i.ar.burst = 'b10;
    //axi_write_read_trans.first_read = 'h1;
    axi_write_read_trans.READ_WRITE = 'b0;
    finish_item(axi_write_read_trans);

    start_item(axi_write_read_trans);
   `uvm_info("READ_SEQ", "Generating Multi-ID Read sequence 2: ", UVM_LOW)	
    axi_write_read_trans.axi_req_i.ar.addr = 'h0;
    axi_write_read_trans.axi_req_i.ar.len = 'h3;
    axi_write_read_trans.axi_req_i.ar.id = 'h1;
    axi_write_read_trans.axi_req_i.ar.size = 'h2;
    axi_write_read_trans.axi_req_i.ar.burst = 'b10;
    //axi_write_read_trans.first_read = 'h1;
    axi_write_read_trans.READ_WRITE = 'b0;
    finish_item(axi_write_read_trans);





  endtask


endclass
