# Add needed packages
using GLMakie
using OrdinaryDiffEq

# Simple harmonic motion: x'' = -(k/m) * x
# m: inertial mass (kg)
# x: displacement (m)
# k: spring constant (N/m)
function harmonic(ddu, du, u, p, t)
    k, m = p
    ddu[1] = -(k / m) * u[1]
end

# Assign variables
# du: initial velocity (m/s)
dx_begin = [0.0]
# u: initial displacement (m)
x_begin = [1.0]
# k: spring constant (N/m)
k = 9.0
# m: mass (kg)
m = 10.0
p = [k, m]
# t: time in seconds
t_begin = 0.0
t_end = 20.0
t_span = (t_begin, t_end)

# Define and solve second order ODE problem
prob = SecondOrderODEProblem(harmonic, dx_begin, x_begin, t_span, p)
sol = solve(prob)

# Interactive plot
fig = Figure(size = (900, 580))

Label(fig[0, 1:2], "Simple Harmonic Motion  —  x'' = -(k/m) · x",
    fontsize = 20, font = :bold, tellwidth = false)

ax = Axis(fig[1, 1],
    xlabel = "Time (s)",
    ylabel = "Displacement (m)",
    xgridvisible = true,
    ygridvisible = true)

hlines!(ax, [0.0], linestyle = :dash, color = :gray60, linewidth = 1)

# Slider panel
slider_grid = GridLayout(fig[1, 2])

Label(slider_grid[1, 1], "Spring constant k (N/m)", halign = :left)
sl_k = Slider(slider_grid[2, 1], range = 0.1:0.1:50.0, startvalue = 9.0)

Label(slider_grid[3, 1], "Mass m (kg)", halign = :left)
sl_m = Slider(slider_grid[4, 1], range = 0.1:0.1:20.0, startvalue = 10.0)

Label(slider_grid[5, 1], "Initial displacement x₀ (m)", halign = :left)
sl_x0 = Slider(slider_grid[6, 1], range = -5.0:0.1:5.0, startvalue = 1.0)

# Live readout labels
Label(slider_grid[2, 2], @lift(string($(sl_k.value), " N/m")))
Label(slider_grid[4, 2], @lift(string($(sl_m.value), " kg")))
Label(slider_grid[6, 2], @lift(string($(sl_x0.value), " m")))

# Reactive ODE solve
sol_data = @lift begin
    k_i = Float64($(sl_k.value))
    m_i = Float64($(sl_m.value))
    x0_i = Float64($(sl_x0.value))
    p_i = [k_i, m_i]
    prob_i = SecondOrderODEProblem(harmonic, [0.0], [x0_i], (0.0, 20.0), p_i)
    sol_i = solve(prob_i, saveat = 20.0 / 300)
    ts = sol_i.t
    xs = [sol_i[i][2] for i in 1:length(sol_i)]
    ω = sqrt(k_i / m_i)
    period = 2π / ω
    (ts, xs, period, ω)
end

t_pts = @lift $(sol_data)[1]
x_pts = @lift $(sol_data)[2]
period = @lift $(sol_data)[3]
omega = @lift $(sol_data)[4]

lines!(ax, t_pts, x_pts, linewidth = 3, color = :mediumpurple)

text!(ax, 1.0, @lift($(x_pts)[1]),
    text = @lift(string(
        "ω = ", round($(omega), digits = 3), " rad/s\n",
        "T = ", round($(period), digits = 3), " s")),
    fontsize = 13,
    color = :mediumpurple,
    align = (:left, :top),
    offset = (4, -4))

on(sol_data) do (ts, xs, T, ω)
    amp = max(maximum(abs.(xs)), 0.1)
    ylims!(ax, -amp * 1.3, amp * 1.3)
    xlims!(ax, 0, 20.5)
end

notify(sl_k.value)

# Keep window open until closed
display(fig)
wait(fig.scene)
