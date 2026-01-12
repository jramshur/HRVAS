from enum import Enum
from typing import Tuple

import numpy as np
from numpy.typing import NDArray
from scipy.interpolate import interp1d


class ReplacementMethod(str, Enum):
    """Methods available for artifact replacement."""
    REMOVE = "remove"
    MEAN = "mean"
    MEDIAN = "median"
    SPLINE = "spline"
    CUBIC = "cubic" # Alias for spline/cubic


def replace_outliers(
    time_values: NDArray[np.float64],
    ibi_values: NDArray[np.float64],
    outliers: NDArray[np.bool_],
    method: ReplacementMethod = ReplacementMethod.MEAN,
    window_size: int = 5,
) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
    """
    Replace or remove detected outliers in an IBI series.

    Args:
        time_values: Array of time stamps.
        ibi_values: Array of IBI values.
        outliers: Boolean mask of outliers (True = outlier).
        method: Replacement strategy.
        window_size: Size of the sliding window for local averaging/median (odd integer).

    Returns:
        Tuple containing (corrected_time, corrected_ibi).
    """
    time = np.asarray(time_values)
    ibi = np.asarray(ibi_values)
    
    if method == ReplacementMethod.REMOVE:
        keep = ~outliers
        return time[keep], ibi[keep]

    # Initialize corrected IBI with original values
    new_ibi = ibi.copy()
    
    if method in (ReplacementMethod.MEAN, ReplacementMethod.MEDIAN):
        if window_size % 2 == 0:
            window_size += 1 # Ensure odd
            
        half_window = (window_size - 1) // 2
        outlier_indices = np.where(outliers)[0]
        
        # Create a reference array where outliers are NaN to exclude them from local stats
        ref_ibi = ibi.copy()
        ref_ibi[outliers] = np.nan
        
        for idx in outlier_indices:
            start = max(0, idx - half_window)
            end = min(len(ibi), idx + half_window + 1)
            
            window_vals = ref_ibi[start:end]
            valid_vals = window_vals[~np.isnan(window_vals)]
            
            if len(valid_vals) > 0:
                if method == ReplacementMethod.MEAN:
                    new_ibi[idx] = np.mean(valid_vals)
                else: # Median
                    new_ibi[idx] = np.median(valid_vals)

    elif method in (ReplacementMethod.SPLINE, ReplacementMethod.CUBIC):
        valid_mask = ~outliers
        if np.sum(valid_mask) >= 2:
            t_valid = time[valid_mask]
            y_valid = ibi[valid_mask]
            
            kind = 'cubic' if len(t_valid) > 3 else 'linear'
            f_interp = interp1d(t_valid, y_valid, kind=kind, fill_value="extrapolate")
            new_ibi[outliers] = f_interp(time[outliers])

    return time, new_ibi
