from dataclasses import dataclass
from typing import Dict, Optional

import numpy as np
from numpy.typing import NDArray


@dataclass
class TimeDomainResults:
    mean_nni: float
    sdnn: float
    rmssd: float
    pnn50: float
    nni_50: int
    mean_hr: float
    sd_hr: float
    min_hr: float
    max_hr: float


def calculate_standard_metrics(ibi: NDArray[np.float64], pnn_threshold_ms: float = 50.0) -> TimeDomainResults:
    """
    Calculate standard time-domain HRV metrics.

    Args:
        ibi: Array of Inter-Beat Intervals in seconds.
             IMPORTANT: These should be cleaned Normal-to-Normal Intervals (NNI),
             free of artifacts/ectopic beats, for valid HRV analysis.
        pnn_threshold_ms: Threshold for pNNx calculation in milliseconds (default 50ms).
                          If different from 50ms, the returned 'pnn50' field indicates 'pNNx'.

    Returns:
        TimeDomainResults object containing calculated metrics in milliseconds (except HR).
    """
    # Convert to milliseconds for standard reporting norms
    nni_ms = ibi * 1000.0
    
    # Basic Stats
    mean_nni = float(np.mean(nni_ms))
    sdnn = float(np.std(nni_ms, ddof=1)) # Use sample standard deviation (N-1)
    
    # RMSSD
    diff_nni = np.diff(nni_ms)
    rmssd = float(np.sqrt(np.mean(diff_nni ** 2)))
    
    # NNx and pNNx
    # Number of interval differences greater than threshold
    abs_diff = np.abs(diff_nni)
    nnx = np.sum(abs_diff > pnn_threshold_ms)
    pnnx = (nnx / len(diff_nni)) * 100.0 if len(diff_nni) > 0 else 0.0
    
    # Heart Rate Stats
    # HR = 60 / IBI(s)
    hr_values = 60.0 / ibi
    mean_hr = float(np.mean(hr_values))
    sd_hr = float(np.std(hr_values, ddof=1))
    min_hr = float(np.min(hr_values))
    max_hr = float(np.max(hr_values))
    
    return TimeDomainResults(
        mean_nni=mean_nni,
        sdnn=sdnn,
        rmssd=rmssd,
        pnn50=float(pnnx),
        nni_50=int(nnx),
        mean_hr=mean_hr,
        sd_hr=sd_hr,
        min_hr=min_hr,
        max_hr=max_hr
    )
