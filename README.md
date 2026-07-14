# FPGA-Accelerated Real-Time FIR Filter & Noise Rejection Engine

![Target Hardware: Intel MAX 10](https://img.shields.io/badge/Hardware-Intel_MAX_10_(DE10--Lite)-0071C5?style=for-the-badge&logo=intel)
![Language: Verilog HDL](https://img.shields.io/badge/Language-Verilog_HDL-E34F26?style=for-the-badge)
![Status: Hardware Validated](https://img.shields.io/badge/Status-Hardware_Validated-2EA44F?style=for-the-badge)

## Overview
This repository contains the RTL architecture and hardware verification for a deterministic, low-latency Digital Signal Processing (DSP) engine implemented on an **Intel MAX 10 FPGA (DE10-Lite)**. 

The system performs real-time high-frequency noise attenuation and signal validation for embedded hardware architectures. By implementing a 3-tap Finite Impulse Response (FIR) moving average filter via a feed-forward shift register cascade ($z^{-1}$ delay line), the engine eliminates external memory dependencies and guarantees unconditional system stability. A custom magnitude threshold detector autonomously differentiates transient electromagnetic interference or switch bounce from valid, sustained step inputs.

---

## System Architecture

> **[IMAGE PLACEHOLDER: Insert your high-level RTL Block Diagram / Quartus RTL Viewer screenshot here]**
> *(Recommended format: `./docs/images/rtl_block_diagram.png` showing the 50MHz-to-1Hz Clock Divider, the 3-stage D-Flip-Flop Delay Line, the Combinational Adder, and the Magnitude Threshold Comparator).*

### Architecture Highlights
* **Clock Domain Scaling:** Includes an internal clock divider downscaling the native 50MHz system clock to 1Hz, establishing a visual "slow-motion" execution domain for real-time state tracking and hardware verification.
* **Discrete Time Delay Line:** Implemented using a cascade of D-Flip-Flops (`x_n`, `x_n_1`, `x_n_2`) to store sequential signal history without utilizing external RAM block resources.
* **Zero-Feedback Stability:** Operates as a strictly feed-forward architecture, ensuring that bounded inputs always produce bounded outputs without risk of oscillation or instability.

---

## Mathematical Model

The filter executes a discrete-time moving average summation governed by the following difference equation:

$$y[n] = \sum_{k=0}^{2} x[n-k] = x[n] + x[n-1] + x[n-2]$$

Where:
* $x[n]$ represents the sampled logic state of the GPIO input at the current clock tick.
* $x[n-1]$ and $x[n-2]$ represent delayed time-step samples retrieved from the shift register pipeline.
* $y[n]$ represents the accumulated signal energy across the 3-sample sliding window.

To map the multi-bit summation ($0 \le y[n] \le 3$) to a binary GPIO output, a magnitude threshold detector applies the following decision logic:

$$\text{Output} = \begin{cases} 1 (\text{Valid Signal}), & \text{if } y[n] \ge 2 \\ 0 (\text{Noise Rejected}), & \text{if } y[n] < 2 \end{cases}$$

---

## Hardware Pin Mapping (DE10-Lite)

| Signal Name | FPGA Pin Location | Physical Component | Function Description |
| :--- | :--- | :--- | :--- |
| **MAX10_CLK1_50** | `PIN_P11` | 50MHz Oscillator | Native hardware system clock |
| **SW[0]** | `PIN_C10` | Slide Switch 0 | Raw GPIO stimulus input ($x[n]$) |
| **LEDR[0]** | `PIN_A8` | Red LED 0 | Visualizer for current state ($x[n]$) |
| **LEDR[1]** | `PIN_A9` | Red LED 1 | Visualizer for 1-cycle delay ($x[n-1]$) |
| **LEDR[2]** | `PIN_A10` | Red LED 2 | Visualizer for 2-cycle delay ($x[n-2]$) |
| **LEDR[9]** | `PIN_B11` | Red LED 9 | **Filtered decision output ($y[n]$)** |
| **HEX0[7:0]** | Multiple Pins | 7-Segment Display | Forced High (`8'hFF`) to disable interference |

---

## Hardware Verification & Test Cases

### 1. Impulse Stimulus Test (High-Frequency Noise Rejection)
* **Test Procedure:** Rapidly toggle the GPIO input switch (`SW[0]`) to simulate a transient noise spike or contact bounce.
* **Observed RTL Behavior:** The logic high state propagates sequentially across the delay line (`LEDR[0]` $\to$ `LEDR[1]` $\to$ `LEDR[2]`). Because the pulse duration is shorter than the filter window, the accumulated energy sum never satisfies the threshold condition ($y[n] < 2$).
* **Result:** The decision output (`LEDR[9]`) remains strictly **LOW**, confirming successful noise attenuation.

### 2. Step Stimulus Test (Signal Validation & Group Delay)
* **Test Procedure:** Transition `SW[0]` from low to high and hold the state to simulate a sustained, valid logic command.
* **Observed RTL Behavior:**
  * **$T = 0\text{s}$:** `LEDR[0]` activates. Sum $= 1$. Output (`LEDR[9]`) remains LOW.
  * **$T = 1\text{s}$:** `LEDR[1]` activates. Sum $= 2$. **Output (`LEDR[9]`) transitions HIGH.**
  * **$T = 2\text{s}$:** `LEDR[2]` activates. Sum $= 3$. Output remains HIGH.
* **Result:** Verifies the causal group delay of the DSP pipeline. The system trades a 1-cycle processing latency for absolute signal reliability.

---

## Build & Synthesis Instructions
1. Open **Intel Quartus Prime** (Lite Edition recommended, v20.1+).
2. Create a new project targeting the **10M50DAF484C7G** FPGA device.
3. Add the `Lab2_FIR.v` Verilog HDL source file to the project hierarchy.
4. Import the pin assignments using the **Pin Planner** or by appending the mappings to the `.qsf` file.
5. Run full compilation (Analysis & Synthesis, Fitter, Assembler, Timing Analysis).
6. Connect the DE10-Lite board via USB-Blaster and program the device using the generated `.sof` bitstream.
