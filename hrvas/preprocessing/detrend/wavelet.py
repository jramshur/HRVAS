from typing import Tuple

import numpy as np
import pywt
from numpy.typing import NDArray

def wavelet_detrend(
    time: NDArray[np.float64],
    ibi: NDArray[np.float64],
    wavelet: str = 'db4',
    level: int = 6
) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
    """
    Detrend using Discrete Wavelet Transform.
    Assumes signal can be treated as uniformly sampled for the transform,
    which is standard practice in simple HRV detrending though technically inexact.
    """
    y = np.asarray(ibi)
    coeffs = pywt.wavedec(y, wavelet, level=level)
    
    # Reconstruct approximation (trend)
    coeffs_rec = [coeffs[0]] + [np.zeros_like(c) for c in coeffs[1:]]
    trend = pywt.waverec(coeffs_rec, wavelet)
    
    # Length adjustment
    if len(trend) > len(y):
        trend = trend[:len(y)]
    elif len(trend) < len(y):
        # This case is rare with wavedec/rec if levels are appropriate, 
        # but zero-padding is a safe fallback
        padding = np.zeros(len(y) - len(trend))
        trend = np.concatenate((trend, padding))
        
    return y - trend, trend
