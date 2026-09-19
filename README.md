# Pipelined Arithmetic Unit

Aim: A 4-wide pipelined arithmetic unit that computes y = (a + b) × c, with a SystemVerilog testbench and automated verification.

## Run and Compile
```bash
verilator --binary --timing --top-module arithmetic_unit_tb src/arithmetic_unit.sv tb/arithmetic_unit_tb.sv

./obj_dir/Varithmetic_unit_tb
```

## yosys comparison

4-lane Pipelined:
```bash
=== arithmetic_unit ===

        +----------Local Count, excluding submodules.
        | 
    14521 wires
    38329 wire bits
       27 public wires
      771 public wire bits
       19 ports
      515 port bits
    12879 cells
     6209   $_AND_
      385   $_DFF_P_
        4   $_MUX_
       29   $_NOT_
     1907   $_OR_
     4345   $_XOR_
```

4-lane Unpipelined:
```bash
=== arithmetic_unit ===

        +----------Local Count, excluding submodules.
        | 
    14377 wires
    37937 wire bits
       19 public wires
      515 public wire bits
       19 ports
      515 port bits
    12615 cells
     6217   $_AND_
      129   $_DFF_P_
       14   $_NOT_
     1913   $_OR_
     4342   $_XOR_
```

The extra pipeline registers cost 256 additional flip-flops because the intermediate values are 4 x 32-bit `sum` registers = 128 flip-flops and 4 x 32-bit `c` registers = 128 flip-flops. Other than this, the combinational logic is identical and the arithmetic has not changed.