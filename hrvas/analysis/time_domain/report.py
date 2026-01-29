from dataclasses import dataclass
from typing import Optional

import numpy as np
from numpy.typing import NDArray

from .statistical import calculate_standard_metrics
from .geometric import calculate_geometric_metrics
from .segmentation import calculate_sdnni

@dataclass
class TimeDomainReport:
    """
    Comprehensive report of Time Domain HRV metrics.
    Matches the standard control GUI output.
    """
    # Statistical
    mean_nni: float
    sdnn: float
    mean_hr: float
    sd_hr: float
    rmssd: float
    nn50: int # NNx (default 50ms)
    pnn50: float # pNNx
    
    # Segmentation
    sdnni: float
    
    # Geometric
    triangular_index: float
    tinn: Optional[float]
    
    # Histograms (for visualization)
    ibi_histogram_counts: Optional[NDArray[np.float64]] = None
    ibi_histogram_bins: Optional[NDArray[np.float64]] = None
    hr_histogram_counts: Optional[NDArray[np.float64]] = None
    hr_histogram_bins: Optional[NDArray[np.float64]] = None


def calculate_time_domain_report(
    ibi: NDArray[np.float64],
    pnn_threshold_ms: float = 50.0,
    geometric_bin_width_ms: float = 7.8125, # 1/128 s
    segment_window_s: float = 300.0,
    hr_bin_width: float = 1.0 # 1 BPM
) -> TimeDomainReport:
    """
    Calculate all Time Domain metrics and generate a consolidated report.
    
    Args:
        ibi: Inter-Beat Intervals in seconds.
        pnn_threshold_ms: Threshold for pNNx (default 50ms).
        geometric_bin_width_ms: Bin width for IBI histogram (default 7.8125ms).
        segment_window_s: Window size for SDNNi (default 300s).
        hr_bin_width: Bin width for HR histogram in BPM.
        
    Returns:
        TimeDomainReport containing all metrics and histogram data.
    """
    # 1. Standard Statistical Metrics
    stats_res = calculate_standard_metrics(ibi, pnn_threshold_ms=pnn_threshold_ms)
    
    # 2. Geometric Metrics (includes IBI histogram)
    geom_res = calculate_geometric_metrics(ibi, bin_width_ms=geometric_bin_width_ms)
    
    # 3. SDNNi
    sdnni_val = calculate_sdnni(ibi, window_size_s=segment_window_s)
    
    # 4. HR Histogram
    # HR = 60 / IBI
    hr_values = 60.0 / ibi
    min_hr = np.floor(np.min(hr_values))
    max_hr = np.ceil(np.max(hr_values))
    
    # Create bins for HR (e.g., 1 BPM steps)
    hr_bins = np.arange(min_hr, max_hr + hr_bin_width, hr_bin_width)
    if len(hr_bins) < 2:
        # Fallback if range is too small
        hr_counts, hr_edges = np.histogram(hr_values, bins='auto')
    else:
        hr_counts, hr_edges = np.histogram(hr_values, bins=hr_bins)
        
    return TimeDomainReport(
        mean_nni=stats_res.mean_nni,
        sdnn=stats_res.sdnn,
        mean_hr=stats_res.mean_hr,
        sd_hr=stats_res.sd_hr,
        rmssd=stats_res.rmssd,
        nn50=stats_res.nni_50,
        pnn50=stats_res.pnn50,
        sdnni=sdnni_val,
        triangular_index=geom_res.triangular_index,
        tinn=geom_res.tinn,
        ibi_histogram_counts=geom_res.ibi_histogram_counts,
        ibi_histogram_bins=geom_res.ibi_histogram_bins,
        hr_histogram_counts=hr_counts,
        hr_histogram_bins=hr_edges
    )
