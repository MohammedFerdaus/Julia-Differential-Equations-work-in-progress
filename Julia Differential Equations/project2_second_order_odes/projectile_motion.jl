# Add needed packages
using GLMakie
using OrdinaryDiffEq

# Projectile motion as a second order ODE
# x'' = 0 (no horizontal acceleration)
# y'' = g (gravitational acceleration)
function f(ddu, du, u, p, t)
    g = p
    ddu[1] = 0
    ddu[2] = g
end

# Gravitational constants in m/s^2
const EARTH_GRAVITY = -9.8
const MOON_GRAVITY = -1.625
const MARS_GRAVITY = -3.728

# Assign variables
# du: initial velocity components
theta = 45
v_begin = 50.0
vx_begin = cosd(theta) * v_begin
vy_begin = sind(theta) * v_begin
du_begin = [vx_begin, vy_begin]
# u: initial position
u_begin = [0.0, 0.0]
# t: time in seconds
t_begin = 0.0
t_end = 20.0
t_span = (t_begin, t_end)

# Define and solve second order ODE problem
prob = SecondOrderODEProblem(f, du_begin, u_begin, t_span, EARTH_GRAVITY)
sol = solve(prob)

# Interactive plot
fig = Figure(size = (900, 620))

Label(fig[0, 1:2], "Projectile Motion  —  x'' = 0,  y'' = g",
    fontsize = 20, font = :bold, tellwidth = false)

ax = Axis(fig[1, 1],
    xlabel = "Horizontal distance (m)",
    ylabel = "Vertical height (m)",
    xgridvisible = true,
    ygridvisible = true)

# Slider panel
slider_grid = GridLayout(fig[1, 2])

Label(slider_grid[1, 1], "Launch angle (°)", halign = :left)
sl_theta = Slider(slider_grid[2, 1], range = 0:1:90, startvalue = 45)

Label(slider_grid[3, 1], "Initial speed (m/s)", halign = :left)
sl_v = Slider(slider_grid[4, 1], range = 0:1:100, startvalue = 50)

Label(slider_grid[5, 1], "Planet", halign = :left)
planet_menu = Menu(slider_grid[6, 1], options = ["Earth", "Moon", "Mars"], default = "Earth")

# Live readout labels
Label(slider_grid[2, 2], @lift(string($(sl_theta.value), " °")))
Label(slider_grid[4, 2], @lift(string($(sl_v.value), " m/s")))

# Reactive ODE solve
sol_data = @lift begin
    θ = Float64($(sl_theta.value))
    v = Float64($(sl_v.value))
    planet = $(planet_menu.selection)
    g = planet == "Earth" ? EARTH_GRAVITY :
        planet == "Moon"  ? MOON_GRAVITY  : MARS_GRAVITY
    vx0 = cosd(θ) * v
    vy0 = sind(θ) * v
    du0 = [vx0, vy0]
    u0 = [0.0, 0.0]
    t_flight = vy0 == 0.0 ? 0.1 : -2.0 * vy0 / g
    t_flight = max(t_flight, 0.1)
    prob_i = SecondOrderODEProblem(f, du0, u0, (0.0, t_flight), g)
    sol_i = solve(prob_i, saveat = t_flight / 300)
    xs = [sol_i[i][3] for i in 1:length(sol_i)]
    ys = [sol_i[i][4] for i in 1:length(sol_i)]
    cutoff = findfirst(y -> y < 0, ys)
    if cutoff !== nothing
        xs = xs[1:cutoff]
        ys = ys[1:cutoff]
    end
    (xs, ys, maximum(ys), xs[end])
end

x_pts = @lift $(sol_data)[1]
y_pts = @lift $(sol_data)[2]
max_h = @lift $(sol_data)[3]
range_x = @lift $(sol_data)[4]

lines!(ax, x_pts, y_pts, linewidth = 3, color = :dodgerblue)

text!(ax, @lift($(x_pts)[div(length($(x_pts)), 2)]), max_h,
    text = @lift(string("Max height: ", round($(max_h), digits = 1), " m")),
    fontsize = 13,
    color = :dodgerblue,
    align = (:center, :bottom),
    offset = (0, 6))

text!(ax, range_x, 0.0,
    text = @lift(string("Range: ", round($(range_x), digits = 1), " m")),
    fontsize = 13,
    color = :gray40,
    align = (:right, :bottom),
    offset = (-4, 6))

on(sol_data) do (xs, ys, mh, rx)
    xlims!(ax, 0, max(rx, 1.0) * 1.1)
    ylims!(ax, 0, max(mh, 1.0) * 1.2)
end

notify(sl_theta.value)

# Keep window open until closed
display(fig)
wait(fig.scene)
