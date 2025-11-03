# MicroWatt CPU — GDS Generation (OpenLane)

This document explains exactly how we generated the MicroWatt CPU GDS from the repository, including which HDL modules were kept/removed and the OpenLane steps used to produce the final layout.

Key repo files used:
- OpenLane config: [microwatt/config.json](https://github.com/s-m33r/openpower_hackathon_project/blob/fea8b885766f492d3eebc304ff375a8f829d2531/microwatt/config.json)
- Pin constraints: [microwatt/pin_order.cfg](https://github.com/s-m33r/openpower_hackathon_project/blob/fea8b885766f492d3eebc304ff375a8f829d2531/microwatt/pin_order.cfg)
- Final GDS artifact: [gds/microwatt_wrapper.gds](https://github.com/s-m33r/openpower_hackathon_project/blob/main/gds/microwatt_wrapper.gds)

OpenLane config highlights (from `microwatt/config.json`):
- DESIGN_NAME: `microwatt_wrapper`
- PDK: `sky130A`
- STD_CELL_LIBRARY: `sky130_fd_sc_hd`
- VERILOG_FILES:
  - `dir::../../verilog/rtl/microwatt_wrapper.v`
  - `dir::../../verilog/rtl/microwatt.v`
- CLOCK_PORT: `clk`, CLOCK_PERIOD: `12.0` ns
- Power: `VDD_NETS=["vccd1"]`, `GND_NETS=["vssd1"]`, `VERILOG_POWER_DEFINE=USE_POWER_PINS`
- Routing: `RT_MAX_LAYER=met5`
- Placement density/utilization tuned for this core

Note: The config expects the CPU wrapper and core sources to be under `verilog/rtl/` at the repository root, referenced via `dir::../../...` paths when running OpenLane from the `microwatt/` directory.

---

## What we kept vs removed

To generate a standalone CPU GDS, we pruned the SoC to the compute core only. The following lists reflect the HDL that remained and what was explicitly removed.

Kept (CPU pipeline and core)
- bit_counter — Population count helper
- cache_ram_5_64_* — Instruction/Data cache RAM
- control_0 — Control signals decode
- core_debug_0 — Debug module
- cr_file_0 — Condition register file
- decode1_0, decode2_0 — Decode stages
- dcache_64_4_... — Data cache
- execute1_0 — Execute stage
- fetch1_... — Fetch stage
- fpu — Floating-point unit
- icache_64_8_... — Instruction cache
- loadstore1_0 — Load/store unit
- logical, rotator — ALU operations
- main_bram_64_9_4096_* — Main memory (BRAM)
- mmu — MMU/TLB
- multiply_4 — 4-cycle multiplier
- plru_1 — LRU replacement policy
- pmu — Performance monitoring
- random — Random number for TLB
- register_file_0 — Register file

Removed (SoC peripherals)
- gpio_32 — GPIO controller
- spi_flash_ctrl_4_4 — SPI Flash controller
- spi_rxtx_4_1 — SPI transceiver
- syscon_* — System control
- xics_icp, xics_ics_* — Interrupt controllers
- wishbone_arbiter_4 — Bus arbiter (critical to remove)
- wishbone_bram_wrapper_4096 — BRAM wrapper
- wishbone_debug_master — Debug bus master

Removed (top-level wrappers)
- microwatt — SoC wrapper (routes to core + peripherals)
- user_project_wrapper — Caravel harness integration
- simplebus_host — SimpleAPI wrapper

Result: A minimal “CPU-only” netlist, wrapped by `microwatt_wrapper.v` to expose the core’s IO pins and power pins in a PDK-friendly way for OpenLane.

---

## Directory expectations

When running OpenLane from `microwatt/`, the config expects:
```
.
├── microwatt/
│   ├── config.json         # OpenLane config for CPU core
│   └── pin_order.cfg       # IO pin ordering / sides
└── verilog/
    └── rtl/
        ├── microwatt.v         # CPU core-only netlist (no SoC peripherals)
        └── microwatt_wrapper.v # Simple top wrapper exposing clk, reset, IO, power pins
```

Ensure:
- `microwatt.v` contains only the CPU pipeline/core modules listed above.
- All SoC-level peripherals and top wrappers are removed as described.
- The wrapper provides consistent top-level ports (`clk`, resets/IO as needed) and `USE_POWER_PINS` for `vccd1`/`vssd1`.

---

## How we generated the CPU GDS (Nix + OpenLane)

We used a Nix-based environment (“Nix shell/develop”) to get a pinned, reproducible toolchain, then ran the standard OpenLane flow using `microwatt/config.json`.

Preconditions
- SkyWater PDK (sky130A) available inside the environment.
- `microwatt.v` contains only the CPU pipeline/core modules listed above (all SoC peripherals/wrappers removed).
- `microwatt_wrapper.v` provides clean top-level ports (clk, reset/IO as needed) and `USE_POWER_PINS` for `vccd1`/`vssd1`.

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
- If your repository provides a flake:
```bash
sudo nix-shell --pure ~/openlane2/shell.nix
```
This brings in OpenLane (and its dependencies) and sets/exports the required environment variables (e.g., PDK_ROOT) as defined by your Nix setup.

2) Run the OpenLane flow from the microwatt directory
```bash
cd microwatt

openlane config.json
```

3) Collect results
- OpenLane writes artifacts under `runs/<tag>/results/...`.
- Copy the final GDS to the repo’s GDS folder.

## Notes

- Pin placement: governed by `pin_order.cfg` to keep core IO stable and routable.
- Power intent: `USE_POWER_PINS` exposes `vccd1` / `vssd1` at the top; these are bound via OpenLane PDN.
- Timing: the clock is defined on `clk` with a 12.0 ns target period in `config.json`.
- Routing: top metal capped at `met5` per config.

This is the exact process we used to obtain the MicroWatt CPU GDS from the core-only netlist.
