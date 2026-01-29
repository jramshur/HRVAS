import numpy as np
import pytest
from hrvas.analysis.time_domain import calculate_time_domain_report

def test_time_domain_report_structure():
    # Generate synthetic IBI data: 60 BPM (1s intervals) with small noise to create histograms
    np.random.seed(42)
    # 300 beats ~ 5 minutes
    ibi = np.random.normal(loc=1.0, scale=0.05, size=300)
    ibi = np.clip(ibi, 0.5, 1.5) # Ensure valid range
    
    report = calculate_time_domain_report(ibi)
    
    # Check all fields exist and are of correct type
    assert isinstance(report.mean_nni, float)
    assert isinstance(report.sdnn, float)
    assert isinstance(report.mean_hr, float)
    assert isinstance(report.sd_hr, float)
    assert isinstance(report.rmssd, float)
    assert isinstance(report.nn50, int)
    assert isinstance(report.pnn50, float)
    assert isinstance(report.sdnni, float)
    assert isinstance(report.triangular_index, float)
    
    # Check Histogram Data Presence
    assert report.ibi_histogram_counts is not None
    assert report.ibi_histogram_bins is not None
    assert len(report.ibi_histogram_counts) == len(report.ibi_histogram_bins) - 1
    
    assert report.hr_histogram_counts is not None
    assert report.hr_histogram_bins is not None
    assert len(report.hr_histogram_counts) == len(report.hr_histogram_bins) - 1
    
    # Basic sanity checks
    assert report.mean_hr > 50 and report.mean_hr < 70
    assert report.mean_nni > 900 and report.mean_nni < 1100

def test_time_domain_report_hr_histogram():
    # HR = 60 constant
    ibi = np.ones(100)
    report = calculate_time_domain_report(ibi, hr_bin_width=1.0)
    
    # Expect all in one bin around 60
    # Bins might be [60, 61] or [59.5, 60.5]
    # Counts should sum to 100
    assert np.sum(report.hr_histogram_counts) == 100
    
    # For constant input of 60, the bins should encompass 60
    assert report.hr_histogram_bins[0] <= 60
    assert report.hr_histogram_bins[-1] >= 60

def test_time_domain_report_defaults():
    # Test empty/minimal defaults handling if robust, but here simple valid input
    ibi = np.array([0.8, 0.8, 0.8])
    report = calculate_time_domain_report(ibi)
    assert report.mean_hr == 75.0
    # Histograms should be generated even for small data
    assert report.hr_histogram_counts is not None
