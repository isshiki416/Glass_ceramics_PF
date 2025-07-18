import fdtd
import numpy as np
import matplotlib.pyplot as plt
import copy

fdtd.set_backend("numpy")

# Speed of light
SPEED_LIGHT = 299792458.0  # [m/s] speed of light

# Wavelength range
wavelengths = np.linspace(0.2e-6, 2e-6, 100)  # 0.2μm to 3μm range with 200 points

# Create initial FDTD Grid without sources
initial_grid = fdtd.Grid(
    shape=(250, 220, 1),
    grid_spacing=0.1e-6,
    permittivity=1,
)

# Detectors
initial_grid[235, :] = fdtd.LineDetector(name="detector")

# x, y boundaries
initial_grid[0:10, :, :] = fdtd.PML(name="pml_xlow")
initial_grid[-10:, :, :] = fdtd.PML(name="pml_xhigh")
initial_grid[:, 0:10, :] = fdtd.PML(name="pml_ylow")
initial_grid[:, -10:, :] = fdtd.PML(name="pml_yhigh")

# Objects
initial_grid[25:225, 10:210, :] = fdtd.Object(permittivity=2.78, name="background")

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
        initial_grid[x, y, 0] = fdtd.Object(permittivity=7, name=f"object_{x}_{y}")

        

transmission_spectrum = []

for WAVELENGTH in wavelengths:
    # Create a copy of the initial grid
    grid = copy.deepcopy(initial_grid)
    
    # Add source to the grid
    grid[15, :] = fdtd.LineSource(period=WAVELENGTH / SPEED_LIGHT, name="source")

    # Run simulation
    grid.run(2000, progress_bar=False)

    # Retrieve detector data
    detector = grid.detectors[0]  # Access the first detector
    detector_values = detector.detector_values()  # Call the method to get data
    
    # Print the keys of the dictionary to understand its structure
    print(f"Detector values keys for wavelength {WAVELENGTH * 1e9} nm: {detector_values.keys()}")
    
    # Assuming the values we need are under a key named 'E'
    if 'E' in detector_values:
        transmission = np.abs(detector_values['E']) ** 2
        transmission_spectrum.append(np.mean(transmission))
    else:
        print(f"Key 'E' not found in detector values for wavelength {WAVELENGTH * 1e9} nm")
        transmission_spectrum.append(0)

# Convert wavelength to nm for saving
wavelengths_nm = wavelengths * 1e9

# Save the results to a txt file
with open("transmission_spectrum_X=0.3_R=0.3um.txt", "w") as file:
    file.write("Wavelength (nm)\tTransmission\n")
    for wavelength, transmission in zip(wavelengths_nm, transmission_spectrum):
        file.write(f"{wavelength}\t{transmission}\n")

# Plot the transmission spectrum
plt.plot(wavelengths_nm, transmission_spectrum)
plt.xlabel("Wavelength (nm)")
plt.ylabel("Transmission")
plt.title("Transmission Spectrum")
plt.grid(True)
plt.savefig('fig_transmission_spectrum_X=0.3_R=0.3um.png', bbox_inches='tight')
plt.show()

