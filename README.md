# Microwatt + FPGA SoC

This project proposal, submitted for the the 2025 [Microwatt Momentum OpenPOWER HW Design Hackathon](https://chipfoundry.io/challenges/microwatt) aims to design an embedded class SoC using the open source [Microwatt](https://github.com/antonblanchard/microwatt) core and a FPGA fabric generator like [OpenFPGA](https://github.com/lnis-uofu/OpenFPGA) or [FABulous](https://fabulous.readthedocs.io/en/latest/).  

The goal of this project is to integrate the open-source OpenPOWER Microwatt core with a customizable FPGA fabric on the same die, creating a heterogeneous SoC platform. By pairing the flexibility of an FPGA fabric with the efficiency of a general-purpose OpenPOWER CPU, the system allows developers to prototype accelerators, custom peripherals, and reconfigurable logic that are tightly coupled with the processor.

## Approach
- Creation of a minimal Microwatt SoC, disabling features like the DRAM controller  
- Conversion of the Microwatt SoC VHDL code to Verilog using GHDL  
- Using OpenFPGA or FABulous to generate the FPGA fabric netlist  
- Integration of FPGA fabric with the SoC (access to bitstream configuration memory and some IOs)  
- GDS generation for the full SoC  
