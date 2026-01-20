import numpy as np
import os

filepath = 'tests/validation/reference_set/data/control_01.ibi'
data = np.loadtxt(filepath, delimiter=',', usecols=1)
# Handle potential header or format issues if loadtxt fails, but standard ibi is usually csv
# However, load_ibi handled it by checking col count.
# Only 2nd column is IBI.

# Convert to ms
data_ms = data * 1000.0

print(f"Count: {len(data)}")
print(f"Mean (ms): {np.mean(data_ms)}")
print(f"Std (ms): {np.std(data_ms, ddof=1)}") # Sample Std Dev
print(f"RMSSD (ms): {np.sqrt(np.mean(np.diff(data_ms)**2))}")

# Check first few values
print(f"First 5: {data_ms[:5]}")
