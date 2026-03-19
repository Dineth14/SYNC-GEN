# EE354 – Complete MATLAB R2025b Implementation Guide
## Step-by-Step: Building All Three Simulation Models from Scratch

---

## BEFORE YOU START — Checklist

- [ ] MATLAB R2025b installed
- [ ] Simscape Electrical toolbox installed (check: `ver` in Command Window → look for "Simscape Electrical")
- [ ] You are working in a dedicated folder, e.g. `C:\EE354\` or `~/EE354/`
- [ ] You have run `openExample('simscapeelectrical/SMControlExample')` at least once to confirm it loads

---

## STEP 0 — Get the Base Example

Open MATLAB, then in the Command Window type:

```matlab
openExample('simscapeelectrical/SMControlExample')
```

The model **Three-Phase Synchronous Machine Control** opens. You will see:
- A Synchronous Machine (Round Rotor)
- AVR and Exciter block (top left)
- Governor and Prime Mover block (left)
- Machine Inertia block (H symbol)
- Initial Load (right)
- Load Step off and Load Step on (far right, with Circuit Breakers)
- Measurement block outputting ΔP and ΔQ

**Do NOT modify this example directly.** Save a copy immediately:

```matlab
% In the MATLAB Command Window:
saveas(bdroot, fullfile(pwd, 'EE354_Exercise1_Base.slx'))
close_system(bdroot)
open('EE354_Exercise1_Base.slx')
```

---

## STEP 1 — Exercise 1: Verify and Add Measurement Outputs

### 1a. Verify Solver Settings
Press **Ctrl+E** (Model Configuration Parameters):
- Solver pane → Type: **Variable-step** → Solver: **ode23t**
- Max step size: **0.001**
- Stop time: **15**

### 1b. Verify Synchronous Machine Parameters
Double-click the **Synchronous Machine Round Rotor (Standard)** block:

| Parameter | Correct Value |
|-----------|--------------|
| Rated apparent power (VA) | 555e6 |
| Rated voltage (V, L-L RMS) | 24000 |
| Frequency (Hz) | 60 |
| Number of pole pairs | 1 |
| Ra | 0.003 |
| Xd | 1.81 |
| Xq | 1.76 |
| Xd' | 0.30 |
| Xq' | 0.65 |
| Xd'' | 0.23 |
| Xq'' | 0.25 |
| H (inertia, Initialization pane) | 3.525 |
| D (damping) | 0.01 |

On the **Initialization** pane, confirm:
- Terminal voltage: 24000 V
- Terminal angle: 0 degrees
- Active power: 250e6 W
- Reactive power: 15e6 VAr

### 1c. Add Scope Outputs / To Workspace Blocks
The example already has a scope. To export data to the MATLAB workspace for plotting:

**For each signal below, add a "To Workspace" block:**

1. From **Simulink Library Browser** → **Simulink** → **Sinks** → drag **To Workspace** onto canvas
2. Connect it to the signal
3. In its dialog: set **Variable name**, **Save format: Timeseries**, **Sample time: -1**

Signals to log:

| Signal | Source in Model | Workspace Variable Name |
|--------|----------------|------------------------|
| Rotor speed (pu) | R port of Synchronous Machine → Governor output | `speed_data` |
| Active power Pe (W) | ΔP output of measurement block (multiply by S_rated: 555e6) | `Pe_data` |
| Reactive power Qm (VAr) | ΔQ output × 555e6 | `Qm_data` |
| Terminal voltage (pu) | Measurement block Vt output | `Vt_data` |
| Mechanical power Pm | Governor & Prime Mover output (gc port) | `Pm_data` |

**Tip:** Right-click any signal line → **Log Selected Signal** to use Simulink Data Inspector instead of To Workspace blocks.

### 1d. Add Frequency Measurement
The machine has 1 pole pair, so electrical frequency = mechanical speed:
1. Tap off the speed signal (at the R port or the pu_output line)
2. Add a **Gain** block (value = 60) to convert pu → Hz
3. Connect to a To Workspace block named `freq_Hz_data`

### 1e. Run Exercise 1
```matlab
sim('EE354_Exercise1_Base')
```

After the simulation completes, run **EE354_AutoPlot.m** (set `RUN_SIMULATIONS = false` first to test, then `true` when you have all the signal names matched up).

---

## STEP 2 — Exercise 2: Two Generators in Parallel

### 2a. Save a Fresh Copy
```matlab
copyfile('EE354_Exercise1_Base.slx', 'EE354_Exercise2_Parallel.slx')
open('EE354_Exercise2_Parallel.slx')
```

### 2b. Rename Existing Blocks as "Generator A"
1. Double-click the **Synchronous Machine** block → Properties → rename to **Generator A**
2. Double-click the **AVR and Exciter** subsystem → rename to **Gen A AVR Exciter**
3. Double-click the **Governor and Prime Mover** → rename to **Gen A Governor Prime Mover**
4. Double-click the **Machine Inertia** → rename to **Gen A Inertia**

### 2c. Add Generator B
1. Select all Generator A blocks (machine + AVR + Governor + Inertia): click and drag a selection box around them all
2. **Ctrl+C** → click empty space above → **Ctrl+V**
3. Rename all copied blocks to use "B": **Generator B**, **Gen B AVR Exciter**, **Gen B Governor Prime Mover**, **Gen B Inertia**

### 2d. Add Synchronisation Breaker
1. From Simulink Library Browser → **Simscape** → **Electrical** → **Switches & Breakers** → find **Three-Phase Breaker** (or **Three-Phase Circuit Breaker**)
2. Place it between Generator B's three-phase output and the main bus
3. Wire Generator B: `~` ports → Breaker → main bus (same bus that Generator A connects to)

**Wiring the breaker control:**
1. Add a **Step** block: Initial value = 0, Final value = 1, Step time = **5** (close at t=5s)
2. Connect Step output → Breaker control input (the signal port)

### 2e. Set Generator B Speed Reference

**For Task 3 (lower frequency, 0.98 pu):**
1. Double-click **Gen B Governor Prime Mover** to open the subsystem
2. Find the **Speed Reference** constant/gain block (usually a Constant block set to `0.998` for Gen A)
3. Change it to **0.98**
4. Save the model

**For Task 4 (higher frequency, 1.01 pu):**
- Repeat step above, set to **1.01**

**Alternative — use a variable parameter:** Add a variable in the model workspace:
```matlab
% In MATLAB workspace before running:
GenB_speedref = 0.98;   % change to 1.01 for Task 4
```
Then inside the Gen B Governor, reference `GenB_speedref` as the speed setpoint.

### 2f. Add Measurement Blocks for Both Generators
For each generator, add:
- **Three-Phase V-I Measurement** (Simscape Electrical → Measurements) at the generator terminals
- Connect its outputs to **Power (Active)** and **Power (Reactive)** calculation blocks, or use the existing ΔP/ΔQ measurement method
- Add **To Workspace** blocks for `P_A`, `Q_A`, `Vt_A`, `speed_A` and `P_B`, `Q_B`, `Vt_B`, `speed_B`

### 2g. Solve Initialization Issues
With two generators, the solver initialization is more complex:
1. Double-click the **Solver Configuration** block (small box usually near the bottom of the canvas)
2. Set **Consistency Tolerance** to `1e-9`
3. Enable **"Use local solver"** only if directed by a solver error

**Initial conditions for Gen B** (before breaker closes):
The generator B machine block needs initialization. Set on the **Initialization** pane:
- Active power: `0` W (unloaded before connecting)
- Or use the same as Gen A if steady-state is needed before t=5s

### 2h. Run Task 3 and Task 4
```matlab
% Task 3
% (Set GenB speed ref to 0.98 in the Governor block)
sim('EE354_Exercise2_Parallel')
% Save results
Task3_P_A = P_A.Data; Task3_P_B = P_B.Data;
Task3_f_A = speed_A.Data*60; Task3_f_B = speed_B.Data*60;
% etc.
save('Task3_Results.mat','Task3_P_A','Task3_P_B','Task3_f_A','Task3_f_B')

% Task 4
% (Change GenB speed ref to 1.01)
sim('EE354_Exercise2_Parallel')
% Save as Task4_...
```

---

## STEP 3 — Exercise 3: Infinite Bus

### 3a. Save a Fresh Copy
```matlab
copyfile('EE354_Exercise2_Parallel.slx', 'EE354_Exercise3_InfiniteBus.slx')
open('EE354_Exercise3_InfiniteBus.slx')
```

### 3b. Delete Generator A (Replace with Infinite Bus)
1. Select and delete: **Generator A**, **Gen A AVR Exciter**, **Gen A Governor Prime Mover**, **Gen A Inertia** — all blocks related to Generator A
2. Keep the bus connection point and the load

### 3c. Add Three-Phase Voltage Source (Infinite Bus)
1. In Simulink Library Browser → **Simscape** → **Electrical** → **Sources** → **Three-Phase Voltage Source**
2. Place it where Generator A was
3. Configure the block:
   - **Phase-to-phase voltage (RMS)**: `24000` V (24 kV — match the system)
   - **Phase angle of phase A**: `0` degrees
   - **Frequency**: `60` Hz
   - **Source resistance** (Rs): `0.0001` Ω (near-ideal, makes it an infinite bus)
   - **Source inductance** (Ls): `0` (or very small, e.g., `1e-6`)
4. Connect the three phase terminals (`A`, `B`, `C`) to the main bus

> **Why this is an infinite bus:** A voltage source with near-zero impedance maintains fixed terminal voltage and frequency regardless of load current. This is the mathematical definition of an infinite bus.

### 3d. Remove Load from Generator A Side
The initial load was shared. Now the load should be connected directly to the infinite bus side. Verify the load block is connected to the main bus, not to where Generator A was.

### 3e. Keep Generator B and Breaker
Generator B, its AVR, Governor, Inertia, and the synchronisation breaker remain unchanged from Exercise 2. The Step block at t = 5 s still closes the breaker.

### 3f. Run Task 5 (Gen B @ 0.98) and Task 6 (Gen B @ 1.01)
Same procedure as Exercise 2 — change the Gen B speed reference, run, save results.

---

## COMMON ERRORS AND FIXES

### Error: "Algebraic loop detected"
**Fix:** In the Solver Configuration block, check that there is no direct feedthrough. Add a Unit Delay block (Ts = 1e-4) in the loop, or enable the algebraic loop solver option.

### Error: "Simulation does not reach steady state"
**Fix:** Increase the simulation stop time to 20–30 s. Reduce step size to `5e-4`.

### Error: "Voltage source block not found in library"
**Fix:** The full path is: `simscapeelectrical/Sources/Three-Phase Voltage Source`. If still not found, try searching "three phase voltage" in the Library Browser search bar.

### Error: Generator B goes unstable when breaker closes
**Fix:** The pre-synchronisation frequency difference is too large. Use `0.995` instead of `0.98`, or `1.005` instead of `1.01`. Also check that both generators are fully initialised before t = 5 s.

### Error: "Cannot find system 'GenB_Governor/Speed_ref'"
**Fix:** The internal block path depends on how you built the subsystem. Open the Governor subsystem, find the Constant block for speed reference, and note its exact name. Update the `set_param` call in your automation script accordingly.

### Error: Signal to To Workspace has wrong size
**Fix:** Set the **Output dimensions** on the To Workspace block to `-1` (inherit from signal). Also set **Save format** to `Timeseries` (not `Array`).

---

## QUICK REFERENCE — Where to Find Each Block

| Block | Library Path |
|-------|-------------|
| Three-Phase Voltage Source | Simscape → Electrical → Sources |
| Three-Phase Breaker | Simscape → Electrical → Switches & Breakers |
| Three-Phase V-I Measurement | Simscape → Electrical → Sensors & Transducers |
| To Workspace | Simulink → Sinks |
| Gain | Simulink → Math Operations |
| Step | Simulink → Sources |
| Solver Configuration | Simscape → Utilities |

---

## PARAMETER SUMMARY TABLE

| Parameter | Exercise 1 | Exercise 2 (T3) | Exercise 2 (T4) | Exercise 3 (T5) | Exercise 3 (T6) |
|-----------|-----------|----------------|----------------|----------------|----------------|
| Gen A setpoint | 0.998 pu | 0.998 pu | 0.998 pu | — (infinite bus) | — (infinite bus) |
| Gen B setpoint | — | **0.98 pu** | **1.01 pu** | **0.98 pu** | **1.01 pu** |
| Sync breaker time | — | t = 5 s | t = 5 s | t = 5 s | t = 5 s |
| Load step OFF | t = 3 s | — | — | — | — |
| Load step ON | t = 9 s | — | — | — | — |
| Sim stop time | 15 s | 15 s | 15 s | 15 s | 15 s |
| Expected Gen B P_ss | — | < 0 (motoring) | > 0 (generating) | < 0 (motoring) | > 0 (generating) |
| Expected f_sys_ss | ~0.99 pu | ~1.008 pu | ~1.023 pu | 1.000 pu (fixed) | 1.000 pu (fixed) |
