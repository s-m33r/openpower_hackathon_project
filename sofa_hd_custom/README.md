# OpenFPGA Setup and Verilog Netlist Generation

This document explains, step by step, how we generate the FPGA fabric Verilog netlist using OpenFPGA, and where to find the outputs that are then used by OpenLane to produce the FPGA GDS.

At a high level:
- We use OpenFPGA to generate a synthesizable Verilog netlist for the custom FPGA fabric (task: `sofa_hd_custom`).
- The generated Verilog files are copied into this repository under `fpga/verilog/`.
- OpenLane consumes those Verilog sources (see `fpga/config.json`) to produce `gds/fpga_top.gds`.

---

## 1) Prerequisites

- OS: Linux (recommended) or macOS
- Tools:
  - Python 3.8+ and pip
  - Git
  - Build essentials (for OpenFPGA/VTR toolchain build on first run):
    - gcc/g++, make, cmake
    - flex, bison
    - libreadline-dev, libffi-dev, libboost-all-dev (names may vary by distro)
- Disk space: several GB (to build VTR and cache artifacts on first run)

Example (Ubuntu/Debian) to install common dependencies:
```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake gcc g++ make \
  flex bison \
  libreadline-dev libffi-dev \
  libboost-all-dev \
  python3 python3-pip git
```

Tip: OpenFPGA will compile/build parts of its flow (e.g., VTR) on first use. This can take time; subsequent runs are much faster.

---

## 2) Get OpenFPGA

Clone OpenFPGA (use a tag or commit that matches your environment; `master` shown as example):

```bash
git clone https://github.com/lnis-uofu/OpenFPGA.git
cd OpenFPGA
git submodule update --init --recursive
```

Optional: create and activate a Python virtual environment (recommended):

```bash
python3 -m venv .venv
source .venv/bin/activate
# If your OpenFPGA checkout provides requirements:
# pip install -r openfpga_flow/requirements.txt
```

---

## 3) Place the Custom Task (sofa_hd_custom)

If you have a custom task directory for your architecture (e.g., `sofa_hd_custom`), ensure it exists under OpenFPGA’s tasks:

```
OpenFPGA/
└── openfpga_flow/
    └── tasks/
        └── sofa_hd_custom/
            ├── <architecture XML(s)>
            ├── <fabric key(s) >
            ├── <yosys/vpr configs>
            └── <task config files>
```

Notes:
- The task folder contains the architecture XML and all files OpenFPGA needs to build the fabric.
- If your task is maintained outside OpenFPGA (e.g., in this repo), copy/sync it into `openfpga_flow/tasks/`.

---

## 4) Run the OpenFPGA Task

From the root of the OpenFPGA repository:

```bash
python3 openfpga_flow/scripts/run_fpga_task.py sofa_hd_custom --maxthreads 1
```

- `sofa_hd_custom` is the task name (use your task name if different).
- `--maxthreads 1` enforces a single-threaded run for reproducibility. You can increase threads for speed when you no longer need strict determinism.

Useful flags:
- `--clean_run` — start a fresh run (ignores previous artifacts).
- `--show_thread_logs` — print per-thread logs for debugging.
- `--timeout <minutes>` — set a max duration for the task.
- `--run_dir <name>` — name the run directory explicitly.

Example with more options:
```bash
python3 openfpga_flow/scripts/run_fpga_task.py sofa_hd_custom \
  --maxthreads 1 \
  --clean_run \
  --run_dir run_sofa_hd_custom_001 \
  --show_thread_logs
```

---

## 5) Locate the Generated Verilog Netlist

After the task completes, OpenFPGA prints the run directory path. Typical locations (examples; exact paths depend on your OpenFPGA version):

- `openfpga_flow/tasks/sofa_hd_custom/<run_dir>/`
- Inside that run directory, look for a fabric/fabrication result directory containing:
  - `fpga_top.v` (top-level)
  - Supporting leaf modules (CLB/IO tiles, switch/connection blocks, muxes, LUTs, FFs, memories, encoders, etc.)

Copy or sync the generated Verilog files into this repository:
```bash
# From the OpenFPGA run directory where netlists were generated:
# Replace <RUN_DIR> with the actual run folder name OpenFPGA created
rsync -av \
  openfpga_flow/tasks/sofa_hd_custom/<RUN_DIR>/fabric_netlist_verilog/ \
  /path/to/your/clone/openpower_hackathon_project/fpga/verilog/
```

Notes:
- In some OpenFPGA versions, the final Verilog folder may be named differently (e.g., `fabric_netlist/` or similar). Use the directory printed by the flow and look for the modules referenced in this repo’s `fpga/config.json` under `VERILOG_FILES`.
- Ensure that `fpga/verilog/fpga_top.v` exists after copying.

---

## 6) Next Step: Generate GDS with OpenLane

Once the Verilog netlist is in `fpga/verilog/`, run OpenLane using this repo’s configuration:
- Top: `fpga_top`
- Config: [`fpga/config.json`](../fpga/config.json)
- Pins: [`fpga/pin_order.cfg`](../fpga/pin_order.cfg)

OpenLane will produce the final GDS here:
- [`gds/fpga_top.gds`](../gds/fpga_top.gds)

See `fpga/README.md` for more details about OpenLane settings and how we generated the FPGA GDS.

---
