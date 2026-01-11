package axi_full_uvm_pkg;
  import uvm_pkg::*;
 `include "uvm_macros.svh" 
  import axi_full_pkg::*;
 `include "axi/typedef.svh"
 `include "axi/assign.svh"


 `include "axi_transaction.sv"

 `include "axi_driver.sv"
 `include "axi_monitor.sv"
 `include "axi_agent.sv"
 `include "axi_scoreboard.sv"
 `include "axi_env.sv"


endpackage;
