# Add needed packages
using GLMakie
using OrdinaryDiffEq

# Verhulst equation (logistic growth)
# N: population at time t
# r: growth rate
# K: carrying capacity (max population the environment can support)
function Verhulst(u, p, t)
    N = u
    r, K = p
    r * N * (1 - (N / K))
end

# Assign variables
r = 0.4
K = 1000.0
n_begin = 10.0
t_begin = 0
t_end = 50
t_span = (t_begin, t_end)
p = [r, K]

# Define and solve ODE problem
prob = ODEProblem(Verhulst, n_begin, t_span, p)
sol = solve(prob)

# Interactive plot
fig = Figure(size = (900, 580))

Label(fig[0, 1:2], "Verhulst Equation  —  dN/dt = r · N · (1 - N/K)",
    fontsize = 20, font = :bold, tellwidth = false)

ax = Axis(fig[1, 1],
    xlabel = "Time (months)",
    ylabel = "Population",
    xgridvisible = true,
    ygridvisible = true)

# Slider panel
slider_grid = GridLayout(fig[1, 2])

Label(slider_grid[1, 1], "Growth rate (r)", halign = :left)
sl_r = Slider(slider_grid[2, 1], range = 0.01:0.01:2.0, startvalue = 0.4)

Label(slider_grid[3, 1], "Carrying capacity (K)", halign = :left)
sl_K = Slider(slider_grid[4, 1], range = 100:100:25000, startvalue = 1000)

Label(slider_grid[5, 1], "Initial population (N₀)", halign = :left)
sl_n0 = Slider(slider_grid[6, 1], range = 1:10:500, startvalue = 10)

# Live readout labels
Label(slider_grid[2, 2], @lift(string($(sl_r.value))))
Label(slider_grid[4, 2], @lift(string($(sl_K.value))))
Label(slider_grid[6, 2], @lift(string($(sl_n0.value))))

# Reactive ODE solve
sol_data = @lift begin
    r_i = Float64($(sl_r.value))
    K_i = Float64($(sl_K.value))
    n0_i = Float64($(sl_n0.value))
    p_i = [r_i, K_i]
    prob_i = ODEProblem(Verhulst, n0_i, (0.0, 50.0), p_i)
    sol_i = solve(prob_i, saveat = 50.0 / 300)
    (sol_i.t, sol_i.u, sol_i.u[end], K_i)
end

t_pts = @lift $(sol_data)[1]
n_pts = @lift $(sol_data)[2]
final_n = @lift $(sol_data)[3]
k_line = @lift $(sol_data)[4]

lines!(ax, t_pts, n_pts, linewidth = 3, color = :seagreen)

# Carrying capacity reference line
hlines!(ax, k_line, linestyle = :dash, color = :red, linewidth = 1.5)

text!(ax, @lift($(t_pts)[end]), @lift($(n_pts)[end]),
    text = @lift(string("N = ", round($(final_n), digits = 1))),
    fontsize = 13,
    color = :seagreen,
    align = (:right, :bottom),
    offset = (-6, 4))

# K label on the right
text!(ax, 50.0, k_line,
    text = @lift(string("K = ", Int($(sl_K.value)))),
    fontsize = 13,
    color = :red,
    align = (:right, :top),
    offset = (-4, -4))

on(sol_data) do (ts, ns, _, K_i)
    ylims!(ax, 0, K_i * 1.2)
    xlims!(ax, 0, 52.0)
end

notify(sl_r.value)

# Keep window open until closed
display(fig)
wait(fig.scene)
