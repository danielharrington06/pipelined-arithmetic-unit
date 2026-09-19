# Pipelined Arithmetic Unit

A 4-wide pipelined arithmetic unit implemented in SystemVerilog that computes:
$$y = (a + b) \times c$$

This project includes constrained-random verfication, functional coverage, assertions, logic synthesis and a comparison of pipelined and unpipelined implementations.

## Architecture
The unit processed four independent calculations in parallel. The pipelined implementation splits the computation into two stages:
```
Stage 1                  Stage 2
a + b ---> register ---> * c ---> output register
```

This allows the addition and multiplication to execute across separate clock periods, reducing the combinatorial logic depth of each stage.

## Run and Compile
The testbench can be compiled and run with Verilator:
```bash
verilator --binary --timing --top-module arithmetic_unit_tb src/arithmetic_unit.sv tb/arithmetic_unit_tb.sv

./obj_dir/Varithmetic_unit_tb
```

The testbench performs 1000 constrained-random tests across all four lanes, in addition to explicit edge cases. It checks the pipelined outputs against a software reference model and records coverage of zero values, boundary values, addition overflow and multiplication overflow.

## Synthesis and Timing Comparison

The pipelined RTL was compared against an equivalent unpipelined implementation using Yosys. The unpipelined version performs the addition and multiplication within a single combinatorial stage:
```
a + b ---> * c ---> output register
```
### Resource Usage
| | Pipelined | Unpipelined | Difference |
| --- | ---| --- | --- |
| Combinatorial cells | 12,494 | 12,486 | +8 |
| Flip-flops | 385 | 129 | +256 |
| Total Cells | 12,879 | 12,615 | +264 |

The pipeline requires 256 additional flip-flops for its intermediate values:
- 4 x 32-bit `sum` registers = 128 flip-flops
- 4 x 32-bit `c` registers = 128 flip-flops

The combinatorial logic is otherwise essentially unchanged, since both implementations perform the same four additions and four multiplications.

### Critical-path Analysis
Generic gate-level timing analysis was used to compare the combinational logic depth between sequential elements.

| | Pipelined | Unpipelined | 
| --- | ---| --- |
| Input -> register depth | 62 gates | 74 gates |
| Register -> register depth | 64 gates | 74 gates | 

The pipelined design reduces the synchronous critical path from 74 to 64 mapped gates, a $13.5%$ reduction.

Under an equal-gate-delay model, this corresponds to a theoretical $1.16\times$ improvement in maximum clock frequency. This is a relative logic-depth comparison rather than an absolute timing measurement, as no technology-specific standard-cell library is used.

## Verification
Verification includes:
- 1,000 constrained-random transactions
- Explicit arithmetic edge cases
- Independent software reference model
- Overflow testing
- Functional coverage tracking
- Pipeline latency assertions
- Four independent arithmetic lanes

The reference model explicitly reproduces the 32-bit truncation behaviour of the RTL, ensuring that overflow cases are checked correctly.

```vbnet
pipelined-arithmetic-unit/ 
├── src/ 
│ └── arithmetic_unit.sv 
│
├── tb/ 
│ └── arithmetic_unit_tb.sv 
│
├── synthesis/ 
│ ├── arithmetic_unit_synth.sv 
│ ├── arithmetic_unit_unpipelined.sv 
│ ├── synth_pipelined.ys 
│ ├── synth_unpipelined.ys 
│ ├── pipelined.json 
│ ├── unpipelined.json 
│ └── analyse_timing.py 
│
└── README.md
```
## Tools
- SystemVerilog
- Verilator
- Yosys
- Python
- Z3
- Git