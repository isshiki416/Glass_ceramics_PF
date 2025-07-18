import fdtd
import numpy as np
import matplotlib.pyplot as plt

import fdtd.backend as bd

fdtd.set_backend("numpy")

WAVELENGTH = 0.6e-6
SPEED_LIGHT = 299792458.0  # [m/s] speed of light

# Create initial FDTD Grid without sources
grid = fdtd.Grid(
    shape=(250, 220, 1),
    grid_spacing=0.1e-6,
    permittivity=1,
)

# Detectors and sources
grid[15, :] = fdtd.LineSource(period=WAVELENGTH / SPEED_LIGHT, name="source")
grid[235, :] = fdtd.LineDetector(name="detector")

# x, y boundaries
grid[0:10, :, :] = fdtd.PML(name="pml_xlow")
grid[-10:, :, :] = fdtd.PML(name="pml_xhigh")
grid[:, 0:10, :] = fdtd.PML(name="pml_ylow")
grid[:, -10:, :] = fdtd.PML(name="pml_yhigh")

grid[25:225, 10:210, :] = fdtd.Object(permittivity=2.78, name="background")

#  Read the coordinates from the.txt file and set the object
filename = "FDTD_marked_grid_points_X=0.3_R=0.3um.txt"
def read_coordinates(filename):
    with open(filename, 'r') as file:
        coordinates = []
        for line in file:
            line = line.strip()
            if line:
                # Remove parentheses and split into x and y
                line = line.strip('()')
                x, y = map(int, line.split(','))
                coordinates.append((x, y))
        return coordinates
coordinates = read_coordinates(filename)
# Set the grid cell corresponding to the coordinates to fdtd.
for (x, y) in coordinates:
    if 25 <= x < 225 and 10 <= y < 210:  #  Make sure the coordinates are within the rectangle.
        grid[x, y, 0] = fdtd.Object(permittivity=7, name=f"object_{x}_{y}")

# Run simulation
grid.run(10000, progress_bar=False)

grid.visualize(z=0)

plt.savefig('1_600nm_X=0.3_R=0.3um.png', bbox_inches='tight')
plt.show()

fig, axes = plt.subplots(3, 3, dpi=300)
titles = ["Ex: xy", "Ey: xy", "Ez: xy", "Hx: xy", "Hy: xy", "Hz: xy"]

fields = bd.stack(
    [
        grid.E[:, :, 0, 0],
        grid.E[:, :, 0, 1],
        grid.E[:, :, 0, 2],
        grid.H[:, :, 0, 0],
        grid.H[:, :, 0, 1],
        grid.H[:, :, 0, 2],
    ]
)

m = max(abs(fields.min().item()), abs(fields.max().item()))

for ax, field, title in zip(axes.ravel(), fields, titles):
    ax.set_axis_off()
    ax.set_title(title)
    ax.imshow(bd.numpy(field), vmin=-m, vmax=m, cmap="RdBu")

plt.savefig('2_600nm_X=0.3_R=0.3um.png', bbox_inches='tight')
plt.show()

Sx = grid.E[:, :, 0, 1] * grid.H[:, :, 0, 2] - grid.E[:, :, 0, 2] * grid.H[:, :, 0, 1]
Sy = grid.E[:, :, 0, 2] * grid.H[:, :, 0, 0] - grid.E[:, :, 0, 0] * grid.H[:, :, 0, 2]

fig, ax = plt.subplots(dpi=300)
ax.set_title("Power Flow (Poynting Vector)")
ax.set_axis_off()
power_flow = np.sqrt(Sx**2 + Sy**2)
ax.imshow(bd.numpy(power_flow), cmap="inferno")
plt.colorbar(ax.imshow(bd.numpy(power_flow), cmap="inferno"), ax=ax, orientation='vertical', label='Power Flow')
plt.savefig('3_600nm_X=0.3_R=0.3um.png', bbox_inches='tight')
plt.show()


with open("field_data_Ez_and_PowerFlow_600nm_X=0.3_R=0.3um.txt", "w") as file:
    file.write("x, y, Ez, Sx, Sy\n")
    for x in range(25, 225):
        for y in range(10, 210):
            Ez = grid.E[x, y, 0, 2]
            Sx_val = Sx[x, y]
            Sy_val = Sy[x, y]
            file.write(f"{x}, {y}, {Ez}, {Sx_val}, {Sy_val}\n")

