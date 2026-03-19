# Troubleshooting Guide: EE354 Synchronous Generator Simulations

This document addresses the most common errors and issues arising from running the EE354 models. Each entry includes exact error message(s), root cause, and step-by-step resolution.

## Quick Diagnostics

**Before spending time troubleshooting, verify:**

1. MATLAB version: `version` in Command Window. Require **R2024b or later**. (Simscape Electrical syntax changed in R2024b.)
2. Simscape Electrical installed: `simulink & ver simscape_electrical`. Should list version 7.X or higher.
3. Current folder: `cd 'e:\University Files\SEM - 5\EE354 Power Engineering\SYNC-GEN'`. Exact path.
4. Initialization run: `EE354_Setup`. If errors, see [Error #1](#error-1-ee354_setup-undefined-variable-or-function).

---

## Error #1: EE354_Setup Undefined Variable or Function

| **Error Message** |
|-------------------|
| `Undefined function or variable 'EE354_Setup'.` |

### Cause
MATLAB cannot find the script folder. Working directory is incorrect, or script was moved.

### Fix

**Step 1:** Check current directory
```matlab
pwd  % Should show: e:\University Files\SEM - 5\EE354 Power Engineering\SYNC-GEN
```

**Step 2:** If path is wrong, change it
```matlab
cd 'e:\University Files\SEM - 5\EE354 Power Engineering\SYNC-GEN'
```

**Step 3:** Verify script exists
```matlab
which EE354_Setup.m  % Should return full file path
```

**Step 4:** If not found, check folder structure
```matlab
ls scripts/  % or dir('scripts/') on Windows
```

Should list: `EE354_Setup.m`, `EE354_AutoPlot.m`, `EE354_Analysis.m`, `EE354_SanityCheck.m`

**Step 5:** Add scripts folder to path (temporary for this session)
```matlab
addpath(pwd + "\scripts")  % MATLAB R2024b+
addpath([pwd '\scripts'])  % Alternative for older versions
```

**Step 6:** Retry
```matlab
EE354_Setup
```

---

## Error #2: Undefined Function 'simscape_electrical'

| **Error Message** |
|-------------------|
| `Undefined function or variable 'simscape_electrical'.` |
| `Error in EE354_Setup.m at line 15: initSimscapeElectrical` |

### Cause
Simscape Electrical is not installed, or license not activated.

### Fix

**Step 1:** Check installation
```matlab
ver simscape_electrical
```

- ✓ **If it lists version (e.g., "Simscape Electrical 7.4"):** License activated. Proceed to Step 4.
- ✗ **If "Simscape Electrical" is not listed:** Not installed.

**Step 2 (if not installed):** Install via MathWorks App Installer
1. Open MATLAB
2. Home > Add-Ons > Get Add-Ons (top menu)
3. Search: `Simscape Electrical`
4. Click "Install"
5. Follow prompts (requires MathWorks account + valid license)
6. Restart MATLAB

**Step 3 (if installed but not activated):** Activate license
1. File > License Center
2. Verify Simscape Electrical is listed with status "Active"
3. If "inactive" or "No License", contact your institution's MathWorks administrator

**Step 4:** Retry setup
```matlab
restart  % Restart kernel
EE354_Setup
```

---

## Error #3: Cannot Open Model File

| **Error Message** |
|-------------------|
| `Cannot open model file 'EE354_Exercise1.slx'. File not found.` |
| `No such file or directory` |

### Cause
Simulink file (.slx) missing or in wrong folder.

### Fix

**Step 1:** Verify models folder
```matlab
ls models/  % or dir('models/') on Windows
```

Should show: `EE354_Exercise1.slx`, `EE354_Exercise2.slx`, etc.

**Step 2:** If missing, check backup location
- Windows File Explorer: navigate to `e:\University Files\SEM - 5\EE354 Power Engineering\SYNC-GEN\models`
- Verify `.slx` files are there (not `.slx~` backup files)

**Step 3:** If files exist but MATLAB doesn't find them:
```matlab
cd models/
open('EE354_Exercise1.slx')  % Fully qualified open
```

**Step 4:** If still fails, model file may be corrupted
- Close all Simulink windows: `close_system('EE354_Exercise1')`
- Delete `slprj/` folder: `rmdir('slprj', 's')`
- Contact course instructor for clean model file

---

## Error #4: Simulink Model Fails to Run ("Algebraic Loop")

| **Error Message** |
|-------------------|
| `Algebraic loop detected in model 'EE354_Exercise1'.` |
| `Algebraic loop blocks: [generator/electrical port] --> [measurements/V port]` |

### Cause
Measurement block configured to output directly feeds back without delay. Voltage measurement outputs instantaneous signal, which loops through algebraic constraint.

### Fix

**Step 1:** Identify the loop
- Run model; Simulink highlights the problematic connection
- Usually between generator terminal voltage and control system feedback

**Step 2:** Insert delay in measurement path
1. Double-click the voltage measurement block (usually named `V_terminal` or similar)
2. Check "Add measurement filter" → Set to first-order lag, $T = 0.001$ s
3. Click OK

**Step 3:** Clear caches
```matlab
close_system('EE354_Exercise1')
clear all
bdclose all
```

**Step 4:** Retry simulation
- Open model: `open('models/EE354_Exercise1.slx')`
- Press ▶ Run

**Step 5:** If persists, check for combinatorial loops
- In Simulink, go to Tools > Model Advisor
- Run "Check for Algebraic Loops" (high priority)
- Follow recommendations to insert delays or change block ordering

---

## Error #5: Simulation Initializes Fail

| **Error Message** |
|-------------------|
| `Failed to initialize model 'EE354_Exercise1'. Inconsistent initial conditions.` |
| `Generator initial speed invalid: omega = X rad/s (expected ~377)` |

### Cause
Initial power flow has unmatched mechanical/electrical power; mechanical power setpoint exceeds steadystate limit; or voltage initialization violates algebraic constraints.

### Fix

**Step 1:** Check steady-state operating point
```matlab
EE354_Setup  % Ensure parameters loaded
disp(['Rated Power: ' num2str(Prated_MW) ' MW'])
disp(['Initial P_setpoint: ' num2str(P_initial_MW) ' MW'])
```

**Step 2:** Verify initial power is reasonable
- Should be **40--80% of rated** (555 MVA ≈ 444 MW max for 0.8 PF)
- In code: set `P_initial_MW = 250` (middle of range)

**Step 3:** Check initial voltage setpoint
- Should be 1.0 pu ±0.02 pu
- In code: `V_initial_pu = 1.0`

**Step 4:** Run simulation initialization-only mode
1. In Simulink, go to Tools > Parameter Estimation > Trimming Tool
2. Select generator subsystem
3. Click "Compute Trim"
4. Review computed initial states (should give green checkmarks)
5. Apply to model

**Step 5:** Alternatively, auto-initialize via `simset`
```matlab
options = simset(sim_options, ...
    'InitialState', 'Auto', ...
    'SolverType', 'Rapid Accelerator');
```

**Step 6:** Retry
```matlab
sim('models/EE354_Exercise1.slx', options)
```

---

## Error #6: Generator Uncontrollably Accelerates (Speed → ∞)

| **Error Message** |
|-------------------|
| Simulation runs but speed keeps increasing; no convergence; simulation halts at 30 min |

### Cause
Governor off ($R = \infty$) **and** no electrical load attached. Generator has no resistive torque; mechanical power drives uncontrolled acceleration.

### Fix

**Step 1:** Verify electrical load is present
- Check Simulink model: generator terminal should connect to grid or load
- If disconnected, generator acts as free motor (no stable operation)

**Step 2:** Add a minimum electrical load
- If intentionally testing open-circuit, add **dummy load** at terminal
  - 5–10% of rated MVA minimum
  - E.g., 27.75–55.5 MVA in parallel with grid

**Step 3:** If governor is off ($R = \infty$), verify this is intentional
- Check Exercise 3: single generator with no governor should not accelerate if well-damped
- If it does, reduce mechanical power setpoint or increase damping in AVR

**Step 4:** Check mechanical input power constraint
```matlab
P_mech_setpoint = 0.25;  % pu, baseline for 250 MW
```
During disturbance, ensure ``P_mech`` doesn't exceed setpoint (governor should limit it).

**Step 5:** Enable damping
- AVR should include **frequency droop term** (not just voltage regulation)
- Mechanical load model should include frequency-dependent damping: $P_L = P_0 + kf \cdot \Delta f$

**Step 6:** Retry with finite droop ratio (even if not testing governor)
- Change generator governor droop from ∞ to 0.1 (10% very stiff) temporarily
- Run simulation
- If it stabilizes, original issue confirmed: need load or finite droop

---

## Error #7: Breaker Won't Close (Synchronization Fails)

| **Error Message** |
|-------------------|
| Breaker remains open after synchronization time; Gen B never connects |
| Power angle between generators > 90° (unstable) |

### Cause
Two generators too far out of phase when synchronization time arrives. Angle difference > ~20° means forces are repulsive (unstable sync).

### Fix

**Step 1:** Verify synchronization parameters
```matlab
sync_time_s = 10.0;  % When Gen B breaker closes
% Check if Gen A and Gen B are within 2° of each other at this time
```

**Step 2:** Extend sync time
- Increase `sync_time_s` (e.g., 10 → 12 seconds)
- Allows longer settling before attempting connection
- Usually 2–3 seconds after main disturbance settles

**Step 3:** Reduce Gen B initial power setpoint
- Set `P_setpoint_B_MW = 100` (lower than 150) during synchronization
- Lower mismatch reduces angle difference
- Increase afterward once connected

**Step 4:** Add frequency-matching pre-sync logic
```matlab
% Check frequency within 0.05 Hz before closing breaker
if abs(omega_A - omega_B) < 0.05 * 2*pi
    breaker_command = 1;  % Close
else
    breaker_command = 0;  % Stay open
end
```

**Step 5:** Enable soft-start ramp
- Instead of abrupt power demand at sync, ramp over 0.5–1.0 s:
```matlab
if t < sync_time
    P_ref_B = 0;  % Off
elseif t < sync_time + 1.0
    P_ref_B = 150 * (t - sync_time);  % Ramp
else
    P_ref_B = 150;  % Full power
end
```

**Step 6:** Retry simulation
- Adjust `sync_time_s` and `P_setpoint_B_ramp` as needed
- Monitor power angle; should increase gradually to 15–25° at steady state

---

## Error #8: AVR Oscillates Uncontrollably (Voltage Hunting)

| **Error Message** |
|-------------------|
| Voltage overshoots ±5% and oscillates; never settles; appears as ~ 5–10 Hz ripple in Vt |

### Cause
AVR controller (PI loop) tuning is too aggressive (proportional gain too high) or integral term too large. Causes overshoot and hunting.

### Fix

**Step 1:** Identify loop tuning
```matlab
% In EE354_Setup.m:
Kp_avr = 50;  % Proportional gain; reduce to 20--30
Ki_avr = 10;  % Integral gain; reduce to 1--5
```

**Step 2:** Reduce proportional gain
- Change `Kp_avr` from (e.g.) 50 → 30
- Retry simulation
- Monitor voltage settling time; should be < 2 seconds

**Step 3:** Reduce integral gain
- Change `Ki_avr` from (e.g.) 10 → 2
- Integral term can cause slow drift and oscillation if too large

**Step 4:** Use classical tuning rule
- For simplicity: $K_p = 10$, $K_i = K_p / T_i$ where $T_i = 2$ s (integral time)
- This yields: $K_p = 10$, $K_i = 5$

**Step 5:** Simulate and observe
```matlab
sim('models/EE354_Exercise1.slx')
% Voltage should settle in < 1.5 s with minimal overshoot
```

**Step 6:** If tuning unclear, use MATLAB's Tuning Tool
```matlab
sisotool  % Opens SISO loop tuning GUI
% Load AVR compensator; use Bode/root-locus to find stable gains
```

---

## Error #9: AVR Not Regulating (Voltage Stays Constant Despite Load)

| **Error Message** |
|-------------------|
| Terminal voltage Vt unchanging at 1.0 pu, even when 100 MW load step applied |
| AVR output (field current) is constant; not adjusting |

### Cause
AVR is disabled, or PI gains set to zero, or voltage feedback not connected to controller input.

### Fix

**Step 1:** Verify AVR gains are nonzero
```matlab
EE354_Setup
disp(['Kp_avr = ' num2str(Kp_avr)])  % Should be > 0
disp(['Ki_avr = ' num2str(Ki_avr)])  % Should be > 0
```

**Step 2:** Check voltage feedback connection in Simulink
1. Open model: `open('models/EE354_Exercise1.slx')`
2. Find voltage measurement block (labeled `V_term` or similar)
3. Drag from output to AVR controller input
4. (Should already be connected; if not, reconnect)

**Step 3:** Check AVR reference voltage
- Should be set to 1.0 pu (nominal)
```matlab
V_ref_pu = 1.0;  % Setpoint
```

**Step 4:** Verify controller is enabled (not in bypass)
- In Simulink, right-click AVR controller block
- Check "Enable block" (should be checked)

**Step 5:** Test with manual field adjustment
```matlab
% Temporarily set field current manually to maximum
V_field = 1.5 * V_field_nominal;
```
Run simulation. If voltage rises sharply, AVR block is OK but gains are wrong. Proceed to Error #8.

If voltage doesn't change, generator or measurement block problem. Check terminal connection.

**Step 6:** Check generator model configuration
- Terminal voltage output should be accessible (not hidden)
- Verify generator block is in "Steady-state+Transient" mode, not "Average electrical behavior"

---

## Error #10: Generator Goes Unstable During Synchronization

| **Error Message** |
|-------------------|
| Simulation runs but power angle δ exceeds 90° and keeps growing (rotor slips) |
| Power P_B oscillates with increasing amplitude → numerical divergence |

### Cause
Synchronizing power (restoring torque) is insufficient to hold machine in sync. Power angle drifts past critical angle.

### Fix

**Step 1:** Check generator operating point
- Verify both machines within rated power (< 0.8 pu)
- Verify both at same frequency (within 0.1 Hz) at sync time

**Step 2:** Increase synchronizing power (stiffness)
- Reduce transmission impedance: X_sync from 0.35 pu → 0.20 pu
- (Physically, means better coupling, shorter/thicker line)

```matlab
X_sync_pu = 0.20;  % More stiff, larger Psync
```

**Step 3:** Active damping (droop governor)
- Add droop governor to the machine that's slipping
- Even R=0.10 (10% droop) provides stability
- Governor feedback adds damping to oscillations

**Step 4:** Phase-shift angle ramp
- Don't demand full power immediately at sync time
- Ramp generator load over 1–2 seconds:

```matlab
if t < sync_time + ramp_duration
    power_fraction = (t - sync_time) / ramp_duration;
else
    power_fraction = 1.0;
end
P_setpoint = power_fraction * P_nominal;
```

**Step 5:** Numerical solver tuning
- Simulink default may be too coarse for fast dynamics
- Go to Simulation > Solver Settings
- Change MaxStep to 0.001 s (default often 0.01 s)
- Change solver from ode45 (variable step) to ode23t (trapezoidal, better for stiff systems)

**Step 6:** Check power angle at sync
```matlab
angle_diff = atan2(Im_V1, Re_V1) - atan2(Im_V2, Re_V2);
if abs(angle_diff) > 20*pi/180  % > 20°
    disp('WARNING: Large angle difference at sync. Reduce load or extend sync time.')
end
```

---

## Error #11: Result Plots Are Blank or Missing

| **Error Message** |
|-------------------|
| `EE354_AutoPlot` runs without error, but plots folder is empty |
| Or figures appear but labels/axes are blank |

### Cause
Simulation results file not saved, or plot script is looking in wrong folder.

### Fix

**Step 1:** Verify simulation output is saved
```matlab
% In Simulink model, check Data Import/Export settings:
% Simulink > Data Import/Export → check "Save as single object"
% Output variable should be: simOut or simOut_Ex1
```

**Step 2:** Manually save simulation results
```matlab
open('models/EE354_Exercise1.slx')
sim('models/EE354_Exercise1.slx')
% After run, save results:
save('results_Ex1.mat', 'simOut')  % or whatever output variable created
```

**Step 3:** Check plot script folder expectation
```matlab
open('scripts/EE354_AutoPlot.m')
% Look for lines like:
% load('results_Ex1.mat')  or  load('../EE354_Plots/simOut.mat')
% Verify these files/paths exist
```

**Step 4:** Create missing folders
```matlab
mkdir('EE354_Plots')
mkdir('EE354_Plots/Exercise1')
mkdir('EE354_Plots/Exercise2')
mkdir('EE354_Plots/Exercise3to6')
```

**Step 5:** Modify plot script to use correct paths
- If results are in different folder, update script
```matlab
% Add at top of EE354_AutoPlot.m:
results_path = 'e:\University Files\SEM - 5\EE354 Power Engineering\SYNC-GEN\results_Ex1.mat';
load(results_path)
```

**Step 6:** Retry
```matlab
EE354_AutoPlot
% Check folder: e:\University Files\SEM - 5\EE354 Power Engineering\SYNC-GEN\EE354_Plots\Exercise1\
```

---

## Error #12: Sanity Check Fails ("Expected P > 0 but got P < 0")

| **Error Message** |
|-------------------|
| `EE354_SanityCheck` returns red FAIL on test 3, 6, or 7 |
| Test message: `FAIL: Task 3 Gen B power should be < 0 (motoring). Got P_B = 200 MW` |

### Cause
Simulation behavior doesn't match expected physics. Often due to wrong parameter, wrong disturbance timing, or control loop malfunction.

### Fix

**Step 1:** Check test expectations vs. setup
```matlab
% Run sanity check verbosely:
open('scripts/EE354_SanityCheck.m')
% Read comments for each test; verify it matches Exercise description
```

**Step 2:** Verify correct simulation data loaded
```matlab
% In EE354_SanityCheck.m, check which result file is loaded:
load('results_Ex3.mat')  % Should match the exercise being tested
```

**Step 3:** Re-run source simulation with fresh setup
```matlab
EE354_Setup  % Fresh parameters
% Run: open('models/EE354_Exercise3.slx') → Press Run
% Wait for completion; close model
```

**Step 4:** If test still fails, examine actual value
```matlab
% Add diagnostic plot to sanity check:
figure, plot(simOut.P_B.time, simOut.P_B.data)
xlabel('Time (s)'), ylabel('Gen B Power (MW)')
% Visually inspect: does it dip negative as expected around t=10--15s?
```

**Step 5:** Check Exercise definition
- Refer to [docs/THEORY.md](docs/THEORY.md) § "Simulation Overview Table"
- Ex3: Gen B should motor (P_B < 0) when Gen A load is removed suddenly
- If Gen A load was never applied, or applied at wrong time, this test will fail

**Step 6:** Modify test tolerance if needed
```matlab
% In EE354_SanityCheck.m:
test_threshold = -50;  % MW; adjust if simulation is physically correct but value slightly different
if min(P_B_data) < test_threshold
    disp('PASS')
else
    disp('FAIL (but may be physically acceptable if within 20%)')
end
```

**Step 7:** If still failing, run `EE354_Analysis` for detailed metrics
```matlab
EE354_Analysis
% Prints table with actual steady-state values; compare to expected
```

---

## General Diagnostics Script

Run this in MATLAB Command Window to auto-diagnose issues:

```matlab
% EE354_Diagnostics.m
clear all; clc

disp('========== EE354 SYSTEM DIAGNOSTICS ==========')
disp('')

% 1. Check MATLAB version
V = ver;
ml_version = V(1).Release;
disp(['✓ MATLAB Version: ' ml_version])

% 2. Check Simscape Electrical
try
    simulink
    SE = ver('simscape_electrical');
    disp(['✓ Simscape Electrical: ' SE.Version])
catch
    disp(['✗ Simscape Electrical NOT INSTALLED or not licensed'])
    return
end

% 3. Check file existence
disp('')
disp('File Status:')
files_to_check = {
    'scripts/EE354_Setup.m'
    'scripts/EE354_AutoPlot.m'
    'scripts/EE354_Analysis.m'
    'scripts/EE354_SanityCheck.m'
    'models/EE354_Exercise1.slx'
    'models/EE354_Exercise2.slx'
    'docs/THEORY.md'
};

for i = 1:length(files_to_check)
    f = files_to_check{i};
    if isfile(f) || isfolder(f)
        disp(['  ✓ ' f])
    else
        disp(['  ✗ ' f ' NOT FOUND'])
    end
end

% 4. Try to run setup
disp('')
disp('Running EE354_Setup...')
try
    EE354_Setup
    disp('✓ Setup successful')
catch ME
    disp(['✗ Setup failed: ' ME.message])
end

disp('')
disp('========== DIAGNOSTICS COMPLETE ==========')
```

---

## Still Stuck?

1. **Check GitHub Issues:** https://github.com/university/EE354-Synchronous-Generator-Simulations/issues
2. **Review THEORY.md:** [docs/THEORY.md](docs/THEORY.md) — confirms physical expectations
3. **Consult course instructor:** Provide:
   - MATLAB version (`version`)
   - Error message (full text)
   - Which exercise you're running
   - Result of running `EE354_Diagnostics` (above script)
