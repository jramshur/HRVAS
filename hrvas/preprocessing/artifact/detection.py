from enum import Enum

import numpy as np
from numpy.typing import NDArray
from scipy.signal import detrend


class DetectionMethod(str, Enum):
    """Methods available for artifact detection."""
    PERCENT = "percent"
    SD = "sd"
    MEDIAN = "median"
    THRESHOLD_ABOVE = "threshold_above"
    THRESHOLD_BELOW = "threshold_below"


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
        limit: Threshold/limit for the detection method.
               - PERCENT: e.g. 0.2 means 20% change from previous beat.
               - SD: e.g. 3 means 3 standard deviations from mean (after detrending).
               - MEDIAN: e.g. 4 means 4 MAD-based z-score threshold (approx 4 SDs).
               - THRESHOLD_ABOVE: Absolute IBI value in seconds (e.g. 2.0s).
               - THRESHOLD_BELOW: Absolute IBI value in seconds (e.g. 0.3s).

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
