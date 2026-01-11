package axi_full_pkg;
  
  import axi_pkg::*;
  import uvm_pkg::*;
 `include "uvm_macros.svh"
 `include "axi/typedef.svh"
 `include "axi/assign.svh"  
  // Parameters
  localparam int unsigned ADDR_WIDTH = 32;

  localparam int unsigned DATA_WIDTH = 32;

  localparam int unsigned STRB_WIDTH     = DATA_WIDTH/8;
  
  localparam int unsigned NUM_PORTS      = 1;
  localparam int unsigned ID_WIDTH       = 'd4;
  localparam int unsigned USER_WIDTH     = 1;
  
  //AXI
  localparam int unsigned AXI_ADDR_WIDTH = 32;
  localparam int unsigned AXI_DATA_WIDTH = 32;
  

  // typedefs as given in the git repo page for AXI design
  //typedef logic [ADDR_WIDTH-1:0] mem_addr_t;
  //typedef logic [MEM_STRB_WIDTH-1:0] mem_strb_t;
  //typedef logic [DATA_WIDTH-1:0]     mem_data_t;
  typedef logic [STRB_WIDTH-1:0]     strb_t;
  typedef logic [7:0]                byte_t;
  typedef logic [ID_WIDTH-1:0]       id_t;
  typedef logic [USER_WIDTH-1:0]     user_t;
  typedef logic [AXI_ADDR_WIDTH-1:0] axi_addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0] axi_data_t;
  

 `AXI_TYPEDEF_AW_CHAN_T (aw_chan_t, axi_addr_t, id_t, user_t)
 `AXI_TYPEDEF_W_CHAN_T  ( w_chan_t, axi_data_t, strb_t, user_t)
 `AXI_TYPEDEF_B_CHAN_T  ( b_chan_t, id_t, user_t)
 `AXI_TYPEDEF_AR_CHAN_T (ar_chan_t, axi_addr_t, id_t, user_t)
 `AXI_TYPEDEF_R_CHAN_T  ( r_chan_t, axi_data_t, id_t, user_t)
 `AXI_TYPEDEF_REQ_T     (req_t,  aw_chan_t, w_chan_t, ar_chan_t)
 `AXI_TYPEDEF_RESP_T    (resp_t, b_chan_t,  r_chan_t) 

 
 endpackage: axi_full_pkg

