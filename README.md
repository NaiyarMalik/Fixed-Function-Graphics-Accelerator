# Fixed-Function Graphics Accelerator

A hardware graphics rendering accelerator implemented in SystemVerilog, designed to explore GPU architecture through RTL design, simulation, and synthesis.


## Current Progress

### Completed
- Established the initial SystemVerilog project structure.
- Began implementing the rendering controller.
- Defined the initial frame-level control interface, including clock, reset, start signal, and triangle index tracking.

### In Progress
- Developing the `render_controller` module to coordinate rendering operations.
- Defining the control flow and state transitions required to manage the rendering pipeline.
- Establishing interfaces between the controller and future rendering stages.

### Next Steps
- Complete the rendering controller FSM.
- Implement triangle processing and primitive setup.
- Develop the rasterization logic to determine pixel coverage.
- Integrate pixel generation and framebuffer output.
- Create testbenches to verify controller behavior and pipeline operation.
- Run synthesis and analyze timing and resource utilization.

**Development Status:** Early RTL development. The rendering controller is the first step toward building a complete fixed-function graphics pipeline.


## Overview

This project aims to build a fixed-function graphics accelerator that processes geometric primitives and generates pixel-level rendering data through dedicated hardware stages.

Unlike a programmable GPU, which executes general-purpose shader programs, a fixed-function graphics accelerator uses specialized hardware logic to perform predefined rendering operations. This project explores digital design, hardware parallelism, control logic, and graphics architecture.

The accelerator is being developed from the ground up, with an emphasis on modular RTL, clearly defined hardware interfaces, and eventual synthesis and timing analysis.

## Architecture

The design is organized into modular hardware components that collectively implement the rendering pipeline.

### Rendering Pipeline

1. **Input and Command Processing:** Accepts rendering commands and input geometry.
2. **Render Controller:** Coordinates pipeline operations, manages control flow, and tracks rendering progress.
3. **Primitive Processing:** Processes geometric primitives, such as triangles, for subsequent rendering stages.
4. **Rasterization:** Determines which pixels are covered by a primitive.
5. **Pixel Generation:** Generates pixel attributes and output color data for covered pixels.
6. **Framebuffer Interface:** Provides a path for storing or transmitting rendered pixel data.

Pipeline stages will be implemented and integrated incrementally as the architecture develops.

## Design Goals

- Implement a graphics rendering pipeline using synthesizable RTL.
- Develop a modular architecture with clearly defined interfaces.
- Explore finite-state machines, counters, datapaths, and hardware control.
- Implement triangle-based rendering and pixel coverage calculations.
- Verify functionality through simulation and testbenches.
- Synthesize the design and analyze area and timing characteristics.
- Establish a foundation for future graphics hardware experiments.

## Technology Stack

- **HDL:** SystemVerilog
- **Simulation:** RTL simulation and testbenches
- **Version Control:** Git and GitHub
- **Future Goals:** Logic synthesis, static timing analysis, and FPGA prototyping

## Repository Structure

```text
Fixed-Function-Graphics-Accelerator/
├── rtl/             # SystemVerilog hardware modules
├── tb/              # Testbenches and verification
├── docs/            # Architecture notes and design documentation
└── README.md
