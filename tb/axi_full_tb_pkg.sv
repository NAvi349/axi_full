package axi_full_tb_pkg;


  `include "axi_full_base_test.sv"
  `include "axi_full_read_test.sv"
  `include "axi_full_write_test.sv"
  `include "axi_full_write_read_test.sv"
  //`include "axi_full_fixed_burst_write_read_test.sv"
  `include "axi_full_incr_burst_write_read_test.sv"
  `include "axi_full_wrap_burst_write_read_test.sv"
  `include "axi_full_multi_id_write_read_test.sv"
endpackage
