from dataclasses import dataclass
from typing import Tuple, Optional

import numpy as np
import scipy.integrate as integrate
from numpy.typing import NDArray


@dataclass
class GeometricResults:
    triangular_index: float
    tinn: Optional[float]


def calculate_geometric_metrics(
    ibi: NDArray[np.float64],
    bin_width_ms: float = 7.8125 # 1/128 seconds as per MATLAB/Standards
) -> GeometricResults:
    """
    Calculate Geometric HRV measures: HRV Triangular Index and TINN.
    
    Args:
        ibi: Array of Inter-Beat Intervals in seconds.
        bin_width_ms: Width of histogram bins in milliseconds (default 1/128 s = 7.8125ms).
        
    Returns:
        GeometricResults object containing triangular_index and tinn (in ms).
    """
    nni_ms = ibi * 1000.0
    
    # Range of data
    t_min = np.min(nni_ms)
    t_max = np.max(nni_ms)
    
    # Create bins
    # MATLAB: nBins=round(dt/binWidth)
    # We use explicit bin edges for histogram
    bins = np.arange(t_min, t_max + bin_width_ms, bin_width_ms)
    
    counts, edges = np.histogram(nni_ms, bins=bins)
    
    # 1. HRV Triangular Index
    # Total number of NN intervals / Number of NN intervals in the modal bin (max density)
    max_density = np.max(counts)
    if max_density == 0:
        return GeometricResults(triangular_index=0.0, tinn=0.0)
        
    triangular_index = len(nni_ms) / max_density
    
    # 2. TINN (Triangular Interpolation of NN Interval Histogram)
    # Algorithm matches MATLAB tinn function logic:
    # - Find peak bin (Mode)
    # - Iteratively optimize base width (M, N) of a triangle q(t)
    #   such that integral (D - q)^2 is minimized.
    # D is the histogram (counts).
    
    # Identify peak index
    # If multiple peaks, take mean index (MATLAB logic)
    peak_indices = np.where(counts == max_density)[0]
    peak_idx = int(np.round(np.mean(peak_indices)))
    
    # If peak is at boundaries, cannot compute TINN effectively (MATLAB returns NaN)
    n_bins = len(counts)
    if peak_idx == 0 or peak_idx == n_bins - 1:
        return GeometricResults(triangular_index=triangular_index, tinn=np.nan)
        
    # MATLAB Optimization Loop
    # Finds M (start) and N (end) of triangle base that minimizes squared error
    # Triangle peak is fixed at (x[peak_idx], D[peak_idx])
    # q(t) goes from 0 at M to Peak, then down to 0 at N.
    
    # We need centers of bins for x-axis? 
    # MATLAB uses `hist` which returns centers. `numpy.histogram` returns edges.
    # Let's approximate x centers.
    x_centers = (edges[:-1] + edges[1:]) / 2
    
    D = counts
    Y = D[peak_idx] # Height of triangle

    # Variable Mapping:
    # D: Histogram counts (distribution)
    # Y: Peak height of the histogram
    # M: Start index of the triangle base (left side)
    # N: End index of the triangle base (right side)
    
    min_error = float('inf')
    best_m, best_n = 0, n_bins - 1
    
    # MATLAB loops:
    # for m = (peak-1) down to 1
    #   for n = (peak+1) up to nBins
    
    # This double loop can be slow for large histograms (many bins).
    # However, NNI histograms aren't usually massive (range ~500-1500ms, width 8ms -> ~125 bins).
    # So Python loop is acceptable.
    
    # Pre-compute parts of q that are zero outside [m, n]? 
    # Error is sum((D-q)^2). Outside [m,n], q=0, so error is sum(D^2).
    # Inside, q is linear ramp.
    
    # Let's iterate as per MATLAB for exact replication of logic
    # (Checking all possible triangle bases)
    
    for m in range(peak_idx - 1, -1, -1):
        for n in range(peak_idx + 1, n_bins):
            # Construct q
            q = np.zeros_like(D, dtype=float)
            
            # Left ramp: 0 to Y
            # Indices from m to peak_idx (inclusive end for python slice?)
            # MATLAB: q(m:peaki)=linspace(0, Y, peaki-m+1)
            # Python: m through peak_idx
            len_left = peak_idx - m + 1
            q[m : peak_idx + 1] = np.linspace(0, Y, len_left)
            
            # Right ramp: Y to 0
            # MATLAB: q(peaki:n)=linspace(Y, 0, n-peaki+1)
            len_right = n - peak_idx + 1
            q[peak_idx : n + 1] = np.linspace(Y, 0, len_right)
            
            # Error metric: integral of squared difference
            # MATLAB: trapz((D-q).^2)
            # Simple sum of squares is often sufficient for discrete, otherwise trapz using step size 1 (bins)
            error = np.sum((D - q)**2)
            
            # If standardizing on trapz:
            # error = np.trapz((D - q)**2)
            
            if error < min_error:
                min_error = error
                best_m = m
                best_n = n
                
    # Calculate TINN width
    # TINN = Base width in ms = x[n] - x[m]
    tinn_ms = x_centers[best_n] - x_centers[best_m]
    
    return GeometricResults(triangular_index=triangular_index, tinn=tinn_ms)
