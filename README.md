# Fixed-Function Graphics Accelerator

A hardware graphics rendering accelerator implemented in SystemVerilog, designed to explore GPU architecture through RTL design, simulation, and synthesis.


## Current Progress

| Status | Component | Description |
|---|---|---|
| Completed | Render Controller | Implemented the controller responsible for coordinating rendering operations and tracking pipeline progress. |
| Completed | Vertex & Index ROMs | Implemented synchronous memory modules to store 3D model vertices and triangle connectivity data. |
| Completed | Geometry Fetch Stage | Implemented the sub-sequencer that fetches vertex indices and coordinates from ROMs based on triangle indices. |
| Completed | Transform Engine & Angle Counter | Implemented rotation angle tracking and full 3D coordinate transformation using fixed-point math and a trigonometric lookup table. |
| Completed | Projection Stage | Converted 3D transformed vertex coordinates into 2D screen coordinates with preserved depth. |
| Completed | Triangle Rasterizer | Implemented bounding-box traversal and edge processing to identify covered triangle pixels. |
| Completed | Pixel Processor | Generated dynamic color shading and gradients based on pixel coordinates and depth. |
| Completed | Framebuffer Interface | Built dual-port video RAM storage for pixel color writes and display scan reads. |
| Completed | Display Controller | Implemented screen scanning and synchronization signal output for display interfaces. |
| Completed | Top-Level Wrapper (`gpu_top.sv`) | Integrated all pipeline modules into a unified system wrapper. |
| In Progress | Verification & Synthesis | Testing the integrated pipeline in simulation, synthesizing RTL, and tuning timing for physical video interfaces (e.g., VGA timing). |

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

