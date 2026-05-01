# Julia Differential Equations

A collection of differential equations projects built in Julia using DifferentialEquations.jl, covering first and second order ODEs, nonlinear systems, chaos theory, and stochastic and partial differential equations. Each file is a standalone simulation with an interactive GLMakie plot driven by real-time sliders.

---

## Repository Structure

```
Julia-Differential-Equations/
├── project1_first_order_odes/
│   ├── compound_interest.jl     — continuous compound interest ODE
│   ├── radiocarbon.jl           — radiocarbon decay ODE
│   └── verhulst.jl              — logistic population growth (Verhulst equation)
├── project2_second_order_odes/
│   ├── harmonic_motion.jl       — simple harmonic oscillator
│   ├── projectile_motion.jl     — 2D projectile under gravity with planet selection
│   └── brachistochrone.jl       — curve of fastest descent via cycloid solution
├── project3_first_order_nonlinear/
    └── lotka_volterra.jl        — predator-prey population dynamics
```

---

## Mathematics

### Project 1 — First Order ODEs

#### Continuous compound interest

The balance $B$ grows at a rate proportional to itself:

$$\frac{dB}{dt} = rB$$

where $r$ is the annual interest rate. The analytic solution is $B(t) = B_0 e^{rt}$, which DifferentialEquations.jl recovers numerically.

---

#### Radiocarbon dating

Carbon-14 decays at a rate proportional to the current amount remaining:

$$\frac{dC}{dt} = -\lambda C$$

where the decay constant $\lambda$ is derived from the half-life $t_{1/2}$:

$$\lambda = \frac{\ln 2}{t_{1/2}}$$

The analytic solution is $C(t) = C_0 e^{-\lambda t}$. The interactive plot lets you vary the half-life to explore how different isotopes decay at different rates.

---

#### Verhulst equation (logistic growth)

The Verhulst equation models population growth with a carrying capacity $K$ — the maximum population the environment can sustain:

$$\frac{dN}{dt} = rN\left(1 - \frac{N}{K}\right)$$

When $N \ll K$ the equation reduces to exponential growth. As $N \to K$ the growth rate approaches zero and the population plateaus at $K$. The interactive plot shows a dashed reference line at $K$ so you can watch the population asymptote toward it.

---

### Project 2 — Second Order ODEs

Second order ODEs of the form $x'' = f(x, x', t)$ are solved using `SecondOrderODEProblem`, which internally reduces them to a first order system by introducing velocity as an auxiliary variable.

#### Simple harmonic motion

A mass $m$ on a spring with constant $k$ obeys:

$$\frac{d^2x}{dt^2} = -\frac{k}{m}x$$

The natural angular frequency and period are:

$$\omega = \sqrt{\frac{k}{m}}, \qquad T = \frac{2\pi}{\omega}$$

Both $\omega$ and $T$ are displayed live on the plot and update as you adjust the sliders.

---

#### Projectile motion

With no air resistance, horizontal and vertical motion decouple into two second order ODEs:

$$\frac{d^2x}{dt^2} = 0, \qquad \frac{d^2y}{dt^2} = g$$

where $g$ is gravitational acceleration. Initial velocity components are set by launch angle $\theta$ and speed $v_0$:

$$v_x = v_0 \cos\theta, \qquad v_y = v_0 \sin\theta$$

Flight time is computed analytically from $y = v_y t + \frac{1}{2}g t^2 = 0$:

$$t_{flight} = \frac{-2v_y}{g}$$

The interactive plot includes a planet selector (Earth, Moon, Mars) so you can compare trajectories under different gravitational fields.

---

#### Brachistochrone

The brachistochrone asks: what curve minimises the travel time of a frictionless bead sliding between two points under gravity? Solved via calculus of variations, the answer is a **cycloid** parameterised by angle $\theta$:

$$x(\theta) = R(\theta - \sin\theta), \qquad y(\theta) = -R(1 - \cos\theta)$$

The radius $R$ is determined by solving the endpoint condition numerically via bisection:

$$\frac{x_{end}}{y_{end}} = \frac{\theta - \sin\theta}{1 - \cos\theta}$$

Travel time along any curve is computed by integrating $ds/v$ where speed comes from energy conservation:

$$v = \sqrt{2g(y_0 - y)}, \qquad T = \int \frac{ds}{v}$$

The plot compares travel times for the cycloid, a straight line, and a circular arc — the cycloid always wins regardless of endpoint.

---

### Project 3 — First Order Nonlinear ODEs

#### Lotka-Volterra equations

The Lotka-Volterra system models predator-prey population dynamics as a coupled nonlinear system:

$$\frac{dx}{dt} = \alpha x - \beta xy$$

$$\frac{dy}{dt} = \delta xy - \gamma y$$

where $x$ is prey population and $y$ is predator population. The four parameters govern the interaction:

| Parameter | Meaning |
|-----------|---------|
| $\alpha$ | Prey natural birth rate |
| $\beta$ | Rate at which predators kill prey |
| $\delta$ | Predator growth rate from consuming prey |
| $\gamma$ | Predator natural death rate |

The system has a non-trivial equilibrium at $(x^*, y^*) = (\gamma/\delta,\ \alpha/\beta)$. Around this point the populations oscillate in a closed orbit — visible in the phase portrait panel on the right side of the interactive plot.

---

## Stack

| Area | Library |
|------|---------|
| Visualization | GLMakie.jl |
| ODE solving | OrdinaryDiffEq.jl |
| SDE solving | StochasticDiffEq.jl (project 6) |
| Core | Julia 1.12.5 standard library |

---

## How to Run

**Requirements:** Julia 1.12.5, VS Code with Julia extension (recommended), or any terminal

Install dependencies:

```julia
using Pkg
Pkg.add("GLMakie")
Pkg.add("OrdinaryDiffEq")
```

Run any file from terminal:

```
julia project1_first_order_odes/compound_interest.jl
julia project2_second_order_odes/harmonic_motion.jl
julia project3_first_order_nonlinear/lotka_volterra.jl
```

Each file opens a GLMakie window with interactive sliders. Close the window to exit.

> **Note:** Run from a standalone terminal (PowerShell or Command Prompt), not the VS Code integrated terminal — GLMakie can crash the VS Code terminal on Windows due to a known GLFW issue.

---

## Notes

Built and tested on Julia 1.12.5, GLMakie, Windows 10. Each file is self-contained with no shared dependencies between projects. The focus of this repository is on deriving and understanding the mathematics of each ODE analytically before implementing the numerical solution — the interactive plots are intended to build intuition for how each parameter affects the behaviour of the system.
