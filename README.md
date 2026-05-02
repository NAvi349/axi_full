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
  
Testbench info

Wrapping burst 'b10:

First part: ((addr / wrap_boundary) * wrap_boundary) → aligns the base address to the nearest boundary.

Second part: (addr + offset) % wrap_boundary → calculates the wrapped offset inside that boundary.

Together: They give the correct wrapped address for each beat.

Example:
   
        wrap_boundary = 16

        addr = 20

        burst_addr = 4

    For i = 0:

        Offset = (4 * 0) % 16 = 0

        Wrapped = (20 + 0) % 16 = 4

        Final = (20/16)*16 + 4 = 16 + 4 = 20

    For i = 1:

        Offset = (4 * 1) % 16 = 4

        Wrapped = (20 + 4) % 16 = 8

        Final = 16 + 8 = 24

    For i = 2:

        Offset = (4 * 2) % 16 = 8

        Wrapped = (20 + 8) % 16 = 12

        Final = 16 + 12 = 28

    For i = 3:

        Offset = (4 * 3) % 16 = 12

        Wrapped = (20 + 12) % 16 = 0 (wrapped back!)

        Final = 16 + 0 = 16

So the burst addresses go: 20, 24, 28, 16… and keep wrapping around.

