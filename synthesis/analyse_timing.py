import json
from collections import defaultdict, deque
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


def get_comb_cells(netlist):
    return {
        name: cell
        for name, cell in netlist["modules"]["arithmetic_unit"]["cells"].items()
        if cell["type"] in CELL_TYPES
    }


def get_register_cells(netlist):
    return {
        name: cell
        for name, cell in netlist["modules"]["arithmetic_unit"]["cells"].items()
        if cell["type"] == "$_DFF_P_"
    }


def build_driver_map(netlist):
    module = netlist["modules"]["arithmetic_unit"]

    drivers = {}

    for cell_name, cell in module["cells"].items():
        for port_name, connections in cell["connections"].items():
            if cell["port_directions"][port_name] != "output":
                continue

            for bit in connections:
                drivers[bit] = cell_name

    return drivers


def build_fanout_map(netlist):
    module = netlist["modules"]["arithmetic_unit"]

    fanout = defaultdict(list)

    for cell_name, cell in module["cells"].items():
        for port_name, connections in cell["connections"].items():
            if cell["port_directions"][port_name] != "input":
                continue

            for bit in connections:
                fanout[bit].append(cell_name)

    return fanout


def cell_inputs(cell):
    inputs = []

    for port_name, connections in cell["connections"].items():
        if cell["port_directions"][port_name] == "input":
            inputs.extend(connections)

    return inputs


def calculate_depths(netlist):
    module = netlist["modules"]["arithmetic_unit"]

    combinational = get_comb_cells(netlist)
    registers = get_register_cells(netlist)
    drivers = build_driver_map(netlist)
    fanout = build_fanout_map(netlist)

    # depth of each net relative to the previous register boundary
    depths = {}

    # outputs of registers start a new timing stage
    for register_name, register in registers.items():
        for port_name, connections in register["connections"].items():
            if register["port_directions"][port_name] == "output":
                for bit in connections:
                    depths[bit] = 0

    # primary inputs also start a timing path
    for port_name, port in module["ports"].items():
        if port["direction"] == "input":
            for bit in port["bits"]:
                depths[bit] = 0

    # repeatedly propagate depth through combinational cells
    changed = True

    while changed:
        changed = False

        for cell_name, cell in combinational.items():
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

            for port_name, connections in cell["connections"].items():
                if cell["port_directions"][port_name] != "output":
                    continue

                for bit in connections:
                    if depths.get(bit, -1) < output_depth:
                        depths[bit] = output_depth
                        changed = True

    # find the deepest combinational cell
    deepest_cell = None
    deepest_depth = 0

    for cell_name, cell in combinational.items():
        inputs = cell_inputs(cell)

        input_depths = [
            depths[bit]
            for bit in inputs
            if bit in depths
        ]

        if len(input_depths) != len(inputs):
            continue

        depth = max(input_depths) + 1

        if depth > deepest_depth:
            deepest_depth = depth
            deepest_cell = cell_name

    return deepest_depth, deepest_cell, depths


def analyse(path):
    netlist = load_netlist(path)

    depth, deepest_cell, depths = calculate_depths(netlist)

    return {
        "depth": depth,
        "deepest_cell": deepest_cell,
        "comb_cells": len(get_comb_cells(netlist)),
        "registers": len(get_register_cells(netlist)),
    }


def main():
    base = Path(__file__).parent

    pipelined = analyse(base / "pipelined.json")
    unpipelined = analyse(base / "unpipelined.json")

    print()
    print("timing analysis")
    print("================")
    print()

    print("pipelined")
    print(f"  combinational cells: {pipelined['comb_cells']}")
    print(f"  register banks:      {pipelined['registers']}")
    print(f"  critical depth:      {pipelined['depth']} gates")
    print()

    print("unpipelined")
    print(f"  combinational cells: {unpipelined['comb_cells']}")
    print(f"  register banks:      {unpipelined['registers']}")
    print(f"  critical depth:      {unpipelined['depth']} gates")
    print()

    if pipelined["depth"] > 0:
        reduction = (
            1
            - unpipelined["depth"] / pipelined["depth"]
        ) * -100

    if unpipelined["depth"] > 0:
        improvement = (
            1
            - pipelined["depth"] / unpipelined["depth"]
        ) * 100

        print(
            f"critical-path reduction: {improvement:.1f}%"
        )

        print(
            f"relative maximum-frequency improvement: "
            f"{unpipelined['depth'] / pipelined['depth']:.2f}x"
        )

    print()


if __name__ == "__main__":
    main()