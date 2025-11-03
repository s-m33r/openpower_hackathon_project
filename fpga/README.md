## How we generated the FPGA GDS (Nix + OpenLane)

We used the Verilog netlists produced by OpenFPGA (architecture XML → fabric generation) and then ran OpenLane in a Nix environment to produce the FPGA GDS.

Preconditions
- SkyWater PDK (sky130A) available inside the environment.
- `fpga/verilog/` contains the OpenFPGA-generated netlists (including `fpga_top.v` and all leaf modules referenced in `config.json`).
- `config.json` points to the netlists under `VERILOG_FILES` and defines:
  - Top module: `fpga_top`
  - Clock: `clk` (12.0 ns period)
  - Power pins via `USE_POWER_PINS` with `vccd1`/`vssd1`
- `pin_order.cfg` defines IO placement.

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

Enter the Nix environment
If your repository provides a flake or pinned shell, use it. For example:
```bash
sudo nix-shell --pure ~/openlane2/shell.nix
```
This brings in OpenLane (and its dependencies) and sets/exports the required environment variables (e.g., PDK_ROOT) as defined by your Nix setup.

Run the OpenLane flow from the fpga directory
```bash
cd fpga
openlane config.json
```

Collect results
- OpenLane writes artifacts under `runs/<tag>/results/...`.
- Copy the final GDS to the repo’s GDS folder.
