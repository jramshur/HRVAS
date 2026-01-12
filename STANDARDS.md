# Coding Standards and Architecture

## 1. Data Structures

### Analysis Results
*   **Always return Dataclasses**: Analysis functions must return strictly typed `dataclass` objects, never raw tuples or dictionaries.
*   **Naming Convention**: Result classes should be named `[Domain]Results` (e.g., `TimeDomainResults`, `GeometricResults`).
*   **HRVMetrics Container**: All domain-specific results are aggregated into `hrvas.analysis.results.HRVMetrics`.

### Configuration
*   **Use HRVASConfig**: All analysis parameters should be managed via `hrvas.config.HRVASConfig` and its sub-configs.
*   **Defaults**: Default values should mirror standard HRVAS (MATLAB) settings where appropriate, but be explicitly exposed in the config classes.

## 2. Frequency Domain & PSD
*   **PSD Availability**: Raw Power Spectral Density (PSD) arrays must be available for visualization.
*   **Return Type**: Frequency domain analysis should return a `FrequencyDomainResults` object that acts as a container for scalar metrics (LF, HF) and optionally includes the spectrum data if requested.

## 3. General Python Patterns
*   **Type Hinting**: All functions must have type hints.
*   **Docstrings**: Use Google-style docstrings.
*   **Pandas for Data**: Use `pandas.DataFrame` for time-series data (IBI, RR intervals).

## 4. Nomenclature & Variables

### Mathematical Abstractions
*   **Context**: For algorithms derived directly from mathematical logic or published papers (e.g., TINN, Geometrical Analysis), single-letter variable names (like `D`, `Y`, `M`, `N`) are **permitted** to maintain alignment with the source material.
*   **Requirement**: Such variables **MUST** be accompanied by a mapping comment block explaining their semantic meaning (e.g., `# D: Histogram counts`).

### Data Terminology
*   **IBI (Inter-Beat Interval)**: Refers to raw, potentially noisy beat-to-beat intervals.
*   **NNI (Normal-to-Normal Interval)**: Refers to cleaned, artifact-free intervals suitable for analysis.
*   **Requirement**: Analysis functions should prefer `nni` as the argument name to strongly imply that they expect clean data.

### Polymorphic Parameters
*   **Context**: Functions where a parameter's meaning changes based on another parameter (e.g., `limit` changes based on `method`).
*   **Requirement**: The docstring **MUST** explicitly enumerate the meaning of the parameter for each mode.
