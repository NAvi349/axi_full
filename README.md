# axi_full

This repo contains a fully fledged **UVM testbench** for the verification of the **AXI4 protocol standard** with support for **burst verification**.

- **Design:** AXI4 slave memory
- **Testbench:** AXI4 master generates and drives AXI4 transactions

---

## Design

The design under test (DUT) is [`axi_sim_mem`](https://github.com/pulp-platform/axi) from the **PULP AXI platform**. It is a behavioral memory array model acting as an **AXI slave** that responds to AXI transactions issued by the testbench.

### Ports / Signals

| Signal | Direction | Description |
|--------|-----------|-------------|
| `clk` | Input | Clock input |
| `rst_n` | Input | Active-low reset |
| `axi_req` | Input | AXI Request Channel (`AW`, `W`, `AR`) |
| `axi_resp` | Output | AXI Response Channel (`B`, `R`) |
| *Misc* | — | Other internal debug signals |

---

## Testbench Info

### Wrapping Burst (`BURST = 2'b10`)

For wrapping bursts, the address calculation per beat consists of two parts:

1. **Base alignment:**
   ```
   (addr / wrap_boundary) * wrap_boundary
   ```
   → Aligns the base address to the nearest wrap boundary.

2. **Wrapped offset:**
   ```
   (addr + offset) % wrap_boundary
   ```
   → Calculates the wrapped offset inside that boundary.

Together, they produce the **correct wrapped address** for each beat in the burst.

---

### Example

Given:

```text
wrap_boundary = 16
addr          = 20
burst_addr    = 4
```

| Beat `i` | Offset = `(4*i) % 16` | Wrapped = `(20 + offset) % 16` | Final Address |
|:--------:|:---------------------:|:------------------------------:|:-------------:|
| 0        | 0                     | 4                              | `(20/16)*16 + 4 = 20` |
| 1        | 4                     | 8                              | `16 + 8 = 24` |
| 2        | 8                     | 12                             | `16 + 12 = 28` |
| 3        | 12                    | 0  *(wrapped!)*                | `16 + 0 = 16` |

So the burst addresses progress as:

```
20 → 24 → 28 → 16 → …
```

…and continue **wrapping around** the boundary.

---

## Features

- Full UVM-compliant testbench architecture
- Support for **FIXED**, **INCR**, and **WRAP** burst types
- Configurable address/data width.
- Burst-level transaction verification.
- Out of order support for transactions with different ID.
