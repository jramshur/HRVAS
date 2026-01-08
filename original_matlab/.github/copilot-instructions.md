<!-- Copilot instructions for working on the HRVAS MATLAB codebase -->
# HRVAS — AI coding assistant guidance

This file contains focused, actionable guidance for AI code agents editing the HRVAS MATLAB project.

- **Big picture:** `HRVAS.m` is the main GUI entry point (large single-file GUI). Core processing is implemented as modular MATLAB functions in the repository root (e.g. `preProcessIBI.m`, `timeDomainHRV.m`, `freqDomainHRV.m`, `timeFreqHRV.m`, `nonlinearHRV.m`, `poincareHRV.m`). Batch processing and I/O are in `batchHRV.m` and `exportHRV.m`.
- **Data flow (typical):** `loadIBI` -> `preProcessIBI` (artifact locate/replace, detrend) -> domain analyses (`timeDomainHRV`, `freqDomainHRV`, `timeFreqHRV`, `nonlinearHRV`) -> collect structure -> `exportHRV` (writes CSV/XLS).
- **Primary file references:** [README.md](../README.md), [HRVAS.m](../HRVAS.m), [batchHRV.m](../batchHRV.m), [preProcessIBI.m](../preProcessIBI.m), [exportHRV.m](../exportHRV.m).

- **Runtime / developer workflows:**
  - Launch interactive GUI in MATLAB by running `main` or `HRVAS` (calls `HRVAS.m`). Use the GUI to load `.ibi` files from `SampleData/` for quick manual tests.
  - Batch processing: run `batchHRV` (the script contains both GUI and console flows). When running from terminal/console, the batch flow will prompt for paths; use sample files in `SampleData/` to reproduce.
  - There is no automated test harness. Use quick manual checks: run `batchHRV` with a small sample set and verify `exportHRV` output (CSV/XLS).

- **Project-specific conventions & patterns:**
  - IBI data is handled as N×2 matrices: first column = time (seconds or increasing timestamps), second column = IBI (seconds). Many functions expect this shape (see `preProcessIBI.m`).
  - Settings/options are persisted to `.mat` files (`settings.mat`, `settings_human.mat`, `settings_rat.mat`). Functions and GUIs load/save `settings` structures — prefer to update defaults there when adding options.
  - The GUI uses several global variables (e.g. `HRV`, `h`, `flagProcessed`) — avoid refactoring globals without ensuring GUI state remains consistent.
  - Frequency-domain code produces multiple PSD methods (Welch / AR / Lomb) and `exportHRV` assumes three sets when building columns.

- **Integration points / external dependencies:**
  - Pure MATLAB code; depends on Signal Processing and Wavelet toolboxes for some routines (wavelet, wpdec, wavedec). Confirm availability when running on CI/VM.
  - Uses `xlswrite` when exporting `.xlsx`; on non-Windows platforms MATLAB's support for Excel may fall back to CSV — prefer CSV for headless runs.

- **Editing guidance for AI agents:**
  - Small, focused edits are preferred: change/extend a single function (e.g. `preProcessIBI.m`) and run `batchHRV` to validate end-to-end behavior with `SampleData/example.ibi`.
  - When modifying analysis outputs, update `exportHRV.m` so the CSV/XLS columns remain consistent. `exportHRV` dynamically builds column order from HRV struct fields; mirror that logic when adding new fields.
  - Avoid large GUI rewrites in a single change. If you must change `HRVAS.m`, keep changes localized and preserve existing callbacks and global state usage.
  - Preserve file I/O formats: `.ibi` files and the 2-column IBI matrix shape. If changing the format, update `loadIBI` and document the change in `README.md`.

- **Examples (from code):**
  - Preprocessing is called with many name-value options in `batchHRV.m`:
    - `preProcessIBI(IBI, 'locateMethod', methods, 'replaceMethod', settings.ArtReplace, 'detrendMethod', settings.Detrend, 'resampleRate',settings.Interp, ...)`
  - Batch export flow: `hrv = batchGetHRV(fpaths,opt,flagNoGui); saveHRV(hrv,opt,fpaths,outPath)` which delegates to `exportHRV`.

- **What to run to reproduce common checks:**
  - In MATLAB (interactive): run `main` then open `SampleData/example.ibi` and press `Run` in GUI.
  - From MATLAB console: run `batchHRV` and follow prompts or point to a small folder `SampleData/` and export to CSV.

- **What I (the human) usually expect from an AI change:**
  - Minimal diffs, unit-like manual verification steps (run GUI/batch on sample data), and updates to `README.md` or `settings.mat` if defaults change.

If any of these items are unclear or you want the document to include more examples (call signatures, exact field names in `settings`), tell me which functions or areas to expand and I'll iterate.
