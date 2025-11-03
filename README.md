# Microwatt + FPGA SoC (OpenPOWER + OpenFPGA on SKY130A)

This repository documents our entry for the 2025 [Microwatt Momentum OpenPOWER HW Design Hackathon](https://chipfoundry.io/challenges/microwatt).  
We designed an embedded-class heterogeneous SoC by integrating the open-source [Microwatt](https://github.com/antonblanchard/microwatt) OpenPOWER CPU core with a custom FPGA fabric generated via [OpenFPGA](https://github.com/lnis-uofu/OpenFPGA). We produced standalone GDSII for both blocks using the open-source [OpenLane](https://github.com/The-OpenROAD-Project/OpenLane) flow on the SkyWater SKY130A PDK.

Why this approach?
- Microwatt gives a general-purpose OpenPOWER CPU.
- The FPGA fabric provides reconfigurability for accelerators and custom peripherals.
- Together, they enable fast prototyping of hardware/software co-designs on one chip.


## Repository structure

```
.
├── fpga/                  # OpenFPGA → OpenLane flow for the FPGA fabric (fpga_top)
│   ├── config.json
│   ├── pin_order.cfg
│   └── verilog/           # OpenFPGA-generated netlists (incl. fpga_top.v)
├── gds/                   # Final GDS artifacts (CPU + FPGA)
│   ├── fpga_top.gds
│   └── microwatt_wrapper.gds
├── microwatt/             # OpenLane flow for Microwatt CPU core (microwatt_wrapper)
│   ├── config.json
│   ├── pin_order.cfg
│   └── lib/               # (reserved for libs/scripts if needed)
├── verilog/
│   └── rtl/
│       ├── microwatt.v         # CPU core-only netlist (no SoC peripherals)
│       └── microwatt_wrapper.v # Simple top exposing IO + power pins
├── Makefile
├── demo.c                 # Example C (for bring-up/sim)
└── .gitignore
```

Quick links:
- FPGA config: [fpga/config.json](fpga/config.json), pins: [fpga/pin_order.cfg](fpga/pin_order.cfg)
- CPU config: [microwatt/config.json](microwatt/config.json), pins: [microwatt/pin_order.cfg](microwatt/pin_order.cfg)
- GDS artifacts: [gds/microwatt_wrapper.gds](gds/microwatt_wrapper.gds), [gds/fpga_top.gds](gds/fpga_top.gds)


## What we built

- Microwatt CPU GDS:
  - We pruned the original SoC: removed all SoC peripherals and top-level wrappers.
  - Kept only the CPU pipeline and core modules (decode, execute, caches, MMU/TLB, FPU, register files, etc.).
  - Wrapped the core with a thin `microwatt_wrapper.v` that cleanly exposes clock/reset/IO and `USE_POWER_PINS`.
  - Ran OpenLane to generate [microwatt_wrapper.gds](gds/microwatt_wrapper.gds).

- FPGA fabric GDS:
  - Generated the FPGA fabric Verilog netlist with OpenFPGA (from its architecture XML and required task files).
  - Fed the generated netlists to OpenLane using [fpga/config.json](fpga/config.json).
  - Produced [fpga_top.gds](gds/fpga_top.gds).


## How we generated the CPU GDS (Nix + OpenLane)

We used a Nix-based environment to get a pinned, reproducible OpenLane toolchain, then ran the flow with `microwatt/config.json`.

Preconditions
- SkyWater PDK (sky130A) available inside the environment.
- `verilog/rtl/microwatt.v` contains only the CPU pipeline/core modules (all SoC peripherals/wrappers removed).
- `verilog/rtl/microwatt_wrapper.v` exposes clean top-level ports (clk, reset/IO as needed) and `USE_POWER_PINS` for `vccd1`/`vssd1`.

Directory layout expected by the config:
```
.
├── microwatt/
│   ├── config.json         # OpenLane config for CPU core
│   └── pin_order.cfg       # IO pin ordering / sides
└── verilog/
    └── rtl/
        ├── microwatt.v         # CPU core-only netlist
        └── microwatt_wrapper.v # Simple top wrapper
```

1) Enter the Nix environment
```bash
# Example pinned shell (replace path with yours)
sudo nix-shell --pure ~/openlane2/shell.nix
```
This brings in OpenLane (and dependencies) and sets environment variables like `PDK_ROOT` as defined by your Nix setup.

2) Run the OpenLane flow from the microwatt directory
```bash
cd microwatt
openlane config.json
```

3) Collect results
- OpenLane writes artifacts under `runs/<tag>/results/...`.
- Copy the final GDS to the repo’s GDS folder:
  - `gds/microwatt_wrapper.gds`


## How we generated the FPGA GDS (Nix + OpenLane)

We used the Verilog netlists produced by OpenFPGA and then ran OpenLane in the same Nix environment.

Preconditions
- SkyWater PDK (sky130A) available inside the environment.
- `fpga/verilog/` contains the OpenFPGA-generated netlists (including `fpga_top.v` and all leaf modules referenced in `config.json`).
- `fpga/config.json` sets:
  - Top module: `fpga_top`
  - Clock port: `clk` (12.0 ns period ≈ 83.3 MHz)
  - Power pins via `USE_POWER_PINS` with `vccd1`/`vssd1`
- `fpga/pin_order.cfg` defines IO placement.

Directory layout expected by the config:
```
.
└── fpga/
    ├── config.json        # OpenLane config for FPGA fabric (fpga_top)
    ├── pin_order.cfg      # IO pin ordering / sides
    └── verilog/           # OpenFPGA-generated netlists
        ├── fpga_top.v
        └── ...            # tiles, muxes, LUT/FFs, memories, encoders, IOs, etc.
```

1) Enter the Nix environment
```bash
# Example pinned shell (replace path with yours)
sudo nix-shell --pure ~/openlane2/shell.nix
```

2) Run the OpenLane flow from the fpga directory
```bash
cd fpga
openlane config.json
```

3) Collect results
- OpenLane writes artifacts under `runs/<tag>/results/...`.
- Copy the final GDS to the repo’s GDS folder:
  - `gds/fpga_top.gds`

For full OpenFPGA netlist-generation steps, see [fpga/OPENFPGA_NETLIST.md](fpga/OPENFPGA_NETLIST.md) (architecture task, command-line, and where to find the generated Verilog).


## Simulation and verification

- CPU functional check:
  - We modified the classic `hello_world.c` to print the “Chip Foundry” logo text.
  - Simulated on the Microwatt CPU using a standard Verilog simulator (e.g., Verilator/Icarus).
  - Verified correct instruction execution and UART-like output behavior.
- You can use [demo.c](demo.c) as a starting point for integration tests or bring-up examples.

## Chip Foundry Logo

<img width="714" height="832" alt="image" src="https://github.com/user-attachments/assets/c9bae075-b4d9-4780-a35a-2210466e0bcf" />

## Configuration highlights

Microwatt CPU ([microwatt/config.json](microwatt/config.json))
- DESIGN_NAME: `microwatt_wrapper`
- PDK: `sky130A`
- STD_CELL_LIBRARY: `sky130_fd_sc_hd`
- VERILOG_FILES: `dir::../../verilog/rtl/microwatt_wrapper.v`, `dir::../../verilog/rtl/microwatt.v`
- CLOCK_PORT: `clk`, CLOCK_PERIOD: `12.0` ns
- Power: `VDD_NETS=["vccd1"]`, `GND_NETS=["vssd1"]`, `VERILOG_POWER_DEFINE=USE_POWER_PINS`
- Routing max layer: `met5`

FPGA fabric ([fpga/config.json](fpga/config.json))
- DESIGN_NAME: `fpga_top`
- PDK: `sky130A`
- STD_CELL_LIBRARY: `sky130_fd_sc_hd`
- VERILOG_FILES: declared under `dir::verilog/...` (generated by OpenFPGA)
- CLOCK_PORT: `clk`, CLOCK_PERIOD: `12.0` ns
- Floorplan: absolute DIE_AREA and moderate utilization/density
- Routing max layer: `met5`
- Power: `vccd1`/`vssd1` with `USE_POWER_PINS`


## Outcomes

- ✅ CPU core-only GDS generated: [microwatt_wrapper.gds](gds/microwatt_wrapper.gds)
- ✅ FPGA fabric GDS generated: [fpga_top.gds](gds/fpga_top.gds)
- ✅ CPU simulation verified with modified “hello_world.c” logo print
- ⏭️ Next: integrate CPU + FPGA fabric into a unified top and run full-chip P&R


## Tools

- HDL/Netlist: GHDL (VHDL→Verilog for Microwatt), OpenFPGA (fabric generation)
- PnR/Signoff: OpenLane + OpenROAD, Magic, KLayout
- Simulation: Verilator / Icarus Verilog
- PDK: SkyWater SKY130A (`sky130_fd_sc_hd`)
