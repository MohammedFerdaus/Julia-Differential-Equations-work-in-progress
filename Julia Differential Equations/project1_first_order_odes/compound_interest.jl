# Add needed packages
using GLMakie
using OrdinaryDiffEq

# Continuous compound interest ODE: dB/dt = r * B
f(u, p, t) = p * u

# Assign variables
# u: bank account balance
u_begin = 1
# p: annual interest rate
p_percent = 1
p = p_percent / 100
# t: time in years
t_begin = 0
t_end = 1
t_span = (t_begin, t_end)

# Define and solve ODE problem
prob = ODEProblem(f, u_begin, t_span, p)
sol = solve(prob)

# Interactive plot
fig = Figure(size = (900, 580))

Label(fig[0, 1:2], "Continuous Compound Interest  —  dB/dt = r · B",
    fontsize = 20, font = :bold, tellwidth = false)

ax = Axis(fig[1, 1],
    xlabel = "Time (years)",
    ylabel = "Account balance (\$)",
    xgridvisible = true,
    ygridvisible = true)

# Slider panel
slider_grid = GridLayout(fig[1, 2])

Label(slider_grid[1, 1], "Interest rate (%)", halign = :left)
sl_rate = Slider(slider_grid[2, 1], range = 0:1:100, startvalue = 5)

Label(slider_grid[3, 1], "Beginning balance (\$)", halign = :left)
sl_balance = Slider(slider_grid[4, 1], range = 0:10:1000, startvalue = 100)

Label(slider_grid[5, 1], "Years", halign = :left)
sl_years = Slider(slider_grid[6, 1], range = 0:1:100, startvalue = 10)

# Live readout labels
Label(slider_grid[2, 2], @lift(string($(sl_rate.value), " %")))
Label(slider_grid[4, 2], @lift(string("\$", $(sl_balance.value))))
Label(slider_grid[6, 2], @lift(string($(sl_years.value), " yr")))

# Reactive ODE solve
sol_data = @lift begin
    r = $(sl_rate.value) / 100.0
    u0 = Float64($(sl_balance.value))
    T = Float64($(sl_years.value))
    if T == 0.0 || u0 == 0.0
        return ([0.0, 1.0], [u0, u0], u0)
    end
    prob_i = ODEProblem(f, u0, (0.0, T), r)
    sol_i = solve(prob_i, saveat = T / 300)
    (sol_i.t, sol_i.u, sol_i.u[end])
end

t_pts = @lift $(sol_data)[1]
b_pts = @lift $(sol_data)[2]
final_bal = @lift $(sol_data)[3]

lines!(ax, t_pts, b_pts, linewidth = 3, color = :dodgerblue)

text!(ax, @lift($(t_pts)[end]), @lift($(b_pts)[end]),
    text = @lift(string("Final: \$", round($(final_bal), digits = 2))),
    fontsize = 13,
    color = :dodgerblue,
    align = (:left, :bottom),
    offset = (6, 4))

on(sol_data) do (ts, bs, _)
    ylims!(ax, 0, max(bs[end], 1.0) * 1.12)
    xlims!(ax, 0, max(ts[end], 1.0) * 1.05)
end

notify(sl_rate.value)

# Keep window open until closed
display(fig)
wait(fig.scene)