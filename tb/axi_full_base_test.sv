`include "uvm_macros.svh"

import uvm_pkg::*;
import axi_full_uvm_pkg::*;
/**********************************************/
/* Testname: axi_full_base_test
/* Description: This is a base testcase for AXI-Lite enviroment.
/**********************************************/


class axi_full_base_test extends uvm_test;
 `uvm_component_utils(axi_full_base_test)
  
  axi_env axi_env_0;

  function new(string name = "axi_full_base_test", uvm_component parent);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
	axi_env_0 = axi_env::type_id::create("axi_env_0", this);
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);


	phase.drop_objection(this);

  endtask: run_phase

  function void end_of_elaboration_phase (uvm_phase phase);
    uvm_top.print_topology();
  endfunction: end_of_elaboration_phase
  
endclass: axi_full_base_test
