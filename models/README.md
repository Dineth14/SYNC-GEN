# Simulink Models Guide

This directory contains three comprehensive Simulink models for the EE354 synchronous generator simulations. This guide explains the model structure, how to interpret results, and how to safely modify parameters.

## Table of Contents

1. [Model Overview](#model-overview)
2. [Model Relationships](#model-relationships)
3. [Parameter Modification Guide](#parameter-modification-guide)
4. [How to Change Generator B Setpoint](#how-to-change-generator-b-setpoint)
5. [Understanding Synchronization Breaker](#understanding-synchronization-breaker)
6. [Adding Measurement Blocks](#adding-measurement-blocks)
7. [Common Pitfalls](#common-pitfalls)

---

## Model Overview

### EE354_Exercise1.slx
**Single synchronous generator with Automatic Voltage Regulator (AVR)**

**Represents:** Single machine against infinite bus with voltage control, no frequency control (no governor).

**Key blocks:**
- **Generator**: 555 MVA, H=3.525s, X_s=0.35pu, with saturation
- **AVR**: PI feedback controller maintaining Vt = 1.0 pu ±0.01 pu
- **Load**: 250 MW baseline + 100 MW disturbance at t=9s (via SW_Load)
- **Measurement blocks**: Vt, f, P, Iq (field current)

**Disturbance sequence:**
1. t=0-9s: Steady state, P=250 MW, V=1.0 pu, f=60 Hz
2. t=9s: 100 MW load step ON (via relay)
3. t=9-15s: Transient response; AVR acts to recover voltage
4. t>15s: New steady state, P≈250 MW still, f≈60 Hz (AVR regulates, no governor)

**Output:** Figure showing voltage recovery dynamics; frequency dip but steady recovery

---

### EE354_Exercise2.slx
**Single synchronous generator with AVR AND governor (droop control)**

**Represents:** Same as Exercise 1, but with frequency-dependent power adjustment via governor.

**Additional blocks vs. Exercise 1:**
- **Governor**: Droop ratio R=5% (adjustable via mask parameter)
  - Transforms: P_ref = P_nl - (P_nl/R)*(Δf/f_0)
  - Acts over time constant T_gov ≈ 0.2s

**Disturbance sequence:** Same as Ex1

**Expected behavior change:**
- Frequency dips further initially (because governor takes time to respond)
- Over 15–20 seconds, governor increases mechanical power → frequency returns to 60.0 Hz
- **Key insight:** Governor sacrifices 0.3 Hz frequency dip to achieve 15–20 s recovery (load-frequency control)

**Output:** Plots show larger frequency dip than Ex1, but cleaner recovery curve

---

### EE354_Exercise3to6.slx
**Two synchronous generators with flexible coupling**

**Represents:** Parallel operation, generator synchronization, and grid-coupled studies.

**Key blocks:**
- **Generator A**: 250 MW nominal, with governor (R=5%)
- **Generator B**: 150 MW nominal, governor setpoint variable (R=5% or ∞ selectable)
- **Synchronization Breaker**: Closes at t=10s (after transients settle), connecting Gen A and Gen B
- **Infinite Bus Option**: Can replace Generator A with stiff grid for Exercises 5–6
- **Measurement blocks**: For each generator: Vt, ωrotor, P, Q, δ (power angle)

**Selector/Mask Parameters:**
- `Generator_B_Gov`: 1=Governor ON (R=5%), 0=Governor OFF (R=∞)
- `Generator_B_P_setpoint_MW`: Nominal power injection point (50–200 MW range safe)
- `Load_Disturbance_Type`: 'ramp', 'step', or 'sine' (for exploration)
- `Use_Infinite_Bus`: 1=Replace Gen A with infinite bus (Exercises 5–6), 0=Use Gen A (Ex 3–4)

**Disturbance sequence (Exercises 3–4):**
1. t=0-10s: Single Gen A operation with 150 MW load in parallel with Gen B (unconnected)
2. t=10s: Synchronization breaker closes; Gen B connects to Gen A
3. t=10-12s: Transient synchronization oscillations (electromechanical 1.2 Hz)
4. t>12s: Parallel steady state; power shared per droop equations

**Exercise 5–6 sequence (Infinite Bus):**
1. t=0-10s: Gen B nominal operation against infinite bus
2. t=10s: Disturbance applied (frequency or power step)
3. t=10-20s: Transient response of Gen B only; infinite bus frequency locked
4. t>20s: Gen B steady state; droop governor (if enabled) stabilizes power angle

---

## Model Relationships

```
┌─────────────────────────────────────┐
│  EE354_Exercise1.slx                │  Single Gen + AVR only
│  ├─ Generator (Simscape Electrical) │  (baseline, no control)
│  ├─ AVR Controller (PI)             │
│  ├─ Load (SW + constant)            │
│  └─ Measurements                    │
└────────────────┬────────────────────┘
                 │ Add Governor
                 ▼
┌─────────────────────────────────────┐
│  EE354_Exercise2.slx                │  Single Gen + AVR + Governor
│  ├─ Generator (same as Ex1)         │  (frequency regulation)
│  ├─ AVR Controller (same)           │
│  ├─ Governor (Droop R=5%)           │
│  ├─ Load (same as Ex1)              │
│  └─ Measurements (same)             │
└────────────────┬────────────────────┘
                 │ Add second generator
                 ▼
┌─────────────────────────────────────┐
│  EE354_Exercise3to6.slx             │  Parallel operation (flexible)
│  ├─ Generator A                     │  ├─ Gov ON (R=5%)
│  ├─ Generator B                     │  ├─ Gov: selectable R
│  ├─ Synchronization Breaker         │  ├─ Can replace Gen A
│  ├─ Measurements (dual)             │  │  with Infinite Bus
│  ├─ Disturbance sources             │  │  (Ex 5–6)
│  └─ Optional Infinite Bus           │
└─────────────────────────────────────┘
```

**Design pattern:** Each model is complete and **independently runnable**. They share electrical parameters (loading those from `EE354_Setup.m`) but model structure differs to isolate specific phenomena.

---

## Parameter Modification Guide

### Most-Changed Parameters

| Parameter | Location | Impact | Safe Range | Default |
|-----------|----------|--------|------------|---------|
| **P_nominal_MW** | Mask / Data Dict | Generator power rating | 100–400 MW | 250 MW |
| **H** | Mask / Data Dict | Inertia constant | 2–6 s | 3.525 s |
| **X_s** | Mask / Data Dict | Synchronous reactance | 0.25–0.50 pu | 0.35 pu |
| **R_droop** | Mask / Data Dict | Droop ratio | 0.02–0.10 | 0.05 (5%) |
| **Kp_AVR, Ki_AVR** | Mask / Data Dict | AVR control gains | Kp: 5–50, Ki: 0.5–10 | 20, 5 |
| **T_gov** | Mask / Data Dict | Governor time constant | 0.1–0.5 s | 0.2 s |
| **Load_MW** | Scope / Constant | Applied load magnitude | 0–500 MW | 100 MW |

### Safe Parameter Modification Workflow

**Step 1: Identify the parameter in Simulink**
```
1. Open model: open('models/EE354_Exercise1.slx')
2. Right-click Generator subsystem → Edit Mask
3. Find parameter in dialog (e.g., S_rating_MVA)
4. Note its Variable Name (e.g., 'S_rated')
```

**Step 2: Modify via EE354_Setup.m (RECOMMENDED)**
```matlab
% In EE354_Setup.m, before running simulation:
S_rated = 555;        % MVA (default)
H_const = 3.525;      % seconds
X_sync = 0.35;        % pu
R_droop = 0.05;       % 5%
f_nominal = 60;       % Hz
```

Then run:
```matlab
EE354_Setup    % Loads parameters into MATLAB workspace
sim('models/EE354_Exercise1.slx')  % Simulink reads from workspace
```

**Step 3: Alternatively, modify in GUI**
```
1. Open model in Simulink
2. Simulink → Simulation → Model Settings
3. Find parameter (Ctrl+F search)
4. Double-click to edit
5. Save model (Ctrl+S)
```

**Step 4: Verify change**
```matlab
% After modification, run sanity checks:
EE354_Analysis
EE354_SanityCheck
```

**⚠️ DO NOT:**
- Change parameter values inside generator/load blocks directly (use masks)
- Delete measurement blocks (analysis scripts need them)
- Change solver settings without understanding effects (use Solver: ode23t, MaxStep=0.001s)

---

## How to Change Generator B Setpoint

This is the **most common modification** for exploring parallel operation behavior.

### Method 1: Mask Parameter (EASY)

**Step 1:** Open Exercise 3–6 model
```matlab
open('models/EE354_Exercise3to6.slx')
```

**Step 2:** Double-click "Generator B" subsystem (blue rect)

**Step 3:** Find field "P_setpoint_MW" in the dialog
- Current default: 150 MW
- Change to desired value (50–250 MW range safe)

**Step 4:** Click OK

**Step 5:** Save model
```matlab
Ctrl+S  % or File → Save
```

**Step 6:** Run simulation
```matlab
Press ▶ Run button  % or sim('models/EE354_Exercise3to6.slx')
```

### Method 2: EE354_Setup.m (RECOMMENDED for batch runs)

```matlab
% In EE354_Setup.m:
P_setpoint_B_MW = 150;  % Change this before calling setup

EE354_Setup              % Load parameter into workspace
sim('models/EE354_Exercise3to6.slx')  % Simulink reads P_setpoint_B_MW
```

**Advantage:** Changes persist across multiple simulations and runs.

### Method 3: Programmatic (For Parameter Sweeps)

```matlab
% Run Exercise 3 with Gen B setpoint sweep
P_sweep = [100, 125, 150, 175, 200];  % MW values
results = {};

for P_B = P_sweep
    % Assign to workspace
    assignin('base', 'P_setpoint_B_MW', P_B);
    
    % Run simulation
    simOut = sim('models/EE354_Exercise3to6.slx');
    
    % Store result
    results{end+1} = simOut;
    fprintf('Completed P_B = %.0f MW\n', P_B)
end

% Analyze results (plot P_B vs. settling time, overshoot, etc.)
```

### What Happens When You Change P_B Setpoint?

| P_B Setpoint | Behavior | Reason |
|--------------|----------|--------|
| **50 MW** | Gen B imports power | Gen B demand < Gen A supply ability |
| **100 MW** | Gen B near balance with Gen A | Equilibrium around 120 Hz system frequency |
| **150 MW** | Gen B exports power | Gen B setpoint > Gen A base load |
| **200 MW** | Gen B exports significantly | Large power imbalance → large power angle |
| **250 MW** | Instability risk! | Power angle > 60° → approaching slack bus limit |

**Physical insight:** Power angle δ relates to setpoint difference. Larger difference → larger δ → risk of loss of synchronism (δ > 90°).

---

## Understanding Synchronization Breaker

The synchronization breaker connects two generators when conditions are favorable.

### How It Works (Block Diagram)

```
Generator A ──┐
              ├─→ [Breaker Logic] ──→ [Breaker (Switch)] ──→ Shared Bus
Generator B ──┘                         
                                (closed at t=10s)
```

### Synchronization Conditions (Typical)

Before breaker closes, the breaker logic checks:

1. **Frequency matching:** |f_A - f_B| < 0.1 Hz
2. **Voltage matching:** |V_t,A - V_t,B| < 0.05 pu
3. **Power angle:** |δ_A - δ_B| < 20° (electromechanical angle)
4. **Time condition:** t > t_sync (closure time)

If all conditions met → Breaker closes; generators now share common bus.

### Why This Matters

- **Too early closure:** Large angle difference → unstable synchronization
- **Too late closure:** Generator waits unnecessarily; simulation time wasted
- **Poor frequency match:** Generator slips into motoring (draws power instead of supplying)

### In This Course

The model simplifies to: **Close at t=10s if conditions approximately met**

In Practice: Real synchronizers use phase-matching relays and frequency deviation limits.

---

## Adding Measurement Blocks

If you need to measure additional quantities (field voltage, rotor speed, etc.):

### Step 1: Locate desirable signal in Simulink model

```
1. Open EE354_Exercise3to6.slx
2. Double-click Generator subsystem → see internal structure
3. Look for output port labeled with desired quantity
   Example: "ωrotor" (rotor speed in rad/s), "Vf" (field voltage)
```

### Step 2: Bring signal to top level

```
1. Right-click output port → Add Connection-Point Trigger / Annotation
2. Draw line from port upward (out of subsystem)
3. Select "Create Output Port" when exiting subsystem box
4. Name the port (e.g., "rotor_speed")
```

### Step 3: Connect to Scope or To Workspace block

```
1. From Simulink Library:
   Sinks > Scope (for visualization)
   OR
   Sinks > To Workspace (for data export to MATLAB)
2. Connect measurement port to block input
```

### Step 4: Configure output variable

```
MATLAB: Simulink > Data Import/Export → Output
- Output variable name: "simOut"
- Save as single object: checked
- Format: timeseries
```

### Step 5: Run simulation and access in MATLAB

```matlab
sim('models/EE354_Exercise3to6.slx')
rotor_speed = simOut.rotor_speed;  % Access added measurement
```

---

## Common Pitfalls

### ❌ Pitfall 1: "Algebraic Loop" Error After Parameter Change

**Cause:** Load resistance changed, breaking steady-state constraints.

**Fix:**
1. Go to Simulink → Data Import/Export
2. Uncheck "Use local solver" (if available)
3. Set Solver to ode23t (trapezoidal, handles stiff systems better)
4. Set MaxStep = 0.001 s

### ❌ Pitfall 2: Generator Accelerates Uncontrollably

**Cause:** No load (infinite bus disconnected or removed); generator has no electrical brake.

**Fix:**
- Ensure load or infinite bus is connected
- Add minimum 5–10 MW load (dummy load) for stability
- Check that P_setpoint < P_max (0.8 pu rated)

### ❌ Pitfall 3: Breaker Won't Close (Synchronization Fails)

**Cause:** Generators too far out of phase; power angle > 30° at closure time.

**Fix:**
- Increase sync time: `sync_time = 10 → 12 seconds`
- Reduce Gen B power setpoint (smaller imbalance)
- Extend governor response time (slows Gen A acceleration)

### ❌ Pitfall 4: AVR Causes Voltage Hunting (Oscillation)

**Cause:** PI gains too aggressive (Kp or Ki too high).

**Fix:**
```matlab
% In mask or EE354_Setup:
Kp_AVR = 20;   % Reduce from 50
Ki_AVR = 5;    % Reduce from 10
```
Retry simulation; voltage should settle smoothly in <2 seconds.

### ❌ Pitfall 5: Droop Equation Doesn't Match Simulation

**Cause:** Governor model includes time delay (low-pass filter); droop equation is steady-state only.

**Fix:**
- Compare only steady-state values (last 10% of signal, 20+ seconds into simulation)
- Allow 5–10 second settling window for governor response
- Check `EE354_Analysis` output for droop verification table

---

## Summary: Workflow for Safe Parameter Studies

```
1. Open EE354_Setup.m
   └─ Modify: S_rated, H_const, X_sync, R_droop, P_setpoint
   
2. Run: EE354_Setup
   └─ Loads parameters to MATLAB workspace
   
3. Run simulation:
   └─ Simulink reads parameters from workspace
   └─ Model: sim('models/EE354_Exercise3to6.slx')
   
4. Analyze results:
   └─ EE354_AutoPlot    (visualize)
   └─ EE354_Analysis    (compute metrics)
   └─ EE354_SanityCheck (validate physics)
   
5. If not as expected:
   └─ Adjust parameters, repeat steps 1–4
```

**This ensures** parameter changes propagate correctly, are documented in code, and don't break models accidentally.

---

## Questions?

- **Model structure:** See [../docs/THEORY.md](../docs/THEORY.md) for mathematical foundations
- **Errors:** See [../docs/TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) for 12+ solutions
- **Analysis help:** Run `help('EE354_Analysis')` in MATLAB Command Window

