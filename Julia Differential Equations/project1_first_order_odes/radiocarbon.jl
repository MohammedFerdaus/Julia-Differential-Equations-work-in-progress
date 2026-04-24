# Add needed packages
using GLMakie
using OrdinaryDiffEq

# Radiocarbon ODE: dC/dt = -c * C
f(u, p, t) = p * u

# Assign variables
# u: C-14 percent remaining
u_begin = 100
# p: decay constant derived from half-life
const halflife = 5730
c = log(2) / halflife
p = -c
# t: time in years
t_begin = 0
t_end = 50000
t_span = (t_begin, t_end)

# Define and solve ODE problem
prob = ODEProblem(f, u_begin, t_span, p)
sol = solve(prob)

# Interactive plot
fig = Figure(size = (900, 580))

Label(fig[0, 1:2], "Radiocarbon Dating  —  dC/dt = -λ · C",
    fontsize = 20, font = :bold, tellwidth = false)

ax = Axis(fig[1, 1],
    xlabel = "Time (years)",
    ylabel = "C-14 remaining (%)",
    xgridvisible = true,
    ygridvisible = true)

# Slider panel
slider_grid = GridLayout(fig[1, 2])

Label(slider_grid[1, 1], "Initial C-14 (%)", halign = :left)
sl_u0 = Slider(slider_grid[2, 1], range = 0:1:100, startvalue = 100)

Label(slider_grid[3, 1], "Half-life (years)", halign = :left)
sl_halflife = Slider(slider_grid[4, 1], range = 1000:100:50000, startvalue = 5730)

Label(slider_grid[5, 1], "Time span (years)", halign = :left)
sl_tspan = Slider(slider_grid[6, 1], range = 1000:1000:100000, startvalue = 50000)

# Live readout labels
Label(slider_grid[2, 2], @lift(string($(sl_u0.value), " %")))
Label(slider_grid[4, 2], @lift(string($(sl_halflife.value), " yr")))
Label(slider_grid[6, 2], @lift(string($(sl_tspan.value), " yr")))

# Reactive ODE solve
sol_data = @lift begin
    u0 = Float64($(sl_u0.value))
    hl = Float64($(sl_halflife.value))
    T = Float64($(sl_tspan.value))
    decay = -log(2) / hl
    prob_i = ODEProblem(f, u0, (0.0, T), decay)
    sol_i = solve(prob_i, saveat = T / 300)
    (sol_i.t, sol_i.u, sol_i.u[end])
end

t_pts = @lift $(sol_data)[1]
c_pts = @lift $(sol_data)[2]
final_c = @lift $(sol_data)[3]

lines!(ax, t_pts, c_pts, linewidth = 3, color = :orange)

text!(ax, @lift($(t_pts)[end]), @lift($(c_pts)[end]),
    text = @lift(string("Remaining: ", round($(final_c), digits = 2), " %")),
    fontsize = 13,
    color = :orange,
    align = (:right, :bottom),
    offset = (-6, 4))

on(sol_data) do (ts, cs, _)
    ylims!(ax, 0, max(cs[1], 1.0) * 1.12)
    xlims!(ax, 0, max(ts[end], 1.0) * 1.05)
end

notify(sl_u0.value)

# Keep window open until closed
display(fig)
wait(fig.scene)
