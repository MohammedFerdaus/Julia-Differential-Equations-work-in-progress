# Add needed packages
using GLMakie
using OrdinaryDiffEq

# Lotka-Volterra equations (predator-prey model)
# dx/dt = alpha*x - beta*x*y
# dy/dt = delta*x*y - gamma*y
#
# x: prey population
# y: predator population
# dx/dt and dy/dt represent the instantaneous growth rates of the two populations

function lotka_volterra(du, u, p, t)
    x, y = u
    alpha, beta, delta, gamma = p
    du[1] = alpha * x - beta * x * y
    du[2] = delta * x * y - gamma * y
end

# alpha: prey natural growth rate (birth rate with no predators)
# beta: predation rate (rate at which predators kill prey)
# delta: predator growth rate from consuming prey
# gamma: predator natural death rate (with no prey)
alpha = 0.1
beta = 0.02
delta = 0.01
gamma = 0.1
p = [alpha, beta, delta, gamma]

# x: initial prey population
# y: initial predator population
u_begin = [40.0, 9.0]

t_begin = 0
t_end = 200
t_span = (t_begin, t_end)

# Define and solve ODE problem
prob = ODEProblem(lotka_volterra, u_begin, t_span, p)
sol = solve(prob)

# Interactive plot
fig = Figure(size = (1100, 700))

Label(fig[0, 1:2], "Lotka-Volterra Equations  —  Predator-Prey Model",
    fontsize = 20, font = :bold, tellwidth = false)

# Left axis: populations over time
ax1 = Axis(fig[1, 1],
    xlabel = "Time",
    ylabel = "Population",
    xgridvisible = true,
    ygridvisible = true)

# Right axis: phase portrait (predator vs prey)
ax2 = Axis(fig[1, 2],
    xlabel = "Prey population",
    ylabel = "Predator population",
    title = "Phase portrait",
    xgridvisible = true,
    ygridvisible = true)

colsize!(fig.layout, 1, Relative(0.5))

# Slider panel below both plots
slider_grid = GridLayout(fig[2, 1:2])

Label(slider_grid[1, 1], "Alpha — prey growth rate", halign = :left)
sl_alpha = Slider(slider_grid[2, 1], range = 0.01:0.01:1.0, startvalue = 0.1)

Label(slider_grid[1, 2], "Beta — predation rate", halign = :left)
sl_beta = Slider(slider_grid[2, 2], range = 0.001:0.001:0.1, startvalue = 0.02)

Label(slider_grid[3, 1], "Delta — predator growth rate", halign = :left)
sl_delta = Slider(slider_grid[4, 1], range = 0.001:0.001:0.1, startvalue = 0.01)

Label(slider_grid[3, 2], "Gamma — predator death rate", halign = :left)
sl_gamma = Slider(slider_grid[4, 2], range = 0.01:0.01:1.0, startvalue = 0.1)

Label(slider_grid[1, 3], "Initial prey x₀", halign = :left)
sl_x0 = Slider(slider_grid[2, 3], range = 1:1:100, startvalue = 40)

Label(slider_grid[3, 3], "Initial predators y₀", halign = :left)
sl_y0 = Slider(slider_grid[4, 3], range = 1:1:50, startvalue = 9)

# Live readout labels
Label(slider_grid[2, 4], @lift(string($(sl_alpha.value))))
Label(slider_grid[2, 4], @lift(string($(sl_beta.value))))
Label(slider_grid[4, 4], @lift(string($(sl_delta.value))))
Label(slider_grid[4, 4], @lift(string($(sl_gamma.value))))

# Reactive ODE solve
sol_data = @lift begin
    p_i = [
        Float64($(sl_alpha.value)),
        Float64($(sl_beta.value)),
        Float64($(sl_delta.value)),
        Float64($(sl_gamma.value))
    ]
    u0_i = [Float64($(sl_x0.value)), Float64($(sl_y0.value))]
    prob_i = ODEProblem(lotka_volterra, u0_i, (0.0, 200.0), p_i)
    sol_i = solve(prob_i, saveat = 200.0 / 500)
    ts = sol_i.t
    xs = [sol_i[i][1] for i in 1:length(sol_i)]
    ys = [sol_i[i][2] for i in 1:length(sol_i)]
    (ts, xs, ys)
end

t_pts = @lift $(sol_data)[1]
x_pts = @lift $(sol_data)[2]
y_pts = @lift $(sol_data)[3]

# Population over time
l_prey = lines!(ax1, t_pts, x_pts, linewidth = 2.5, color = :dodgerblue)
l_pred = lines!(ax1, t_pts, y_pts, linewidth = 2.5, color = :tomato)

Legend(fig[1, 3], [l_prey, l_pred], ["Prey", "Predators"])

# Phase portrait
lines!(ax2, x_pts, y_pts, linewidth = 2, color = :mediumpurple)
scatter!(ax2,
    @lift([$(x_pts)[1]]),
    @lift([$(y_pts)[1]]),
    markersize = 10, color = :black)

on(sol_data) do (ts, xs, ys)
    ylims!(ax1, 0, max(maximum(xs), maximum(ys)) * 1.15)
    xlims!(ax1, 0, 200)
    xlims!(ax2, 0, max(maximum(xs), 1.0) * 1.1)
    ylims!(ax2, 0, max(maximum(ys), 1.0) * 1.1)
end

notify(sl_alpha.value)

# Keep window open until closed
display(fig)
wait(fig.scene)
