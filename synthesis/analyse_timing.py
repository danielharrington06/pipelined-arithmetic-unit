import json
from pathlib import Path


CELL_TYPES = {
    "$_AND_",
    "$_OR_",
    "$_XOR_",
    "$_NOT_",
    "$_MUX_",
}


def load_netlist(path):
    with open(path) as f:
        return json.load(f)


def get_module(netlist):
    return netlist["modules"]["arithmetic_unit"]


def get_comb_cells(netlist):
    module = get_module(netlist)
    return {
        name: cell
        for name, cell in module["cells"].items()
        if cell["type"] in CELL_TYPES
    }


def get_register_cells(netlist):
    module = get_module(netlist)
    return {
        name: cell
        for name, cell in module["cells"].items()
        if cell["type"] == "$_DFF_P_"
    }


def cell_inputs(cell):
    inputs = []

    for port_name, connections in cell["connections"].items():
        if cell["port_directions"][port_name] == "input":
            inputs.extend(connections)

    return inputs


def cell_outputs(cell):
    outputs = []

    for port_name, connections in cell["connections"].items():
        if cell["port_directions"][port_name] == "output":
            outputs.extend(connections)

    return outputs


def build_register_output_nets(netlist):
    registers = get_register_cells(netlist)
    register_outputs = set()

    for register in registers.values():
        register_outputs.update(cell_outputs(register))

    return register_outputs


def build_primary_input_nets(netlist):
    module = get_module(netlist)
    inputs = set()

    for port in module["ports"].values():
        if port["direction"] == "input":
            inputs.update(port["bits"])

    return inputs


def calculate_depths(netlist):
    combinational = get_comb_cells(netlist)
    register_outputs = build_register_output_nets(netlist)
    primary_inputs = build_primary_input_nets(netlist)

    # Track the combinational depth from the start of each timing path.
    depths = {}

    # Register outputs start new synchronous timing paths.
    for bit in register_outputs:
        depths[bit] = 0

    # Primary inputs also form timing-path starting points.
    for bit in primary_inputs:
        depths.setdefault(bit, 0)

    changed = True

    while changed:
        changed = False

        for cell in combinational.values():
            inputs = cell_inputs(cell)

            if not inputs:
                continue

            input_depths = [
                depths[bit]
                for bit in inputs
                if bit in depths
            ]

            if len(input_depths) != len(inputs):
                continue

            output_depth = max(input_depths) + 1

            for bit in cell_outputs(cell):
                if depths.get(bit, -1) < output_depth:
                    depths[bit] = output_depth
                    changed = True

    return depths


def analyse_paths(netlist):
    module = get_module(netlist)
    registers = get_register_cells(netlist)
    combinational = get_comb_cells(netlist)

    depths = calculate_depths(netlist)

    register_input_depth = {}
    register_output_depth = {}
    output_depth = {}

    # Measure depth immediately before every register.
    for register_name, register in registers.items():
        inputs = cell_inputs(register)

        input_depths = [
            depths[bit]
            for bit in inputs
            if bit in depths
        ]

        if input_depths:
            register_input_depth[register_name] = max(input_depths)

    # Record the depth of each register output.
    for register_name, register in registers.items():
        outputs = cell_outputs(register)

        output_depths = [
            depths[bit]
            for bit in outputs
            if bit in depths
        ]

        if output_depths:
            register_output_depth[register_name] = max(output_depths)

    # Find primary-output depths.
    for port_name, port in module["ports"].items():
        if port["direction"] != "output":
            continue

        depths_for_port = [
            depths[bit]
            for bit in port["bits"]
            if bit in depths
        ]

        if depths_for_port:
            output_depth[port_name] = max(depths_for_port)

    # The useful synchronous metric is the maximum amount of
    # combinational logic between a register output and a register input.
    register_to_register = 0

    for register_name, depth in register_input_depth.items():
        register_to_register = max(register_to_register, depth)

    # Also report primary-input-to-register depth separately.
    #
    # We cannot distinguish the origin of a bit using only the final
    # depth value, so calculate this directly by starting from inputs.
    input_depths = {}

    for bit in build_primary_input_nets(netlist):
        input_depths[bit] = 0

    changed = True

    while changed:
        changed = False

        for cell in combinational.values():
            inputs = cell_inputs(cell)

            if not inputs:
                continue

            input_values = [
                input_depths[bit]
                for bit in inputs
                if bit in input_depths
            ]

            if len(input_values) != len(inputs):
                continue

            depth = max(input_values) + 1

            for bit in cell_outputs(cell):
                if input_depths.get(bit, -1) < depth:
                    input_depths[bit] = depth
                    changed = True

    input_to_register = 0

    for register in registers.values():
        for bit in cell_inputs(register):
            if bit in input_depths:
                input_to_register = max(
                    input_to_register,
                    input_depths[bit],
                )

    return {
        "register_to_register": register_to_register,
        "input_to_register": input_to_register,
        "registers": len(registers),
        "comb_cells": len(combinational),
    }


def analyse(path):
    netlist = load_netlist(path)
    return analyse_paths(netlist)


def main():
    base = Path(__file__).parent

    pipelined = analyse(base / "pipelined.json")
    unpipelined = analyse(base / "unpipelined.json")

    print()
    print("timing analysis")
    print("================")
    print()

    print("pipelined")
    print(f"  combinational cells:       {pipelined['comb_cells']}")
    print(f"  register banks:            {pipelined['registers']}")
    print(
        f"  input -> register depth:   "
        f"{pipelined['input_to_register']} gates"
    )
    print(
        f"  register -> register depth:"
        f" {pipelined['register_to_register']} gates"
    )
    print()

    print("unpipelined")
    print(f"  combinational cells:       {unpipelined['comb_cells']}")
    print(f"  register banks:            {unpipelined['registers']}")
    print(
        f"  input -> register depth:   "
        f"{unpipelined['input_to_register']} gates"
    )
    print(
        f"  register -> register depth:"
        f" {unpipelined['register_to_register']} gates"
    )
    print()

    pipelined_depth = pipelined["register_to_register"]
    unpipelined_depth = unpipelined["register_to_register"]

    if pipelined_depth > 0 and unpipelined_depth > 0:
        reduction = (
            1 - pipelined_depth / unpipelined_depth
        ) * 100

        frequency_improvement = (
            unpipelined_depth / pipelined_depth
        )

        print(
            f"register-to-register critical-path reduction: "
            f"{reduction:.1f}%"
        )

        print(
            f"relative maximum-frequency improvement: "
            f"{frequency_improvement:.2f}x"
        )

    print()


if __name__ == "__main__":
    main()