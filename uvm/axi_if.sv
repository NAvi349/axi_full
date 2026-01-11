interface axi_if (input logic clock);
  import axi_full_pkg::*; 
  // DUT inputs
 `include "axi/typedef.svh"
 `include "axi/assign.svh"

  // DUT inputs
  logic rst_ni;
  req_t axi_req_i;
 
  // DUT outputs
  resp_t axi_resp_o;
  

  // DUT monitor outputs
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
  
endinterface : axi_if
