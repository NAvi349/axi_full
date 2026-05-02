# axi_full
This repo contains a fully fledged UVM testbench for the verification of AXI4 protocol standard with support for burst verification.

**Design:** AXI4 slave memory
**Testbench:** AXI4 master generates and drives AXI4 transactions 

Design

Design is axi_sim_mem from pulp axi platform. It is a behavioural mem array model acting as AXI slave.
It responds to AXI transactions from testbench
Some inouts:
- Clock input
- RST_N input
- Input axi_req - AXI Request Channel (AW, W, AR)
- Output axi_resp - AXI Response Channel (B, R)
- Other Internal debug signals
  

