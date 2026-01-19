# General Reference Validation Set

This directory contains the primary validation dataset for the HRVAS port. It consists of ECG Inter-Beat Interval (IBI) data from a rat study involving Control and Treatment groups.

## Data Structure

- **`data/`**: Directory containing **80 anonymized** `.ibi` files.
    - Files `control_01.ibi` to `control_XX.ibi` represent the Control group.
    - Files `treatment_01.ibi` to `treatment_XX.ibi` represent the Treatment (Aldosterone) group.
    
- **`settings.yaml`**: The configuration file used to generate the validation results. Uses modern YAML format mapped to `HRVASConfig`.

- **`ground_truth.xlsx`**: Excel file containing the original HRVAS (MATLAB) output metrics for all 80 files. The filenames in this file correspond to the anonymized names in the `data/` folder.

## Usage
To validate the Python implementation:
1. Load config: `config = HRVASConfig.from_yaml('settings.yaml')`.
2. Run the analysis on all files in `data/`.
3. Compare the output dataframe against `ground_truth.xlsx`.
