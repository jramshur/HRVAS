from enum import Enum
from typing import Optional, Tuple, Union

import numpy as np
from numpy.typing import NDArray
from scipy.interpolate import interp1d
from scipy.signal import detrend


class DetectionMethod(str, Enum):
    """Methods available for artifact detection."""
    PERCENT = "percent"
    SD = "sd"
    MEDIAN = "median"
    THRESHOLD_ABOVE = "threshold_above"
    THRESHOLD_BELOW = "threshold_below"


class ReplacementMethod(str, Enum):
    """Methods available for artifact replacement."""
    REMOVE = "remove"
    MEAN = "mean"
    MEDIAN = "median"
    SPLINE = "spline"
    CUBIC = "cubic" # Alias for spline/cubic


def detect_outliers(
    ibi_values: NDArray[np.float64],
    method: DetectionMethod = DetectionMethod.PERCENT,
    limit: float = 0.2,
) -> NDArray[np.bool_]:
    """
    Detect outliers/artifacts in an IBI series.

    Args:
        ibi_values: Array of Inter-Beat Interval values.
        method: The detection algorithm to use.
        limit: Threshold/limit for the detection method.
               - PERCENT: e.g. 0.2 for 20% change from previous beat.
               - SD: e.g. 3 for 3 standard deviations from mean.
               - MEDIAN: e.g. 4 for MAD-based z-score threshold.
               - THRESHOLD_*: The absolute value threshold.

    Returns:
        Boolean array of same shape as input, where True indicates an outlier.
    """
    # Ensure input is a numpy array
    ibi = np.asarray(ibi_values, dtype=np.float64)
    outliers = np.zeros(len(ibi), dtype=bool)

    if method == DetectionMethod.PERCENT:
        # PChange = abs(diff(ibi)) / ibi[prev]
        diffs = np.abs(np.diff(ibi))
        percent_change = diffs / ibi[:-1]
        
        # Shift result to align indices (compare i to i-1)
        outliers[1:] = percent_change > limit

    elif method == DetectionMethod.SD:
        # Linear detrend before calculating stats
        detrended_ibi = detrend(ibi, type='linear')
        mu = np.mean(detrended_ibi)
        sigma = np.std(detrended_ibi)
        
        outliers = np.abs(detrended_ibi - mu) > (limit * sigma)

    elif method == DetectionMethod.MEDIAN:
        med_val = np.median(ibi)
        mad = np.median(np.abs(ibi - med_val))
        
        # Scale factor for normal distribution consistency
        scale_factor = 1.0 if mad == 0 else 1.483 * mad
            
        deviation = np.abs(ibi - med_val) / scale_factor
        outliers = deviation > limit

    elif method == DetectionMethod.THRESHOLD_ABOVE:
        outliers = ibi > limit

    elif method == DetectionMethod.THRESHOLD_BELOW:
        outliers = ibi < limit

    return outliers


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
        
        # Iterate only through outlier indices for efficiency
        # Note: If there are many outliers, a vectorized convolution approach might be faster,
        # but handling arbitrary NaNs in convolution is tricky. Iteration is fine for IBI series
        # which are typically < 100k points with sparse outliers.
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
            # If no valid neighbors, the outlier remains or we could interpolate.
            # Current behavior: remains original outlier value (since we copied ibi). 
            # Ideally we might want linear interp here as fallback.

    elif method in (ReplacementMethod.SPLINE, ReplacementMethod.CUBIC):
        valid_mask = ~outliers
        if np.sum(valid_mask) >= 2:
            t_valid = time[valid_mask]
            y_valid = ibi[valid_mask]
            
            kind = 'cubic' if len(t_valid) > 3 else 'linear'
            f_interp = interp1d(t_valid, y_valid, kind=kind, fill_value="extrapolate")
            new_ibi[outliers] = f_interp(time[outliers])

    return time, new_ibi
