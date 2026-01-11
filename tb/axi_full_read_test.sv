/**********************************************/
/* Testname: axi_lite_read_test
/* Description: This is a read operation testcase for AXI-Lite enviroment.
/**********************************************/

`include "uvm_macros.svh"

import uvm_pkg::*;
import axi_full_pkg::*;
import axi_full_uvm_pkg::*;  
import axi_full_tb_pkg::*;
class axi_full_read_test extends axi_full_base_test;
 `uvm_component_utils(axi_full_read_test)
  
  axi_read_sequence axi_rd_seq;
  
  function new(string name = "axi_full_read_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
	axi_rd_seq = axi_read_sequence::type_id::create("axi_rd_seq", this);
  endfunction: build_phase
 
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
      axi_rd_seq.start(axi_env_0.axi_agent_0.axi_sequencer_0);
	phase.drop_objection(this);
  endtask: run_phase

endclass: axi_full_read_test
