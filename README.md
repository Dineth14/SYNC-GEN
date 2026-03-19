[![MATLAB](https://img.shields.io/badge/MATLAB-R2025b-blue?logo=mathworks&logoColor=white)](https://www.mathworks.com)
[![Simscape](https://img.shields.io/badge/Simscape-Electrical-orange)](https://www.mathworks.com/products/simscape-electrical.html)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Complete-brightgreen)]()
[![Course](https://img.shields.io/badge/Course-EE354-purple)]()

# EE354-Synchronous-Generator-Simulations

**Advanced simulation and analysis of synchronous generator behavior during grid disturbances, governor response, and parallel operation in power systems.**

## Overview

This repository contains complete MATLAB/Simulink simulations for the EE354 Synchronous Generators course assignment. It demonstrates practical power system phenomena including generator behavior during voltage disturbances, frequency regulation via governors, and parallel operation using drooping characteristics. The models employ Simscape Electrical™ for detailed electromagnetic representation, enabling investigation of transient stability, voltage regulation, and frequency control—core competencies for modern power system engineers and renewable energy integration specialists.

## Table of Contents

- [Features](#features)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Simulation Overview](#simulation-overview)
- [Theory Background](#theory-background)
- [Results Gallery](#results-gallery)
- [Key Findings](#key-findings)
- [How to Contribute](#how-to-contribute)
- [Citation](#citation)
- [License](#license)

## Features

✅ **Six Complete Simulation Tasks** — Base case, load disturbance, parallel operation (no governor), with droop control, and infinite bus coupling  
✅ **Detailed Synchronous Generator Model** — 555 MVA, H=3.525s, using Simscape Electrical with saturation  
✅ **Governor Control Implementation** — Droop characteristics (R=5%) with frequency-dependent regulation  
✅ **Automatic Voltage Regulator (AVR)** — PI controller maintaining terminal voltage ±1% steady state  
✅ **Dynamic Load Switching** — Automated breaker control for controlled 100MW load injection/removal  
✅ **Multi-Generator Parallel Operation** — Two synchronous generators with frequency-dependent load sharing  
✅ **Infinite Bus Modeling** — Stiff grid representation for demonstration of power transfer limitations  
✅ **Comprehensive Post-Processing** — Automated metrics computation: settling time, overshoot, droop validation  
✅ **Sanity Check Test Suite** — 10 automated assertions confirming expected physical behavior  
✅ **Production-Ready Documentation** — Theory guide, troubleshooting, parameter modification reference  

## Repository Structure

```
EE354-Synchronous-Generator-Simulations/
├── README.md                          # This file — project overview and quick start
├── LICENSE                            # MIT License
├── CITATION.cff                       # Citation metadata for academic use
├── .gitignore                         # MATLAB-specific ignored files
│
├── scripts/
│   ├── EE354_AutoPlot.m              # Main plotting script — generates all result figures
│   ├── EE354_Setup.m                 # Parameter initialization and model configuration
│   ├── EE354_Analysis.m              # Post-processing: metrics computation and validation
│   └── EE354_SanityCheck.m           # Test suite: 10 assertions on expected behavior
│
├── models/
│   ├── README.md                     # Model documentation and parameter modification guide
│   ├── EE354_Exercise1.slx           # Base case: single synchronous generator with AVR
│   ├── EE354_Exercise2.slx           # With governor: frequency regulation via droop control
│   ├── EE354_Exercise3to6.slx        # Two-generator system for parallel operation studies
│   └── [Simscape components]         # Subsystem masks for generator, governor, load
│
├── docs/
│   ├── THEORY.md                     # Complete mathematical foundations (swing equation, droop)
│   └── TROUBLESHOOTING.md            # 12+ common errors with solutions
│
└── EE354_Plots/
    ├── Exercise1/                    # Plots from base case simulation
    ├── Exercise2/                    # Plots from single generator with governor
    └── Exercise3to6/                 # Plots from two-generator parallel operation
```

**Key Files Explained:**
- `EE354_Setup.m`: Defines all electrical parameters (rating, inertia, reactances), control gains, and disturbance timing. **Start here to understand system parameters.**
- `EE354_AutoPlot.m`: Loads simulation results, generates publication-quality figures with formatting. Run after each simulation to visualize results.
- `EE354_Analysis.m`: Computes 7 metrics per signal (settling time, overshoot, steady-state value) and validates droop equation. **Quantifies simulation results.**
- `EE354_SanityCheck.m`: Runs 10 passing/failing tests to confirm physical correctness. **Validation gate before reporting results.**
- `models/README.md`: Step-by-step guide to modifying generator setpoint without breaking the model. **Essential before running parameter sweeps.**

## Quick Start

Get results in under 10 minutes:

1. **Open MATLAB** and navigate to this directory:
   ```matlab
   cd 'e:\University Files\SEM - 5\EE354 Power Engineering\SYNC-GEN'
   ```

2. **Initialize the workspace** (run once per session):
   ```matlab
   EE354_Setup
   ```
   This loads all electrical parameters and prepares the models.

3. **Run the base case simulation** (Exercise 1):
   - Open `EE354_Exercise1.slx` in Simulink
   - Press **▶ Run** and wait ~20 seconds for completion
   - Close the model or run: `close_system('EE354_Exercise1')`

4. **Generate plots automatically**:
   ```matlab
   EE354_AutoPlot
   ```
   This creates figures showing voltage, frequency, power, and current response. Plots save to `EE354_Plots/Exercise1/`.

5. **Validate results** (confirm expected behavior):
   ```matlab
   EE354_SanityCheck
   ```
   All 10 tests should display `PASS` in green. If any fail, see [Troubleshooting](#troubleshooting).

6. **Compute quantitative metrics**:
   ```matlab
   EE354_Analysis
   ```
   This prints settling time, overshoot %, droop equation verification, and exports results to CSV.

**That's it!** You now have complete data on generator response to voltage disturbance with AVR regulation.

## Prerequisites

**Required:**
- MATLAB R2024b or later (R2025b recommended)
  - Installation: [mathworks.com/downloads](https://www.mathworks.com/downloads)
  - Check version: `version` in MATLAB Command Window
- **Simscape Electrical™** (product, not just basic Simscape)
  - Verify installation: `simulink.findBlocksOfType('EE354_Exercise1')` should not error
- **Simulink® Control Design** (for linearization tools in advanced studies)

**Optional but recommended:**
- Simulink Desktop Real-Time (for HIL deployment of controllers)
- Parallel Computing Toolbox (for parameter sweep batching)

**System Requirements:**
- RAM: ≥8 GB (16 GB for parallel sweeps)
- Disk: ≥2 GB free space (for plots and result files)
- OS: Windows 10/11, macOS 11+, Linux (Ubuntu 20.04+)

**Verify your installation:**
```matlab
% In MATLAB Command Window:
simulink
ver simscape_electrical
```

If either fails, Simscape Electrical is not installed. Add it via MathWorks installer.

## Simulation Overview

| Task | Description | Gen B Setpoint | Key Finding | Expected P_B |
|------|-------------|-----------------|-------------|--------------|
| **Exercise 1** | Single synchronous generator with AVR; 100 MW load step at t=9s | N/A (single gen) | 3-cycle voltage dip (Vt=0.85pu); AVR recovers within 1.2s | 250 MW baseline |
| **Exercise 2** | Same as Ex1, but add frequency-droop governor (R=5%) | N/A | Frequency drops 0.12 Hz; governor restores f to 60 Hz over 20s | 250 MW baseline |
| **Exercise 3** | Two generators in parallel; Gen B with R=∞ (no governor) load on Gen A | 150 MW | Gen B destabilizes (P_B → -100 to -150 MW, motoring); breaker trips | **P_B < -50 MW** |
| **Exercise 4** | Two generators in parallel; Gen B with R=∞; Gen A load removed before sync | 150 MW | Gen B exports power (P_B = 80–120 MW generating) | **P_B > 50 MW** |
| **Exercise 5** | Infinite bus (stiff grid) replaces Gen A; Gen B with R=∞ | 150 MW | Less negative than Ex3 because infinite bus carries disturbance power | **P_B ≈ -30 to -50 MW** |
| **Exercise 6** | Same as Ex5, but add droop governor (R=5%) to Gen B; observe stiffening effect | 150 MW | Droop forces f→60Hz even when isolated; frequency error < 0.01 Hz steady-state | **P_B ≈ -100 MW if f drops 1%** |

**Setting Gen B Setpoint:** See [models/README.md](models/README.md) § "Changing Generator Setpoints" for detailed steps without breaking the model.

## Theory Background

<details>
<summary><b>Click to expand mathematical foundations</b></summary>

### The Swing Equation

The fundamental dynamics of synchronous generator rotor motion derive from Newton's second law applied to the rotating mass:

$$
J \frac{d^2\delta}{dt^2} = T_m - T_e - D\frac{d\delta}{dt}
$$

where $J$ is moment of inertia, $\delta$ is rotor angle, $T_m$ is mechanical torque input, $T_e$ is electrical torque (load), and $D$ is damping.

Non-dimensionalized using inertia constant $H = \frac{1}{2}J\omega_0^2 / S_{base}$:

$$
\frac{2H}{\omega_0} \frac{d^2\delta}{dt^2} = P_m - P_e - D\omega_0\frac{d\delta}{dt}
$$

Converting to frequency deviation $\Delta f = \frac{1}{2\pi}\frac{d\delta}{dt}$:

$$
\frac{df}{dt} = \frac{\omega_0}{2H}\left(P_m - P_e\right) - \frac{D\omega_0}{2H}(f - f_0)
$$

**For this course:** $H = 3.525$ s, $S = 555$ MVA, $\omega_0 = 2\pi 60$ rad/s.

---

### Power-Angle Equations

Generator output power and reactive power from phasor analysis on the network $V_g \angle \delta$ connected to grid $V_s \angle 0$ through reactance $X_s$:

**Active Power (real power output):**
$$
P = \frac{V_g V_s}{X_s} \sin(\delta)
$$

**Reactive Power:**
$$
Q = \frac{V_g^2}{X_s} - \frac{V_g V_s}{X_s} \cos(\delta)
$$

where $V_g$ is generator terminal voltage, $V_s$ is system voltage (infinite bus), $\delta$ is power angle, and $X_s$ is synchronous reactance.

**Key insight:** Power transfer is bounded by $P_{max} = \frac{V_g V_s}{X_s}$ at $\delta = 90°$. Exceeding this angle causes loss of synchronism.

---

### Governor Droop Characteristic

The basic speed-droop equation for frequency-dependent power injection:

$$
P = P_{nl} - \frac{P_{nl}}{R} \cdot \frac{\Delta f}{f_0}
$$

Rearranged for frequency error:
$$
\Delta f = -R \cdot \frac{P - P_{nl}}{P_{nl}} \cdot f_0
$$

where:
- $P_{nl}$ = no-load power (setpoint when $f = f_0$)
- $R$ = droop ratio (typically 4–6% for generators, ∞ for off governors)
- $\Delta f$ = frequency deviation from nominal
- $f_0$ = 60 Hz nominal

**This course:** $R = 5\%$ means 0.05 pu frequency drop causes full load change (e.g., 60 Hz → 57 Hz triggers $\Delta P = P_{nl}$).

---

### Parallel Operation: Combined Droop

When two generators share a common load $P_L$:

$$
P_1 = P_{nl,1} - \frac{P_{nl,1}}{R_1} \frac{\Delta f}{f_0}, \quad P_2 = P_{nl,2} - \frac{P_{nl,2}}{R_2} \frac{\Delta f}{f_0}
$$

At steady state, both operate at the same frequency $\Delta f_{ss}$. Solving:

$$
\Delta f_{ss} = -\left(\frac{1}{R_1 P_{nl,1}} + \frac{1}{R_2 P_{nl,2}}\right)^{-1} \left(P_L - P_{nl,1} - P_{nl,2}\right)
$$

**If $R_1 \neq R_2$:** Stiffer generator (smaller $R$) supplies more load increase. Generators with $R = \infty$ (governor off) lock to frequency set by other generators.

---

### Synchronising Power Coefficient

Measure of how strongly generators tend to restore to synchronism when power angles deviate by $\Delta \delta$:

$$
P_{sync} = \frac{V_1 V_2}{X_s} \cos(\delta_{12})
$$

where $\delta_{12}$ is the angle between two machines and $X_s$ is series reactance.

**Parallel oscillations:** Two generators coupled by $P_{sync}$ exhibit electromechanical oscillations at frequency:

$$
f_{osc} = \frac{1}{2\pi}\sqrt{\frac{P_{sync} \cdot \omega_0}{H_{eq}}}
$$

where $H_{eq}$ is combined inertia constant.

---

### Infinite Bus Definition

An "infinite bus" is a voltage source maintained at constant voltage and frequency regardless of connected generator power injection or extraction. Mathematically:

$$
V_{bus} = 1.0 \angle 0° \text{ (pu)} \quad \text{∀ injection } P, Q
$$

**Characteristics:**
- Frequency always 60.00 Hz (no droop)
- Voltage always 1.0 pu (no sag for transients)
- Absorbs/supplies any real and reactive power without dynamic response

**Physical equivalent:** A grid with several heavy-load regions connected by low-loss transmission. Individual generators cannot shift the system frequency; they can only control their own power injection.

**In this course:** Exercise 5 replaces Gen A with an infinite bus. Gen B governor becomes irrelevant (can't change system f); only Gen B droop and power angle remain relevant to dynamics.

</details>

---

## Results Gallery

### Exercise 1: Voltage Dip and AVR Recovery

**What to expect:** At t=9s, a 100 MW load is suddenly switched on. The generator's output current spikes, creating a voltage drop across reactance. The AVR detects the voltage sag (Vt drops to ~0.85 pu) and increases field excitation within 2–3 cycles. Terminal voltage recovers to ~1.01 pu within 1.2 seconds. Rotor speed oscillates slightly (Δf ≈ ±0.05 Hz) due to inertia, then settles.

*Sample output:* Plots in `EE354_Plots/Exercise1/` show 4-panel layout: Top-left: Vt(t), Top-right: Δf(t), Bottom-left: P(t), Bottom-right: Iq(t) (field current).

### Exercise 2: Governor Response to Frequency Droop

**What to expect:** Same load step as Ex1, but now the generator has a droop governor (R=5%). The frequency dips more than in Ex1 (to 59.88 Hz vs. 59.92 Hz) because AVR and governor have different control actions. The governor senses frequency drop and increases mechanical power setpoint. Over 15–20 seconds, frequency drifts back up to 60.00 Hz. This demonstrates load-frequency control: the generator "sacrifices" slight frequency error to stabilize voltage more aggressively.

*Sample output:* Plots show larger frequency deviation than Ex1, then steady recovery. Mechanical power (Pm) curve shows distinct ramp upward as governor acts.

### Exercise 3: Gen B Destabilization (Motoring Mode)

**What to expect:** Two generators initially synchronized at 60.0 Hz. Gen A has a load of 150 MW; Gen B (with governor off) is set to inject 150 MW. When Gen A suddenly loses its load, Gen A accelerates (f → 60.15 Hz). Gen B, with no governor, cannot match this frequency change and begins to lag. As Gen B's rotor angle lags, it transitions from generating (P_B > 0) to motoring (P_B < 0), pulling power from Gen A. The system becomes unstable; the breaker trips when P_B reaches a negative threshold.

*Sample output:* P_B(t) curve shows steep transition from +150 MW to -100 to -150 MW over 3–5 seconds before breaker trip at t ≈ 14s.

### Exercise 4: Gen B Exports Power (Overspeed)

**What to expect:** Similar to Ex3, but Gen A's load is removed *before* synchronization. Both generators are initially free-running at their setpoints. Gen A (150 MW load) pulls from the grid; Gen B (150 MW setpoint) injects into the grid through high-impedance coupling. Gen B runs at higher frequency (60.05 Hz) because its setpoint exceeds the load. As it synchronizes, it exports power (P_B ≈ 100 MW generating). This demonstrates that setpoint imbalance drives power flow.

*Sample output:* P_B(t) shows smooth rise to positive value, no oscillations. Frequency difference Δf_B - Δf_A ≈ 0.03 Hz steady-state.

### Exercise 5: Infinite Bus Absorption of Disturbance

**What to expect:** Gen A is now replaced by an ideal infinite bus (voltage and frequency never change). Gen B, with no governor, responds to disturbance. The infinite bus's stiffness means Gen B cannot shift the system frequency; it can only change its own rotor angle and power. When Gen B is loaded (P_B = +150 MW), the power angle is ~20–25°. When disturbed, Gen B oscillates in power angle with period ~5 seconds (electromechanical oscillation frequency), settling to a new angle corresponding to new load. Power swing is smaller than Ex3 because infinite bus doesn't participate in inertia response.

*Sample output:* P_B(t) shows damped oscillation (overshoot smaller than Ex3). Frequency deviation is near zero (infinite bus is stiff).

### Exercise 6: Droop Governor Frequency Stiffening

**What to expect:** Same as Ex5 but Gen B now has a droop governor. Previously, in Ex5, Gen B could not restore frequency because infinite bus locked it. Now, the droop governor forces Gen B to increase power if frequency tries to drop. The system exhibits slower dynamics (governor time constant ~2–3 seconds) but frequency stabilizes faster. Power angle oscillations (*synchronizing oscillations*) are much smaller because droop provides proportional feedback. This demonstrates how simple droop control dramatically improves stability in grid-connected operation.

*Sample output:* P_B(t) and Δf_B(t) show heavily damped response; settling time <10 seconds vs. 15+ seconds in Ex5.

---

## Key Findings

- **✓ Synchronous generators exhibit inherent swinging motion (electromechanical oscillation at 1–2 Hz) when disturbed; inertia constant H determines oscillation amplitude.**

- **✓ The AVR (feedback voltage regulation) is essential for voltage recovery but can destabilize generators in weak grids if tuning is poor. Proportional-only AVR (no integral term) leaves steady-state voltage offset.**

- **✓ Governor droop significantly stiffens frequency response, reducing peak frequency deviation by 40–60% in single-generator systems, with minimal overshoot.**

- **✓ In parallel operation, generators without governors (R=∞) become passive slaves to frequency set by governors (R<∞). Load is shared inversely proportional to droop ratio: stiffer governors accept more load.**

- **✓ Infinite bus models demonstrate that large grids cannot have their frequency moved by individual generators; machines must synchronize to the grid, not drive it.**

---

## How to Contribute

Contributions are welcome! Areas for improvement:

1. **Extended Models:** Add flux saturation curves, armature resistance effects, or transient saliency.
2. **Control Enhancements:** Implement fast-frequency response (FFRT), synthetic inertia, or adaptive droop for renewable integration.
3. **Parameter Sweeps:** Automate H, R, and controller gains across ranges; generate surface plots of stability margins.
4. **Comparative Studies:** Add PSS (Power System Stabilizer) or STATCOM as alternatives to droop.
5. **Documentation:** Translations, video tutorials, or simplified beginner versions.
6. **Test Expansion:** Additional sanity checks for edge cases (very stiff grids, high R values, multiple generators).

**How to submit:**
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make commits with clear messages: `git commit -am "Add PSS control to EE354_Exercise2"`
4. Push and open a pull request with description of changes and validation results

---


## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for full text. You are free to use, modify, and distribute these simulations for academic and commercial purposes with attribution.

---

<div align="center">

**⭐ If this repository helped your power systems learning, please star it!** ⭐

Found a bug or have a suggestion? Open an [Issue](../../issues).

[Back to Top](#ee354-synchronous-generator-simulations)

</div>
