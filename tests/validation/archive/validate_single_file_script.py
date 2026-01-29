import os
import sys
import numpy as np
import pandas as pd
from hrvas.config import HRVASConfig
from hrvas.io import load_ibi
from hrvas.preprocessing import detrend_ibi, DetrendMethod
from hrvas.preprocessing.artifact import detect_outliers, replace_outliers, DetectionMethod, ReplacementMethod
from hrvas.analysis.time_domain import calculate_standard_metrics

# Parameters
VALIDATION_DIR = os.path.dirname(os.path.abspath(__file__))
REF_DIR = os.path.join(VALIDATION_DIR, 'reference_set')
DATA_DIR = os.path.join(REF_DIR, 'data')
SETTINGS_FILE = os.path.join(REF_DIR, 'settings.yaml')
GT_FILE = os.path.join(REF_DIR, 'ground_truth.xlsx')
FILENAME = 'control_01.ibi'

def main():
    print(f"--- HRVAS Validation: {FILENAME} ---")
    
    # 1. Load Configuration
    if not os.path.exists(SETTINGS_FILE):
        print(f"Error: Settings file not found at {SETTINGS_FILE}")
        return
    config = HRVASConfig.from_yaml(SETTINGS_FILE)
    print("Configuration loaded successfully.")
    
    # 2. Load Data
    filepath = os.path.join(DATA_DIR, FILENAME)
    if not os.path.exists(filepath):
        print(f"Error: Data file not found at {filepath}")
        return
    
    # header_row=None is crucial for these .ibi files
    df = load_ibi(filepath, header_row=None)
    time_raw = df['Time'].values
    ibi_raw = df['IBI'].values    
    print(f"Data Loaded. Beats: {len(ibi_raw)}")
    
    # 3. Preprocessing
    
    # A. Artifact Detection & Correction (on Raw IBI)
    # MATLAB: preProcessIBI calls correctEctopic (Art) then detrendIBI
    print("Step A: Artifact Detection (on Raw IBI)")
    art_det = config.preprocessing.artifact_detection
    mask = np.zeros(len(ibi_raw), dtype=bool)
    
    if art_det.percent.enabled:
        limit = art_det.percent.threshold / 100.0
        m = detect_outliers(ibi_raw, method=DetectionMethod.PERCENT, limit=limit)
        mask = mask | m
        print(f"  - Percent Method ({limit*100}%): Found {np.sum(m)} outliers")
        
    if art_det.std_dev.enabled:
        limit = art_det.std_dev.threshold
        m = detect_outliers(ibi_raw, method=DetectionMethod.SD, limit=limit)
        mask = mask | m
        print(f"  - SD Method ({limit} sigma): Found {np.sum(m)} outliers")
        
    if art_det.median.enabled:
        limit = art_det.median.threshold
        m = detect_outliers(ibi_raw, method=DetectionMethod.MEDIAN, limit=limit)
        mask = mask | m
        print(f"  - Median Method: Found {np.sum(m)} outliers")
        
    print(f"Total Outliers: {np.sum(mask)}")

    # Replacement
    rep_conf = config.preprocessing.artifact_replace
    rep_method_enum = ReplacementMethod.REMOVE
    if rep_conf.method == "Mean": rep_method_enum = ReplacementMethod.MEAN
    elif rep_conf.method == "Median": rep_method_enum = ReplacementMethod.MEDIAN
    elif rep_conf.method == "Spline": rep_method_enum = ReplacementMethod.SPLINE
    
    time_clean, ibi_clean = replace_outliers(
        time_raw, 
        ibi_raw, 
        outliers=mask, 
        method=rep_method_enum
    )
    print(f"Cleaned Data: {len(ibi_clean)} beats (nIBI)")
    
    # B. Detrending (on Cleaned IBI)
    # MATLAB: output of correctEctopic -> detrendIBI -> dIBI
    print("Step B: Detrending (on Cleaned IBI)")
    det_conf = config.preprocessing.detrending
    print(f"Detrending Method: {det_conf.method}")
    # Get sampling rate from config
    fs = config.frequency_domain.interpolation_rate
    print(f"Sampling Rate for Detrending: {fs} Hz")
    
    if det_conf.method == "Smoothness Priors":
        detrended_ibi, trend = detrend_ibi(
            time_clean, 
            ibi_clean, 
            method=DetrendMethod.SMOOTHNESS_PRIORS, 
            lambda_param=det_conf.smoothness_priors_lambda,
            sampling_rate=fs
        )
    elif det_conf.method == "Polynomial":
        detrended_ibi, trend = detrend_ibi(
            time_clean, ibi_clean, method=DetrendMethod.POLYNOMIAL
        )
    else:
        detrended_ibi = ibi_clean
        trend = np.zeros_like(ibi_clean)
    
    print("Preprocessing Complete.")

    # 4. Analysis
    print("\n--- Analysis ---")
    
    # Time Domain: Uses nIBI (Cleaned Raw)
    # Reference: HRVAS.m line 386: output.time=timeDomainHRV(nIBI,...)
    print("Time Domain (Input: Cleaned Raw IBI)")
    td_results = calculate_standard_metrics(ibi_clean, pnn_threshold_ms=config.time_domain.pnn_threshold_ms)
    print(td_results)
    
    # Calculate Detrended for Debug comparison
    td_detrended = calculate_standard_metrics(detrended_ibi, pnn_threshold_ms=config.time_domain.pnn_threshold_ms)
    
    # 5. Compare
    print("\n--- Comparison ---")
    if os.path.exists(GT_FILE):
        gt_df = pd.read_excel(GT_FILE)
        
        # Check available columns
        # print(f"GT Columns: {list(gt_df.columns)}")
        
        row = gt_df[gt_df.iloc[:,0] == FILENAME]
        if not row.empty:
            # Metric Map
            col_map_td = {
                'mean': ('mean_nni', td_results), 
                'SDNN': ('sdnn', td_results), 
                'RMSSD': ('rmssd', td_results),
                'pNNx': ('pnn50', td_results),
                # Debug: Check if GT SDNN matches Detrended SDNN
                'SDNN_Detr': ('sdnn', td_detrended) 
            }
            
            print(f"{'Metric':<12} | {'Python':<10} | {'MATLAB':<10} | {'Diff':<10}")
            print("-" * 50)
            
            for gt_col, (py_attr, result_obj) in col_map_td.items():
                # Handle debug column that might not exist in GT, so we manually check logic
                matched_gt_col = gt_col
                if gt_col == 'SDNN_Detr': matched_gt_col = 'SDNN' # Compare against GT SDNN

                if matched_gt_col in row.columns:
                    gt_val = row[matched_gt_col].values[0]
                    py_val = getattr(result_obj, py_attr)
                    
                    # Units:
                    # calculate_standard_metrics returns ms for mean, sdnn, rmssd.
                    # returns percent (0-100) for pnn50.
                    
                    py_disp = py_val
                    
                    # Check pNNx scaling
                    if py_attr == 'pnn50':
                        # If GT is < 1 (Ratio), convert Py (Percent) to Ratio? 
                        # Or if GT is > 1 (Percent), keep Py as Percent.
                        # HRVAS MATLAB usually uses % for pNNx.
                        pass

                    diff = abs(py_disp - gt_val)
                    print(f"{gt_col:<12} | {py_disp:<10.4f} | {gt_val:<10.4f} | {diff:<10.4f}")
                else:
                    print(f"{gt_col:<12} | NOT FOUND IN GT")
        else:
            print("File not found in GT.")

if __name__ == "__main__":
    main()
