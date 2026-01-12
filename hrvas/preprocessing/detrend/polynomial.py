from enum import Enum
from typing import Tuple

import numpy as np
from numpy.typing import NDArray

class DetrendMethod(str, Enum):
    """Methods available for detrending IBI series."""
    NONE = "none"
    POLYNOMIAL = "polynomial"
    SMOOTHNESS_PRIORS = "smoothness_priors"
    WAVELET = "wavelet"

def polynomial_detrend(
    time: NDArray[np.float64],
    ibi: NDArray[np.float64],
    poly_order: int = 2
) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
    """Detrend using polynomial fit."""
    coeffs = np.polyfit(time, ibi, poly_order)
    trend = np.polyval(coeffs, time)
    return ibi - trend, trend
