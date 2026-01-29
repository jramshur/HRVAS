import os
import sys
import numpy as np
import pandas as pd
from hrvas.io import load_ibi
from hrvas.analysis.time_domain import calculate_sdnni, calculate_sdann

# Parameters
VALIDATION_DIR = os.path.dirname(os.path.abspath(__file__))
REF_DIR = os.path.join(VALIDATION_DIR, 'reference_set')
DATA_DIR = os.path.join(REF_DIR, 'data')
FILENAME = 'control_01.ibi'
GT_SDNN = 2.1
GT_SDNNI = 2.0
GT_SDANN = 2.0

def run_sweep():
    filepath = os.path.join(DATA_DIR, FILENAME)
    df = load_ibi(filepath, header_row=None)
    time_raw = df['Time'].values
    ibi_raw = df['IBI'].values # Raw data (Cleaned is same as Raw for control_01)
    
    print(f"--- SDNN/SDNNi Settings Sweep for {FILENAME} ---")
    print(f"GT SDNN: {GT_SDNN} | GT SDNNi: {GT_SDNNI} | GT SDANN: {GT_SDANN}")
    
    results = []
    
    # Sweep Window Sizes for SDNNi / SDANN
    # 30s is default. Try 10s to 300s.
    print("\nSweeping Window Size (Seconds) for SDNNi/SDANN on Raw IBI...")
    
    windows = [10, 20, 30, 45, 60, 90, 120, 150, 200, 300]
    
    for win in windows:
        # Calculate SDNNi
        try:
            sdnni = calculate_sdnni(ibi_raw, window_size_s=win)
        except:
            sdnni = np.nan
            
        # Calculate SDANN
        try:
            sdann = calculate_sdann(ibi_raw, window_size_s=win)
        except:
            sdann = np.nan
            
        # Also calculate "Local SDNN" (Time Domain SDNN in local window? No, SDNN is global)
        
        diff_sdnni = abs(sdnni - GT_SDNNI) if not np.isnan(sdnni) else 999
        diff_sdann = abs(sdann - GT_SDANN) if not np.isnan(sdann) else 999
        
        results.append({
            'Window(s)': win,
            'SDNNi': sdnni,
            'SDANN': sdann,
            'Diff_SDNNi': diff_sdnni
        })

    res_df = pd.DataFrame(results)
    print("\n--- Results ---")
    print(res_df.to_string(index=False))

if __name__ == "__main__":
    run_sweep()
