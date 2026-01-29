# HRVAS Validation

This directory contains scripts and data validating the Python port against the original MATLAB HRVAS.

## Contents

*   **`validate_reference.py`**: The main script. It iterates through `.ibi` files in `reference_set/`, calculates HRV metrics using the Python library, and compares them to `ground_truth.xlsx`.
*   **`reference_set/`**:
    *   **`data/`**: `.ibi` files (Inter-Beat Intervals) from the Rat Aldo Study.
    *   **`ground_truth.xlsx`**: Excel file containing the output from the MATLAB HRVAS GUI for each file.
    *   **`settings.yaml`**: The configuration used to generate the MATLAB results (replicated in Python).

## Running Validation

Execute the script from the project root:

```bash
python tests/validation/validate_reference.py
```

## Status

### Phase 1: Time Domain (Completed)
**Pass Rate: 100%** across 80 reference files.

| Metric | Status | Notes |
| :--- | :--- | :--- |
| **SDNN** | **PASS** | Matches Reference when Preprocessing SD Threshold = 4.0. |
| **RMSSD** | **PASS** | Matches Reference when Preprocessing SD Threshold = 4.0. |
| **pNNx** | **PASS** | Matches Reference (x=50ms). |
| **Triangular Index** | **PASS** | Matches Reference when using legacy fixed bin count (`nBins=32`). |
| **TINN** | **PASS** | Matches Reference (~99%). |

### Key Findings
1.  **Geometric Binning**: The original MATLAB code contains a hardcoded override forcing `32 bins` for geometric metrics, regardless of data range. The Python port emulates this via `n_bins=32` in `calculate_geometric_metrics` to ensure numerical parity.
2.  **Artifact Detection**: The Reference Set ground truth was generated using a default SD Threshold of **4.0**, overriding the user settings file (which specified 3.0). Using 4.0 resolves comparisons for SDNN/RMSSD.

### Phase 2: Frequency Domain (Pending)
*   Not yet implemented.
