# Theory Background: Synchronous Generator Dynamics & Control

This document provides the mathematical foundations underlying the EE354 simulations. All equations reflect IEEE standard conventions for power systems.

## Table of Contents
1. [The Swing Equation](#the-swing-equation)
2. [Power-Angle Relationships](#power-angle-relationships)
3. [Governor Droop Control](#governor-droop-control)
4. [Parallel Operation and Load Sharing](#parallel-operation-and-load-sharing)
5. [Synchronizing Power](#synchronizing-power)
6. [Infinite Bus Definition](#infinite-bus-definition)
7. [Numerical Examples](#numerical-examples)

---

## The Swing Equation

The synchronous generator rotor's motion is governed by Newton's second law applied to the rotating mass:

$$
J \frac{d^2\delta}{dt^2} = T_m - T_e - D\frac{d\delta}{dt}
$$

where:
- **J** = moment of inertia of rotor (kg·m²)
- **δ** = absolute rotor angle (radians)
- **T_m** = mechanical torque input from prime mover (N·m)
- **T_e** = electromagnetic torque (load on rotor) (N·m)
- **D** = damping coefficient (N·m·s/rad)

### Derivation

Starting from rotational mechanics:

1. **Kinetic energy stored:** $KE = \frac{1}{2}J\omega^2$ where $\omega = \frac{d\delta}{dt}$

2. **Apply Newton's 2nd law in angular form:** $\sum \tau = J\alpha = J\frac{d^2\delta}{dt^2}$

3. **Torque balance:** Mechanical torque $T_m$ accelerates the rotor; electrical torque $T_e$ resists (acts as load); damping $D$ opposes velocity.

4. **Result:** $J\frac{d^2\delta}{dt^2} = T_m - T_e - D\frac{d\delta}{dt}$

### Non-Dimensionalization

To work with per-unit quantities used in power systems, define the **inertia constant**:

$$
H = \frac{\text{Kinetic Energy Stored}}{\text{Apparent Power Rating}} = \frac{J\omega_0^2}{2S_{base}}
$$

where $\omega_0 = 2\pi f_0$ (377 rad/s for 60 Hz base) and $S_{base}$ is MVA rating.

Substituting $J = \frac{2HS_{base}}{\omega_0^2}$ and converting torque to per-unit power ($P = T \cdot \omega_0 / S_{base}$):

$$
\frac{2H}{\omega_0}\frac{d^2\delta}{dt^2} = P_m - P_e - D\omega_0(f - f_0)
$$

### Frequency-Based Form

Since rotor angle $\delta = \omega_0 t + \Delta\delta(t)$ and frequency $f = f_0 + \Delta f$:

$$
\frac{2H}{f_0} \frac{df}{dt} = P_m - P_e - D(f - f_0)
$$

**For this course parameters:**
- $S_{base} = 555$ MVA
- $H = 3.525$ s (typical for large synchronous generators)
- $f_0 = 60$ Hz, $\omega_0 = 377$ rad/s

This becomes:

$$
\boxed{0.118 \frac{df}{dt} = P_m - P_e - D(f - f_0)}
$$

or after solving for the acceleration term:

$$
\frac{df}{dt} = 8.47(P_m - P_e) - D(f - f_0)
$$

**Physical interpretation:** Each MW of power imbalance ($P_m \neq P_e$) drives frequency change at ~8.47 Hz per MW imbalance. Larger H means slower frequency response (more inertia resists change).

---

## Power-Angle Relationships

### Active Power Output

Consider a synchronous generator with terminal voltage $\vec{V}_g = V_g\angle\delta$ connected to the grid at $\vec{V}_s = V_s\angle 0°$ through synchronous reactance $X_s$.

The voltage difference drives current through the reactance:

$$
\vec{I} = \frac{V_g\angle\delta - V_s\angle 0°}{jX_s} = \frac{V_g\angle\delta - V_s}{jX_s}
$$

Active power output from the generator:

$$
P_e = V_g I_d = V_g \cdot \frac{V_g V_s \sin\delta}{X_s} = \boxed{\frac{V_g V_s}{X_s}\sin\delta}
$$

where $\delta$ is the power angle (phase difference between generator and system voltage).

**Key properties:**
- Maximum power transfer: $P_{max} = \frac{V_g V_s}{X_s}$ at $\delta = 90°$
- Beyond $\delta = 90°$: Power decreases (rotor slips) → **loss of synchronism**
- Stable equilibrium: $\delta = 0°$ (generator pulls forward with grid)

### Reactive Power Output

Similarly, the reactive power output:

$$
Q_e = V_g I_q = \boxed{\frac{V_g^2}{X_s} - \frac{V_g V_s}{X_s}\cos\delta}
$$

This shows reactive power depends strongly on terminal voltage $V_g$. The AVR controls $V_g$ to regulate $Q_e$ and maintain voltage near 1.0 pu.

### Application to EE354 Parameters

Rating: 555 MVA, $X_s = 0.35$ pu, $V_{base} = 13.8$ kV

At nominal voltage ($V_g = 1.0$ pu, $V_s = 1.0$ pu):
- $P_{max} = \frac{1 \times 1}{0.35} = 2.86$ pu = **1587 MW** (far above rated 555 MW)
- Safe operation: $|\delta| < 60°$ keeps power $< 1$.

When loaded at 250 MW (rated 555 MVA ≈ 0.45 pu):
- $\sin\delta = 0.45 \Rightarrow \delta \approx 26.7°$ (healthy margin to instability)

---

## Governor Droop Control

### Basic Droop Equation

A speed-droop governor adjusts mechanical power setpoint in response to frequency deviation:

$$
P_m = P_{nl} - \frac{P_{nl}}{R} \cdot \frac{\Delta f}{f_0}
$$

Rearranged:

$$
\Delta f = -R \cdot \frac{\Delta P_m}{P_{nl}} \cdot f_0
$$

where:
- **$P_{nl}$** = no-load power (setpoint when $f = f_0$)
- **$R$** = droop ratio (0.04–0.06 for traditional generators, ∞ for off)
- **$\Delta f$** = frequency error from nominal (60 Hz)
- **$\Delta P_m$** = change in mechanical power

### Physical Interpretation

**Example:** $P_{nl} = 250$ MW, $R = 0.05$ (5% droop), $f_0 = 60$ Hz

If system frequency drops by 0.3 Hz (to 59.7 Hz):
$$
\Delta P_m = -P_{nl} \cdot \frac{\Delta f}{R \cdot f_0} = -250 \times \frac{-0.3}{0.05 \times 60} = 25 \text{ MW}
$$

The governor increases power output by 25 MW to restore frequency. This is **load-frequency control**: sacrificing 0.3 Hz frequency to actively stabilize the system.

**Without governor ($R = \infty$):** No frequency correction; power remains at $P_{nl}$, and frequency drift continues until another source intervenes.

### Droop Time Constant

Real governors have time delays due to hydraulic or electrical response. Model as first-order lag:

$$
P_m(s) = P_{ref}(s) - \frac{P_{ref}}{R} \cdot \frac{\Delta f(s)}{f_0} \cdot \frac{1}{1 + sT_g}
$$

where $T_g \approx 0.2$–0.5 s (typical governor time constant). In EE354 simulations, we simplify to $T_g \approx 0$ for pedagogical clarity.

---

## Parallel Operation and Load Sharing

### Two Generators in Parallel

When two synchronous generators supply a common load $P_L$ at frequency $f$, each operates according to its droop equation:

$$
P_1 = P_{nl,1} - \frac{P_{nl,1}}{R_1}\frac{f - f_0}{f_0}, \quad P_2 = P_{nl,2} - \frac{P_{nl,2}}{R_2}\frac{f - f_0}{f_0}
$$

At steady state, power balance gives:

$$
P_1 + P_2 = P_L
$$

Substituting and solving for steady-state frequency:

$$
\Delta f_{ss} = f_{ss} - f_0 = -\frac{P_L - (P_{nl,1} + P_{nl,2})}{\frac{P_{nl,1}}{R_1} + \frac{P_{nl,2}}{R_2}}
$$

### Load Sharing with Unequal Droops

The distribution of load change is **inversely proportional to droop ratio**:

$$
\frac{\Delta P_1}{\Delta P_2} = \frac{P_{nl,1}/R_1}{P_{nl,2}/R_2}
$$

**Example from EE354 Exercise 3:**
- Gen A: $P_{nl} = 250$ MW, $R = 5\%$
- Gen B: $P_{nl} = 150$ MW, $R = \infty$ (governor off)

When 100 MW load steps on Gen A:
- Gen B has no droop feedback → cannot alter power automatically
- Gen B's frequency is forced down by Gen A's inertia response
- Gen B transitions from generating to motoring, pulling load instead of supplying it
- Result: Gen B outputs **negative power** (~100–150 MW motoring)

**Fix:** Add governor to Gen B (Exercise 4 setup with Gen A load removed beforehand).

---

## Synchronizing Power

### Definition

When two generators operate at slightly different power angles $\delta_1$ and $\delta_2$, they experience a restoring torque proportional to angle difference:

$$
P_{sync} = \frac{V_1 V_2}{X_s} \cos(\delta_1 - \delta_2) \approx \frac{V_1 V_2}{X_s} \quad \text{(small angle)}
$$

This is the **synchronizing power coefficient**—analogous to spring stiffness. It resists angle divergence.

### Electromechanical Oscillations

Two computers coupled by synchronizing power exhibit oscillations at frequency:

$$
f_{osc} = \frac{1}{2\pi}\sqrt{\frac{P_{sync} \cdot \omega_0}{H_{eq}}}
$$

where $H_{eq} = \frac{H_1 H_2}{H_1 + H_2}$ is the combined inertia constant.

**For EE354 parameters** ($H = 3.525$ s, $P_{sync} = 1.5$ pu):

$$
f_{osc} = \frac{1}{2\pi}\sqrt{\frac{1.5 \times 377}{2 \times 3.525}} \approx \boxed{1.2 \text{ Hz}}
$$

This matches observation in Exercise 3/4 plots: ~1.2 Hz oscillation in power and frequency during the first 10 seconds after disturbance.

### Damping by Load

Frequency-dependent load (e.g., induction motors, controllers) adds damping:

$$
P_L = P_0 + D \cdot \Delta f
$$

This damping reduces oscillation amplitude by ~15–30% in typical grids, explaining why Exercise 5 (infinite bus, no frequency-dependent load) has slightly larger oscillations than Exercise 3 (two generators).

---

## Infinite Bus Definition

An **ideal infinite bus** is a voltage and frequency source that maintains:

$$
V_{bus}(t) = 1.0 \angle 0° \text{ (pu, constant)} \quad \forall \text{ any injection } P, Q
$$

**Characteristics:**
- Voltage magnitude: always 1.0 pu (no sag for transients)
- Frequency: always 60.00 Hz (zero Hz deviation, infinite system inertia)
- Power capacity: unlimited (can absorb or supply any amount)

**Physically represents:** A large interconnected grid with many generators, loads, and transmission lines. No single generator has enough power to move the system voltage or frequency.

### Comparison: Generator vs. Infinite Bus

| Property | Two Generators | Generator + Infinite Bus |
|----------|-----------------|------------------------|
| Frequency | Determined by both droops | Locked to bus (60 Hz) |
| Voltage | Determined by both AVRs | Locked to bus (1.0 pu) |
| Droop effectiveness | Both affect system f | Droop only changes own power, not system f |
| Synchronizing oscillations | 1.2–1.5 Hz | Only rotor swing within own machine (~2–3 Hz) |
| Stability | Sensitive to droop ratio mismatch | Determined solely by own governor/AVR |

**In the simulations:**
- **Exercise 3–4:** Two generators, frequency and voltage determined mutually
- **Exercise 5–6:** Gen A replaced by infinite bus, system frequency always 60 Hz regardless of Gen B droop

---

## Numerical Examples

### Example 1: Swing Equation with EE354 Parameters

**Given:**
- Generator rated 555 MVA, $H = 3.525$ s
- Initial power: $P_m = 250$ MW
- Load step: $\Delta P_L = 100$ MW at $t = 0$
- Damping: $D = 0.01$ (typical)

**Find:** Initial frequency acceleration

**Solution:**
$$
\frac{df}{dt}\bigg|_{t=0^+} = \frac{f_0}{2H}(P_m - P_e - D(f - f_0))
$$

Before disturbance: $P_m = P_e = 250$ MW, $f = 60$ Hz

$$
\frac{df}{dt}\bigg|_{t=0^+} = \frac{60}{2 \times 3.525} \times (-100) = -8.47 \times 100 = -847 \text{ Hz/s}
$$

Wait, this is too large. Re-examining units: Power is in **per-unit** (pu), not MW.

**Corrected:**
- 250 MW / 555 MVA = 0.45 pu
- 100 MW / 555 MVA = 0.18 pu

$$
\frac{df}{dt}\bigg|_{t=0^+} = \frac{60}{2 \times 3.525} \times (-0.18) = 8.47 \times (-0.18) = -1.52 \text{ Hz/s}
$$

**Interpretation:** When 18% load suddenly appears, frequency initially drops at 1.52 Hz/s. Within ~0.1 seconds, frequency deviation reaches ~0.15 Hz.

### Example 2: Droop Governor Frequency Recovery

**Given:**
- Generator: $P_{nl} = 250$ MW, $R = 0.05$, $H = 3.525$ s
- Step load: 100 MW
- Initial frequency dip: $\Delta f = -0.15$ Hz (from Example 1)

**Find:** Mechanical power increase commanded by governor

**Solution:**
$$
\Delta P_m = -\frac{P_{nl}}{R} \times \frac{\Delta f}{f_0} = -\frac{250}{0.05} \times \frac{-0.15}{60} = 5000 \times 0.0025 = 12.5 \text{ MW}
$$

Over the next few seconds, the governor increases power output by 12.5 MW. If load is 100 MW, remaining imbalance is 87.5 MW, which continues to decelerate the generator until governor response catches up. Steady state: frequency stabilizes when:

$$
\Delta f_{ss} = -0.06 \text{ Hz} \quad (100 \text{ MW} / 5000 \text{ MW/Hz})
$$

Verification: $\Delta P_m = -\frac{250}{0.05} \times \frac{-0.06}{60} = 5 \text{ MW}$, revealing 95 MW unmet (~95% of original load, with 5% sacrificed to frequency decline). This is realistic for grid support.

### Example 3: Parallel Operation Load Sharing

**Given:**
- Gen A: $P_{nl,A} = 250$ MW, $R_A = 0.05$ (with governor)
- Gen B: $P_{nl,B} = 150$ MW, $R_B = \infty$ (governor off)
- Load suddenly decreases: $\Delta P_L = -100$ MW

**Find:** Steady-state frequency and power distribution

**Solution:**

Without Gen B governor, frequency is determined solely by Gen A's droop:

$$
\Delta f = -R_A \times \frac{\Delta P_A - \Delta P_L}{P_{nl,A} \times f_0}
$$

Gen B responds only to frequency (via inertia swinging), not independently adjusting power. After oscillations damp, Gen B's power settles where power angle allows:

In absence of detailed model, approximate: Gen A's droop governs overall frequency; Gen B passively follows. Steady-state frequency:

$$
\Delta f_{ss} \approx -0.05 \times \frac{0 - (-100)}{250 \times 60} \times 60 = -0.05 \times \frac{-100}{15000} \times 60 = +0.02 \text{ Hz}
$$

This matches Exercise 4 observation: frequency rises slightly (underspeed removed), and Gen B exports power because its frequency is above nominal and inertia of both machines has accelerated the pair.

---

## Summary

The swing equation governs rotor dynamics; power-angle equations limit maximum power transfer; governor droop enables frequency regulation. In parallel operation, stiffer governors (smaller R) assume more load changes. Infinite bus models demonstrate that large grids decouple individual machine frequency from system frequency, requiring careful damping design.

For detailed derivations and proofs, see:
- Kundur et al., *Power System Stability and Control* (IEEE, 1994)
- Sauer & Pai, *Power System Dynamics and Stability* (Prentice Hall, 1998)

