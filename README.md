# HRVAS 2.0: Heart Rate Variability Analysis Software

![Status](https://img.shields.io/badge/status-active-success.svg)
![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)
![License](https://img.shields.io/badge/license-GPLv3-blue.svg)

**HRVAS 2.0** is the Python port of the original MATLAB-based [HRVAS](https://github.com/jramshur/HRVAS) tool. It provides a comprehensive library for Heart Rate Variability (HRV) analysis, including preprocessing, time-domain, frequency-domain, and nonlinear analysis.

> **Note**: The original MATLAB code has been moved to the `legacy-matlab` branch.

## Features (In Progress)
-   **Preprocessing**: Artifact detection/correction, advanced detrending (Wavelet, Smoothness Priors).
-   **Time Domain**: SDNN, RMSSD, pNNx, etc.
-   **Frequency Domain**: VLF, LF, HF bands using Welch, Lomb-Scargle, and AR methods.
-   **Nonlinear**: Poincare, DFA, Sample Entropy.
-   **Extensible Design**: "Library-first" architecture allowing for easy integration into other apps or notebooks.

## Installation

```bash
pip install -e .
```

## Quick Start
*See `examples/notebooks` for detailed usage.*

```python
from hrvas.io import load_ibi
from hrvas.preprocessing import preprocess
from hrvas.analysis import time_domain

# 1. Load Data
ibi_data = load_ibi("path/to/file.ibi")

# 2. Preprocess
clean_ibi = preprocess(ibi_data, method="smoothness_priors")

# 3. Analyze
results = time_domain.calculate(clean_ibi)
print(results)
```

## Citation

If you use HRVAS in your research, please cite both the original thesis and this software version:

**Original Thesis:**
Ramshur, J. (2010). *Design, Evaluation, and Application of Heart Rate Variability Analysis Software (HRVAS)*. Masters Thesis. University of Memphis, Memphis, TN.

**Software:**
Ramshur, J. (2024). *HRVAS 2.0: Python Heart Rate Variability Analysis Software*. GitHub. https://github.com/jramshur/HRVAS

## License
GNU General Public License v3 (GPLv3)
