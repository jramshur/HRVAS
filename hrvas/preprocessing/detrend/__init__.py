from typing import Tuple

import numpy as np
from numpy.typing import NDArray

from .polynomial import DetrendMethod, polynomial_detrend
from .smoothness_priors import smoothness_priors_detrend
from .wavelet import wavelet_detrend


def detrend_ibi(
    time: NDArray[np.float64],
    ibi: NDArray[np.float64],
    method: DetrendMethod = DetrendMethod.SMOOTHNESS_PRIORS,
    lambda_param: float = 500.0,
    poly_order: int = 2,
    wavelet: str = 'db4',
    wavelet_level: int = 6,
    sampling_rate: float = 4.0
) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
    """
    Main entry point for detrending.
    Dispatches to specific strategy based on method enum.
    """
    # Ensure inputs
    time = np.asarray(time)
    ibi = np.asarray(ibi)
    
    if method == DetrendMethod.NONE:
        return ibi, np.zeros_like(ibi)
        
    elif method == DetrendMethod.POLYNOMIAL:
        return polynomial_detrend(time, ibi, poly_order=poly_order)
        
    elif method == DetrendMethod.SMOOTHNESS_PRIORS:
        return smoothness_priors_detrend(time, ibi, lambda_param=lambda_param, sampling_rate=sampling_rate)
        
    elif method == DetrendMethod.WAVELET:
        return wavelet_detrend(time, ibi, wavelet=wavelet, level=wavelet_level)
        
    else:
        raise ValueError(f"Unknown detrend method: {method}")

__all__ = ["DetrendMethod", "detrend_ibi", "polynomial_detrend", "smoothness_priors_detrend", "wavelet_detrend"]
