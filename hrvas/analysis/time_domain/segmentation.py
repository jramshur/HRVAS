from typing import Tuple

import numpy as np
from numpy.typing import NDArray


def calculate_sdann(
    ibi: NDArray[np.float64],
    window_size_s: float = 300.0,
    overlap: bool = False # Standard SDANN usually non-overlapping? MATLAB uses non-overlapping loop
) -> float:
    """
    Calculate SDANN (Standard Deviation of the Average NN intervals).
    SD of the means of NN intervals for each 5-minute (default) segment.

    Args:
        ibi: Array of Inter-Beat Intervals in seconds.
        window_size_s: Window size in seconds (default 300s = 5min).
        overlap: Whether windows should overlap (NOT implemented in basic version matching MATLAB).

    Returns:
        SDANN value in milliseconds.
    """
    # Convert to ms
    nni_ms = ibi * 1000.0
    
    # MATLAB implementation:
    # Loop, check if sum(ibi(buffer)) >= t.
    # Basically accumulate beats until they fill the time window.
    
    means = []
    
    current_window_sum = 0.0
    current_window_vals = []
    
    for val in nni_ms:
        current_window_vals.append(val)
        current_window_sum += (val / 1000.0) # Track time in seconds
        
        if current_window_sum >= window_size_s:
            # Window full
            means.append(np.mean(current_window_vals))
            
            # Reset
            current_window_sum = 0.0
            current_window_vals = []
            
    if not means:
        return 0.0 # Or NaN?
        
    # SDANN is SD of these means
    return float(np.std(means, ddof=1))


def calculate_sdnni(
    ibi: NDArray[np.float64],
    window_size_s: float = 300.0
) -> float:
    """
    Calculate SDNNi (SDNN index).
    Mean of the standard deviations of all NN intervals for each 5-minute segment.

    Args:
        ibi: Array of Inter-Beat Intervals in seconds.
        window_size_s: Window size in seconds.

    Returns:
        SDNNi value in milliseconds.
    """
    nni_ms = ibi * 1000.0
    stds = []
    
    current_window_sum = 0.0
    current_window_vals = []
    
    for val in nni_ms:
        current_window_vals.append(val)
        current_window_sum += (val / 1000.0)
        
        if current_window_sum >= window_size_s:
            stds.append(np.std(current_window_vals, ddof=1))
            current_window_sum = 0.0
            current_window_vals = []
            
    if not stds:
        return 0.0
        
    return float(np.mean(stds))
