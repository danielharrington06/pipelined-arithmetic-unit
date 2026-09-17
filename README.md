# Pipelined Arithmetic Unit

Aim: A 4-wide pipelined arithmetic unit that computes y = (a + b) × c, with a SystemVerilog testbench and automated verification.

## Run and Compile
```bash
verilator --binary --timing --top-module arithmetic_unit_tb src/arithmetic_unit.sv tb/arithmetic_unit_tb.sv

./obj_dir/Varithmetic_unit_tb
```