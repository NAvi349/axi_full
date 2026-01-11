//Contains agents and scoreboard
//This ENV for AXI4 mem slave this is single agent environment

class axi_env extends uvm_env;
 `uvm_component_utils(axi_env)

  axi_agent axi_agent_0;
  axi_scoreboard axi_scoreboard_0;

  function new(string name="axi_env", uvm_component parent);
    super.new(name, parent);
  endfunction: new
  
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
	axi_agent_0 = axi_agent::type_id::create("axi_agent_0", this);
	axi_scoreboard_0 = axi_scoreboard::type_id::create("axi_scoreboard_0", this);
  endfunction: build_phase

  function void connect_phase(uvm_phase phase);

    // Connect AXI monitor to AXI scoreboard
    if (axi_agent_0.axi_monitor_0.dut_in_tx_port == null) `uvm_fatal("NULL", "dut_in_tx_port is null");
    if (axi_scoreboard_0.in_imp == null) `uvm_fatal("NULL", "in_imp is null");
    if (axi_agent_0.axi_monitor_0.dut_out_tx_port == null) `uvm_fatal("NULL", "dut_out_tx_port is null");
    if (axi_scoreboard_0.out_imp == null) `uvm_fatal("NULL", "out_imp is null");



	super.connect_phase(phase);
    axi_agent_0.axi_monitor_0.dut_in_tx_port.connect(axi_scoreboard_0.in_imp);
	axi_agent_0.axi_monitor_0.dut_out_tx_port.connect(axi_scoreboard_0.out_imp); 
  endfunction: connect_phase

  
endclass: axi_env
