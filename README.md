[![MATLAB](https://img.shields.io/badge/MATLAB-R2025b-0076A8?logo=mathworks&logoColor=white)](https://www.mathworks.com)
[![Simscape Electrical](https://img.shields.io/badge/Simscape-Electrical-E86100)](https://www.mathworks.com/products/simscape-electrical.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e.svg)](LICENSE)
[![LaTeX](https://img.shields.io/badge/Report-LaTeX-008080?logo=latex&logoColor=white)](#report)

# ⚡ Synchronous Generator Control — Simulation & Analysis

> MATLAB/Simulink simulations of a 555 MVA synchronous generator under load transients, parallel operation, and infinite-bus connection. Built for the EE354 Power Engineering course.

---

## What This Project Covers

Three exercises explore how a synchronous generator behaves in progressively more complex scenarios:

| Exercise | Scenario | What Happens |
|:--------:|----------|--------------|
| **1** | Single machine, load switching | Governor and AVR respond to 100 MW step changes at *t* = 3 s and *t* = 9 s |
| **2** | Two identical generators in parallel | Gen B connects at *t* = 5 s — power sharing depends entirely on governor setpoints |
| **3** | Generator connected to an infinite bus | The grid holds frequency at 1.0 pu — Gen B can only control its own power output |

Each exercise varies Generator B's governor speed reference (0.98 pu or 1.02 pu) to show the difference between motoring and generating conditions.

---

## Repository Structure

```
.
├── Exercise1/                      # Task 1–2: Single machine with AVR + governor
│   ├── Exercise1_SM.slx            #   Simulink model
│   ├── SMControlExample.m          #   Run script
│   └── SMControlPlotResults.m      #   Plotting script
│
├── Exercise2/                      # Task 3–4: Two generators in parallel
│   ├── Exercise2_Parallel.slx
│   ├── SMControlExample.m
│   └── SMControlPlotResults.m
│
├── Exercise3/                      # Task 5–6: Generator vs infinite bus
│   └── Exercise3_infinite.slx
│
├── figures/                        # All 26 result plots (PNG)
│
├── EE354_Report.tex                # Main LaTeX report (modular)
├── sections/                       # LaTeX section files
│   ├── introduction.tex
│   ├── exercise1.tex               #   Tasks 1–2 analysis
│   ├── exercise2.tex               #   Tasks 3–4 analysis
│   ├── exercise3.tex               #   Tasks 5–6 analysis
│   ├── limitations.tex             #   Model assumptions
│   ├── conclusion.tex
│   ├── references.tex
│   ├── appendix.tex
│   └── titlepage.tex
│
├── LICENSE
└── .gitignore
```

---

## Machine Parameters

| Parameter | Value |
|-----------|-------|
| Rated apparent power | 555 MVA |
| Rated voltage (L–L) | 24 kV |
| Rated frequency | 60 Hz |
| Rotor type | Round rotor (1 pole pair) |
| Inertia constant *H* | 3.525 s |
| Governor droop *R* | 5 % |
| AVR model | AC1C (IEEE 421.5) |
| d-axis synchronous reactance *X_d* | 1.81 pu |
| q-axis synchronous reactance *X_q* | 1.76 pu |

---

## Task Summary

### Tasks 1–2 — Single Machine Response

A single generator supplies a 250 MW load. At *t* = 3 s a load block disconnects; at *t* = 9 s a larger load connects.

- **P–f coupling:** load removal → rotor accelerates → governor reduces turbine power
- **Q–V coupling:** load addition → voltage dips to ≈ 0.82 pu → AVR restores it in 3–4 s
- **ROCOF** at *t* = 9 s: ≈ −1.54 Hz/s (calculated from swing equation)

### Tasks 3–4 — Parallel Operation

Two identical generators; Gen B connects at *t* = 5 s with a different governor setpoint.

| | Task 3 | Task 4 |
|-|--------|--------|
| Gen B setpoint | 0.98 pu | 1.02 pu |
| Gen B behaviour | Absorbs power (motors) | Supplies load (generates) |
| System frequency | Settles at ≈ 1.008 pu | Settles at ≈ 1.015 pu |
| Practical outcome | Overloads Gen A — unsafe | Load transferred — desired |

The system frequency after synchronisation is the arithmetic mean of both setpoints (for equal droop and ratings):

$$f_\text{sys} \approx \frac{f_{nl,A} + f_{nl,B}}{2}$$

### Tasks 5–6 — Infinite Bus

Gen A is replaced by an ideal voltage source (constant *V* = 1.0 pu, *f* = 60 Hz).

| | Task 5 | Task 6 |
|-|--------|--------|
| Gen B setpoint | 0.98 pu | 1.02 pu |
| System frequency | 1.000 pu (unchanged) | 1.000 pu (unchanged) |
| Gen B behaviour | Motors (absorbs power) | Generates (injects power) |
| Gen B influence on grid | None | None |

The infinite bus absorbs or supplies whatever power Gen B demands without any frequency or voltage change.

---

## How to Run

### Prerequisites

- **MATLAB R2024b+** (R2025b recommended)
- **Simscape Electrical** toolbox
- **Simulink**

Verify installation:
```matlab
ver('simscape')
ver('simscape_electrical')
```

### Running a Simulation

```matlab
% 1. Open the model
open_system('Exercise1/Exercise1_SM.slx')

% 2. Run
sim('Exercise1_SM')

% 3. Plot results
SMControlPlotResults
```

Repeat for Exercise2 and Exercise3 with their respective `.slx` files.

### Changing Gen B's Setpoint

In the Simulink model, double-click the **Governor** block for Generator B and change the **Speed Reference** parameter:

- `0.98` → under-frequency (Tasks 3, 5)
- `1.02` → over-frequency (Tasks 4, 6)

---

## Report

The full LaTeX report is in [EE354_Report.tex](EE354_Report.tex) with sections in [sections/](sections/). To compile:

1. Upload all `.tex` files and the `figures/` folder to [Overleaf](https://www.overleaf.com)
2. Set `EE354_Report.tex` as the main document
3. Compile with pdfLaTeX

The report covers:
- Component descriptions (synchronous machine, AVR, governor, inertia)
- Governing equations with derivations
- Simulation results with annotated plots
- Comparison tables (finite bus vs infinite bus)
- Model limitations and assumptions

---

## Key Equations

**Swing equation** — rotor dynamics:

$$\frac{2H}{\omega_s}\frac{d\omega}{dt} = P_m - P_e - D(\omega - \omega_s)$$

**Droop characteristic** — governor steady-state:

$$P = \frac{f_{nl} - f_\text{sys}}{S_P}$$

**Power-angle equation** — active power transfer:

$$P \approx \frac{E \cdot V}{X} \sin\delta$$

**Combined droop** — parallel generators:

$$\Delta P_L = -\left(\frac{1}{R_1} + \frac{1}{R_2}\right)\Delta f$$

---

## Results at a Glance

### Exercise 1 — Load Step Response

| Signal | Before *t* = 9 s | Transient | Settled |
|--------|:-:|:-:|:-:|
| Active Power | 150 MW | spike | 350 MW |
| Frequency | ≈ 1.010 pu | dip to 0.980 pu | ≈ 0.990 pu |
| Terminal Voltage | 1.0 pu | dip to 0.82 pu | 1.0 pu (AVR) |

### Grand Comparison — Tasks 3–6

| Parameter | Task 3 (Finite, 0.98) | Task 4 (Finite, 1.02) | Task 5 (Inf, 0.98) | Task 6 (Inf, 1.02) |
|-----------|:-----:|:-----:|:-----:|:-----:|
| System freq | ≈ 1.008 pu | ≈ 1.015 pu | 1.000 pu | 1.000 pu |
| Gen B power | Negative (motors) | Positive (generates) | Negative (motors) | Positive (generates) |
| Gen B freq influence | Pulls down | Pulls up | None | None |

---

## References

1. P. Kundur, *Power System Stability and Control*, McGraw-Hill, 1994.
2. J. Grainger & W. Stevenson, *Power System Analysis*, McGraw-Hill, 1994.
3. J. Glover, M. Sarma & T. Overbye, *Power Systems Analysis and Design*, 6th ed., Cengage, 2017.
4. MathWorks, "Three-Phase Synchronous Machine Control," Simscape Electrical Examples, R2025b.
5. IEEE Std 421.5-2016, "Excitation System Models for Power System Stability Studies."
6. IEEE Std 1110-2019, "Synchronous Generator Modeling Practices."

---

## License

[MIT](LICENSE) — use freely for academic and personal projects.
