from typing import Tuple

import numpy as np
import scipy.sparse as sp
from scipy.interpolate import interp1d
from scipy.sparse.linalg import spsolve
from numpy.typing import NDArray

def smoothness_priors_detrend(
    time: NDArray[np.float64],
    ibi: NDArray[np.float64],
    lambda_param: float = 500.0,
    sampling_rate: float = 4.0
) -> Tuple[NDArray[np.float64], NDArray[np.float64]]:
    """
    Detrend using Smoothness Priors (Tarvainen et al., 2002).
    Requires resampling to a regular grid.
    """
    t = np.asarray(time)
    y = np.asarray(ibi)
    
    # 1. Resample to regular grid
    t_start, t_end = t[0], t[-1]
    num_points = int((t_end - t_start) * sampling_rate)
    t_reg = np.linspace(t_start, t_end, num_points)
    
    f_interp = interp1d(t, y, kind='cubic', fill_value="extrapolate")
    y_reg = f_interp(t_reg)
    
    # 2. Apply method
    T = len(y_reg)
    I = sp.eye(T)
    data = np.ones((T, 3)) * np.array([1, -2, 1])
    D2 = sp.spdiags(data.T, [0, 1, 2], T - 2, T)
    
    A = I + (lambda_param**2) * (D2.T @ D2)
    trend_reg = spsolve(A, y_reg)
    
    # 3. Resample trend back
    f_trend_interp = interp1d(t_reg, trend_reg, kind='cubic', fill_value="extrapolate")
    trend = f_trend_interp(t)
    
    return y - trend, trend
