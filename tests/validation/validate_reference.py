import os
import sys
import glob
import time
import yaml
import numpy as np
import pandas as pd
from dataclasses import asdict

# Add project root to path so we can import hrvas
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../')))
from hrvas.config import HRVASConfig
from hrvas.analysis.time_domain import (
    calculate_standard_metrics,
    calculate_geometric_metrics,
    calculate_sdann,
    calculate_sdnni
)
from hrvas.preprocessing.artifact.detection import detect_outliers, DetectionMethod
from hrvas.preprocessing.artifact.replacement import replace_outliers, ReplacementMethod
from hrvas.preprocessing.detrend.smoothness_priors import smoothness_priors_detrend
from hrvas.io.ibi_loader import load_ibi

# Constants
VALIDATION_DIR = os.path.dirname(os.path.abspath(__file__))
REFERENCE_SET_DIR = os.path.join(VALIDATION_DIR, 'reference_set')
DATA_DIR = os.path.join(REFERENCE_SET_DIR, 'data')
SETTINGS_FILE = os.path.join(REFERENCE_SET_DIR, 'settings.yaml')
GROUND_TRUTH_FILE = os.path.join(REFERENCE_SET_DIR, 'ground_truth.xlsx')

def main():
    # ... setup ...
    if not os.path.exists(SETTINGS_FILE):
        return

    config = HRVASConfig.from_yaml(SETTINGS_FILE)
    
    # Load raw yaml for future settings
    # ...
    # (Same as before)
    with open(SETTINGS_FILE, 'r') as f:
        raw_settings = yaml.safe_load(f)
    
    future_settings = raw_settings.get('_future', {})
    artifact_settings = future_settings.get('artifacts', {})
    pp_settings = future_settings.get('preprocessing', {})
    
    # ... load GT ...
    gt_df = pd.read_excel(GROUND_TRUTH_FILE)
    
    # Map ground truth columns to expected metrics
    # Metric Mapping: (Python Attribute, Ground Truth Column, Tolerance)
    metric_map = [
        ('mean_nni', 'mean', 1e-1), # Mean NNI (ms)
        ('sdnn', 'SDNN', 1e-1),     # SDNN (ms)
        ('rmssd', 'RMSSD', 1e-1),   # RMSSD (ms)
        ('pnn50', 'pNNx', 1.0),     # pNNx (%) - Using larger tolerance as implementations vary slightly
        ('mean_hr', 'meanHR', 1e-1),# Mean HR (BPM)
        ('sd_hr', 'sdHR', 1e-1),    # SD HR (BPM)
        ('sdann', 'SDANN', 1e-1),   # SDANN (ms)
        ('sdnni', 'SDNNi', 1e-1),   # SDNNi (ms)
        ('triangular_index', 'HRVTi', 1e-2), # Triangular Index
        ('tinn', 'TINN', 1e-1),     # TINN (ms)
    ]    
    results = []
    ibi_files = sorted(glob.glob(os.path.join(DATA_DIR, '*.ibi')))
    
    for filepath in ibi_files:
        filename = os.path.basename(filepath)
        gt_row = gt_df[gt_df['HRV Variable'] == filename]
        if gt_row.empty: continue
        gt_row = gt_row.iloc[0]
        
        try:
            # Use shared loader. 
            # Files have no header, so header_row=None is important.
            df = load_ibi(filepath, header_row=None)
            time_s = df['Time'].values
            ibi_s = df['IBI'].values
        except Exception as e:
            print(f"Error loading {filepath}: {e}")
            continue
            
        # --- Preprocessing Pipeline ---
        # ...
        # (Rest of loop is same, using time_s, ibi_s)
        
        # 1. Artifact Detection
        mask = np.zeros(len(ibi_s), dtype=bool)
        
        det_sd = artifact_settings.get('detection_sd')
        det_pct = artifact_settings.get('detection_percent')
        
        if det_sd is not None:
            mask_sd = detect_outliers(ibi_s, method=DetectionMethod.SD, limit=float(det_sd))
            mask = mask | mask_sd
            
        if det_pct is not None:
             pass 
            
        # 2. Replacement
        rep_method = artifact_settings.get('replacement_method', 'Remove')
        if rep_method == 'Remove':
             time_clean, ibi_clean = replace_outliers(time_s, ibi_s, mask, method=ReplacementMethod.REMOVE)
        else:
             time_clean, ibi_clean = replace_outliers(time_s, ibi_s, mask, method=ReplacementMethod.MEAN) 

        if len(ibi_clean) < 2:
            print(f"Skipping {filename}: Not enough data after cleaning")
            continue

        # 3. Detrending
        # Check if detrending enabled
        detrend_method = pp_settings.get('detrend_method')
        lambda_val = float(pp_settings.get('smoothness_priors_lambda', 500.0))
        
        if detrend_method == 'Smothness Priors': 
            fs = config.frequency_domain.interpolation_rate 
            ibi_detrended, trend = smoothness_priors_detrend(time_clean, ibi_clean, lambda_param=lambda_val, sampling_rate=fs)
        else:
            ibi_detrended = ibi_clean
            
        # --- Analysis ---
        
        td_mean = calculate_standard_metrics(ibi_clean, pnn_threshold_ms=config.time_domain.pnn_threshold_ms)
        td_var = calculate_standard_metrics(ibi_detrended, pnn_threshold_ms=config.time_domain.pnn_threshold_ms)
        
        geo_clean = calculate_geometric_metrics(ibi_clean, bin_width_ms=config.geometric.bin_width_ms)
        geo_detr = calculate_geometric_metrics(ibi_detrended, bin_width_ms=config.geometric.bin_width_ms)

        sdann = calculate_sdann(ibi_clean) 
        sdnni = calculate_sdnni(ibi_clean)
        
        # Assemble Computed Values
        computed = {}
        
        computed['mean_nni'] = td_mean.mean_nni
        computed['mean_hr'] = td_mean.mean_hr
        computed['sd_hr'] = td_mean.sd_hr
        computed['min_hr'] = td_mean.min_hr
        computed['max_hr'] = td_mean.max_hr
        
        computed['sdnn'] = td_var.sdnn
        computed['rmssd'] = td_var.rmssd
        computed['pnn50'] = td_var.pnn50
        computed['nni_50'] = td_var.nni_50
        
        computed['triangular_index'] = geo_clean.triangular_index
        computed['tinn'] = geo_clean.tinn
        
        computed['sdann'] = sdann
        computed['sdnni'] = sdnni
        
        # ... Compare ...
        file_result = {'filename': filename, 'status': 'PASS', 'details': []}
        
        for py_attr, gt_col, tol in metric_map:
            val_py = computed.get(py_attr)
            val_gt = gt_row[gt_col]
            
            if pd.isna(val_gt): continue
            
            if pd.isna(val_py):
                 pass 
            
            diff = abs(val_py - val_gt)
            check = diff <= tol
            
            if not check:
                file_result['status'] = 'FAIL'
                file_result['details'].append(
                    f"{gt_col}: Python={val_py:.4f}, GT={val_gt:.4f}, Diff={diff:.4f}"
                )
            
            results.append({
                'filename': filename,
                'metric': gt_col,
                'python_val': val_py,
                'gt_val': val_gt,
                'error': diff,
                'pass': check
            })
            
        if file_result['status'] == 'FAIL':
            print(f"X {filename} FAILED")
            for d in file_result['details']:
                print(f"    - {d}")
                
    # ... Summary ...
    df_res = pd.DataFrame(results)
    # ... Print ...
    print("\n" + "="*40)
    print("VALIDATION SUMMARY")
    print("="*40)
    
    overall_pass = df_res['pass'].all()
    print(f"Overall Status: {'PASS' if overall_pass else 'FAIL'}")
    
    # Group by metric
    print("\nMetric Performance (Mean Absolute Error):")
    summary = df_res.groupby('metric')['error'].agg(['mean', 'max', 'count'])
    print(summary)

if __name__ == '__main__':
    main()
