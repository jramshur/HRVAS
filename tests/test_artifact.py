import numpy as np
import pytest
from hrvas.preprocessing.artifact import (
    DetectionMethod, 
    ReplacementMethod, 
    detect_outliers, 
    replace_outliers
)

def test_detect_outliers_percent():
    # 20% change detection
    ibi = np.array([1.0, 1.0, 1.5, 1.0, 1.0]) 
    time = np.arange(len(ibi))
    
    outliers = detect_outliers(ibi, method=DetectionMethod.PERCENT, limit=0.2)
    expected = np.array([False, False, True, True, False]) 
    
    np.testing.assert_array_equal(outliers, expected)

def test_detect_outliers_sd():
    # Mean=10, std=0 (roughly). With 20 present: mean=12, std=4
    ibi = np.array([10.0, 10.0, 20.0, 10.0, 10.0]) 
    
    # |20-12|=8 > 1.5*4=6 -> True
    outliers = detect_outliers(ibi, method=DetectionMethod.SD, limit=1.5)
    
    assert outliers[2] == True
    assert outliers[0] == False

def test_replace_outliers_mean():
    time = np.arange(5, dtype=float)
    ibi = np.array([1.0, 1.0, 100.0, 1.0, 1.0])
    outliers = np.array([False, False, True, False, False])
    
    # Window size 3: neighbors are 1.0 and 1.0. Mean = 1.0
    _, corrected = replace_outliers(
        time, ibi, outliers, 
        method=ReplacementMethod.MEAN, 
        window_size=3
    )
    
    assert corrected[2] == 1.0
    assert corrected[0] == 1.0

def test_replace_outliers_remove():
    time = np.arange(5, dtype=float)
    ibi = np.array([1.0, 1.0, 100.0, 1.0, 1.0])
    outliers = np.array([False, False, True, False, False])
    
    t_new, i_new = replace_outliers(
        time, ibi, outliers, 
        method=ReplacementMethod.REMOVE
    )
    
    assert len(i_new) == 4
    assert 100.0 not in i_new
