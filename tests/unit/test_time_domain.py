import numpy as np
import pytest
from hrvas.analysis.time_domain import (
    calculate_standard_metrics,
    calculate_sdann,
    calculate_sdnni,
    calculate_geometric_metrics
)

def test_standard_metrics_constant():
    # Constant IBI = 1.0s (60 BPM)
    # Mean HR = 60, SDNN=0, RMSSD=0, pNN50=0
    ibi = np.ones(100)
    results = calculate_standard_metrics(ibi)
    
    assert results.mean_nni == 1000.0
    assert results.mean_hr == 60.0
    assert results.sdnn == 0.0
    assert results.rmssd == 0.0
    assert results.pnn50 == 0.0

def test_standard_metrics_synthetic():
    # Alternating 1.0s and 1.1s
    # Diff = 0.1s = 100ms > 50ms -> pNN50 should be 100% (or near)
    # RMSSD = 100ms
    ibi = np.array([1.0, 1.1] * 50)
    results = calculate_standard_metrics(ibi)
    
    assert results.mean_nni == 1050.0
    assert np.isclose(results.rmssd, 100.0)
    assert np.isclose(results.pnn50, 100.0)
    
def test_segmentation_measures():
    # 10 minutes of data (600s)
    # First 5 mins: Constant 1.0s (SDNN=0)
    # Second 5 mins: Alternating 1.0/1.1 (SDNN ~ 50ms)
    
    # 300 beats @ 1.0s, then ~270 beats alternating
    part1 = np.ones(300) # 300s
    part2 = np.array([1.0, 1.1] * 150) # 315s approx
    ibi = np.concatenate([part1, part2])
    
    # SDANN: SD of Means. Mean1=1000, Mean2=1050. SD of [1000, 1050] is approx 35.35
    sdann = calculate_sdann(ibi, window_size_s=300)
    assert np.isclose(sdann, 35.355, atol=1.0)
    
    # SDNNi: Mean of SDs. SD1=0, SD2=np.std([1000, 1100])=50. Mean is 25.
    sdnni = calculate_sdnni(ibi, window_size_s=300)
    assert np.isclose(sdnni, 25.0, atol=1.0)
    
def test_geometric_measures_triangle():
    # Construct a perfect triangle distribution (0 to 2000 ms)
    # Peak at 1000ms.
    # We can simulate this by generating random numbers with triangular distribution
    np.random.seed(42)
    nni_ms = np.random.triangular(500, 1000, 1500, 10000)
    ibi = nni_ms / 1000.0
    
    # Triangular Index estimate: Total / Max.
    # For a theoretical triangle, max height depends on bin width.
    # This test primarily checks code runs and returns reasonable positive numbers.
    # Triangular Index estimate: Total / Max.
    # For a theoretical triangle, max height depends on bin width.
    # This test primarily checks code runs and returns reasonable positive numbers.
    results = calculate_geometric_metrics(ibi)
    
    assert results.triangular_index > 0
    assert results.tinn > 0
    # Base width of triangular distribution is 1500-500 = 1000.
    # TINN should approximate this
    assert 800 < results.tinn < 1200
