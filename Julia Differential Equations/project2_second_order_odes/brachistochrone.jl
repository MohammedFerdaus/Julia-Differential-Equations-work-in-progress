# Add needed packages
using GLMakie
using OrdinaryDiffEq

# Brachistochrone problem — curve of fastest descent
# Find the path between two points along which a frictionless bead
# slides in minimum time under gravity alone
#
# The analytic solution is a cycloid parameterized by angle theta:
#   x(theta) = R * (theta - sin(theta))
#   y(theta) = R * (1 - cos(theta))
#
# R is determined by matching the endpoint (x_end, y_end)
# Travel time along any curve is given by:
#   T = integral of ds / v
# where v = sqrt(2 * g * (y_start - y)) by energy conservation

# Gravitational acceleration (m/s^2)
const g = 9.8

# Find R for the cycloid passing through (x_end, y_end)
function find_R(x_end, y_end)
    f(theta) = (theta - sin(theta)) / (1 - cos(theta)) - x_end / y_end
    lo, hi = 1e-6, 2π - 1e-6
    for _ in 1:100
        mid = (lo + hi) / 2
        f(mid) > 0 ? hi = mid : lo = mid
    end
    theta_end = (lo + hi) / 2
    R = y_end / (1 - cos(theta_end))
    (R, theta_end)
end

# Generate cycloid points
function cycloid_curve(R, theta_end, n = 300)
    thetas = range(0, theta_end, length = n)
    xs = R .* (thetas .- sin.(thetas))
    ys = -(R .* (1 .- cos.(thetas)))
    (xs, ys)
end

# Travel time along a discrete curve
function travel_time(xs, ys)
    T = 0.0
    for i in 2:length(xs)
        dx = xs[i] - xs[i-1]
        dy = ys[i] - ys[i-1]
        ds = sqrt(dx^2 + dy^2)
        y_mid = (ys[i] + ys[i-1]) / 2
        h = max(-y_mid, 1e-10)
        v = sqrt(2 * g * h)
        T += ds / v
    end
    T
end

# Straight line between two points
function straight_line(x_end, y_end, n = 300)
    xs = collect(range(0, x_end, length = n))
    ys = collect(range(0, -y_end, length = n))
    (xs, ys)
end

# Circular arc scaled to endpoints
function circular_arc(x_end, y_end, n = 300)
    thetas = range(π, π/2, length = n)
    R = sqrt(x_end^2 + y_end^2)
    xs = R .* cos.(thetas) .+ R
    ys = R .* sin.(thetas)
    xs = xs .* (x_end / xs[end])
    ys = ys .* (-y_end / (-ys[end]))
    (xs, ys)
end

# Interactive plot
fig = Figure(size = (800, 800))

Label(fig[0, 1:2], "Brachistochrone — Curve of Fastest Descent",
    fontsize = 22, font = :bold, tellwidth = false)

ax = Axis(fig[1, 1],
    xlabel = "Horizontal distance (m)",
    ylabel = "Vertical distance (m)",
    xgridvisible = true,
    ygridvisible = true)

# Give the axis column much more space than the slider column
colsize!(fig.layout, 1, Relative(0.78))

# Slider panel
slider_grid = GridLayout(fig[1, 2])

Label(slider_grid[1, 1], "Endpoint x (m)", halign = :left)
sl_x = Slider(slider_grid[2, 1], range = 0.5:0.1:5.0, startvalue = 2.0)

Label(slider_grid[3, 1], "Endpoint y (m)", halign = :left)
sl_y = Slider(slider_grid[4, 1], range = 0.5:0.1:5.0, startvalue = 1.5)

Label(slider_grid[2, 2], @lift(string($(sl_x.value), " m")))
Label(slider_grid[4, 2], @lift(string($(sl_y.value), " m")))

# Reactive curve data
curve_data = @lift begin
    x_end = Float64($(sl_x.value))
    y_end = Float64($(sl_y.value))
    R, theta_end = find_R(x_end, y_end)
    cx, cy = cycloid_curve(R, theta_end)
    sx, sy = straight_line(x_end, y_end)
    ax_x, ax_y = circular_arc(x_end, y_end)
    t_cycloid = travel_time(cx, cy)
    t_straight = travel_time(sx, sy)
    t_arc = travel_time(ax_x, ax_y)
    (cx, cy, sx, sy, ax_x, ax_y, t_cycloid, t_straight, t_arc, x_end, y_end)
end

# Plot the three curves
l1 = lines!(ax,
    @lift($(curve_data)[1]),
    @lift($(curve_data)[2]),
    linewidth = 3, color = :dodgerblue)

l2 = lines!(ax,
    @lift($(curve_data)[3]),
    @lift($(curve_data)[4]),
    linewidth = 2, color = :tomato, linestyle = :dash)

l3 = lines!(ax,
    @lift($(curve_data)[5]),
    @lift($(curve_data)[6]),
    linewidth = 2, color = :seagreen, linestyle = :dot)

# Legend below the plot
Legend(fig[2, 1],
    [l1, l2, l3],
    ["Cycloid (brachistochrone)", "Straight line", "Circular arc"],
    orientation = :horizontal,
    tellwidth = false)

# Time annotation
text!(ax, @lift($(curve_data)[10] * 0.02), @lift(-$(curve_data)[11] * 0.75),
    text = @lift(string(
        "Cycloid:  ", round($(curve_data)[7], digits = 4), " s\n",
        "Straight: ", round($(curve_data)[8], digits = 4), " s\n",
        "Arc:      ", round($(curve_data)[9], digits = 4), " s")),
    fontsize = 14,
    color = :black,
    align = (:left, :top))

# Start and end point markers
scatter!(ax, [0.0], [0.0], markersize = 14, color = :black)
scatter!(ax,
    @lift([$(curve_data)[10]]),
    @lift([-$(curve_data)[11]]),
    markersize = 14, color = :black)

on(curve_data) do d
    xlims!(ax, -0.1, d[10] * 1.1)
    ylims!(ax, -d[11] * 1.2, d[11] * 0.2)
end

notify(sl_x.value)

# Keep window open until closed
display(fig)
wait(fig.scene)
