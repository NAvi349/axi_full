// driver, monitor, sequencer are created here.
// Driver and sequencer are connected together

class axi_agent extends uvm_agent;
 `uvm_component_utils(axi_agent)
  
  axi_sequencer axi_sequencer_0;
  axi_driver axi_driver_0;
  axi_monitor axi_monitor_0;  

  
  function new(string name = "axi_agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);


    axi_monitor_0 = axi_monitor::type_id::create("axi_monitor_0", this);
	axi_driver_0 = axi_driver::type_id::create("axi_driver_0", this);
	axi_sequencer_0 = axi_sequencer::type_id::create("axi_sequencer_0", this);


  endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase); 
    if (axi_driver_0 == null) `uvm_fatal("NULL","driver is null");
    if (axi_sequencer_0 == null) `uvm_fatal("NULL","sequencer is null")
    
	axi_driver_0.seq_item_port.connect(axi_sequencer_0.seq_item_export);	
  endfunction: connect_phase

endclass: axi_agent
