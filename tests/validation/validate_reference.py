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
from hrvas.analysis.time_domain import calculate_standard_metrics
from hrvas.preprocessing.artifact import detect_outliers, replace_outliers, DetectionMethod, ReplacementMethod
from hrvas.preprocessing.detrend import detrend_ibi, DetrendMethod
from hrvas.io.ibi_loader import load_ibi

# Constants
VALIDATION_DIR = os.path.dirname(os.path.abspath(__file__))
REFERENCE_SET_DIR = os.path.join(VALIDATION_DIR, 'reference_set')
DATA_DIR = os.path.join(REFERENCE_SET_DIR, 'data')
SETTINGS_FILE = os.path.join(REFERENCE_SET_DIR, 'settings.yaml')
GROUND_TRUTH_FILE = os.path.join(REFERENCE_SET_DIR, 'ground_truth.xlsx')

def main():
    if not os.path.exists(SETTINGS_FILE):
        print("Settings file not found.")
        return

    # Load Config (Standard)
    config = HRVASConfig.from_yaml(SETTINGS_FILE)
    
    # Load GT
    gt_df = pd.read_excel(GROUND_TRUTH_FILE)
    
    ibi_files = sorted(glob.glob(os.path.join(DATA_DIR, '*.ibi')))
    
    print(f"{'Filename':<20} | {'Mean(Raw)':<10} | {'Mean(GT)':<10} | {'SDNN(Raw)':<10} | {'SDNN(Detr)':<11} | {'SDNN(GT)':<10}")
    print("-" * 85)

    for filepath in ibi_files:
        filename = os.path.basename(filepath)
        gt_row = gt_df[gt_df['HRV Variable'] == filename]
        if gt_row.empty: continue
        gt_row = gt_row.iloc[0]
        
        try:
            df = load_ibi(filepath, header_row=None)
            time_s = df['Time'].values
            ibi_s = df['IBI'].values
        except Exception as e:
            print(f"Error loading {filepath}: {e}")
            continue
            
        # 1. Artifact (Standard Settings: 20% / 3SD)
        mask = np.zeros(len(ibi_s), dtype=bool)
        
        # Using hardcoded config values from settings.yaml (since Config obj might be slightly different in logic)
        # Percent 20
        m_pct = detect_outliers(ibi_s, method=DetectionMethod.PERCENT, limit=0.20)
        # SD 3 (updated by user) or 4 (default). Let's use 3.
        m_sd = detect_outliers(ibi_s, method=DetectionMethod.SD, limit=3.0)
        mask = m_pct | m_sd
        
        t_clean, i_clean = replace_outliers(time_s, ibi_s, mask, method=ReplacementMethod.REMOVE)
        
        # 2. Detrended
        fs = 10.0 # From config
        lambda_val = 155.0 # From config
        try:
            i_detrended, _ = detrend_ibi(t_clean, i_clean, method=DetrendMethod.SMOOTHNESS_PRIORS, lambda_param=lambda_val, sampling_rate=fs)
        except:
             # Fallback if Smoothness Priors fails or not supported
             i_detrended = i_clean
            
        # 3. Calculate SDNN
        td_raw = calculate_standard_metrics(i_clean)
        td_detr = calculate_standard_metrics(i_detrended)
        
        # 4. Compare
        gt_mean = gt_row.get('mean', np.nan)
        gt_sdnn = gt_row.get('SDNN', np.nan)
        
        # Highlight Matches
        match_raw = "*" if abs(td_raw.sdnn - gt_sdnn) < 0.1 else " "
        match_detr = "*" if abs(td_detr.sdnn - gt_sdnn) < 0.1 else " "
        
        print(f"{filename:<20} | {td_raw.mean_nni:<10.2f} | {gt_mean:<10.2f} | {td_raw.sdnn:<9.2f}{match_raw} | {td_detr.sdnn:<10.2f}{match_detr} | {gt_sdnn:<10.2f}")

if __name__ == '__main__':
    main()
