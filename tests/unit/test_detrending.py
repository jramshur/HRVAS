import numpy as np
import pytest
from hrvas.preprocessing.detrend import DetrendMethod, detrend_ibi

def test_detrend_polynomial():
    # Create linear trend y = 2t + 1
    t = np.linspace(0, 10, 100)
    trend = 2 * t + 1
    noise = np.random.normal(0, 0.1, 100)
    y = trend + noise
    
    # Detrend using polynomial order 1
    y_detrended, estimated_trend = detrend_ibi(t, y, method=DetrendMethod.POLYNOMIAL, poly_order=1)
    
    # Check if estimated trend is close to true trend
    # RMSE should be small
    rmse = np.sqrt(np.mean((estimated_trend - trend)**2))
    assert rmse < 1.0  # Allow some fitting error due to noise
    
    # Check if detrended signal is centered around 0
    assert np.abs(np.mean(y_detrended)) < 0.2

def test_detrend_smoothness_priors():
    # Low frequency trend + High frequency signal
    t = np.linspace(0, 50, 200) # 50 seconds, 4Hz
    trend = 0.5 * np.sin(0.1 * t) # Slow wave
    signal = 0.5 * np.sin(2 * np.pi * 1.0 * t) # 1Hz heart rate variability
    y = trend + signal
    
    # Detrend
    y_detrended, estimated_trend = detrend_ibi(t, y, method=DetrendMethod.SMOOTHNESS_PRIORS, lambda_param=500)
    
    # The trend should capture the slow wave
    correlation = np.corrcoef(estimated_trend, trend)[0, 1]
    assert correlation > 0.95
    
    # Detrended signal should match original signal
    correlation_sig = np.corrcoef(y_detrended, signal)[0, 1]
    assert correlation_sig > 0.95

def test_detrend_none():
    t = np.arange(10)
    y = np.arange(10)
    y_det, trend = detrend_ibi(t, y, method=DetrendMethod.NONE)
    
    np.testing.assert_array_equal(y_det, y)
    np.testing.assert_array_equal(trend, np.zeros_like(y))

def test_detrend_wavelet():
    # Use composed signal
    t = np.linspace(0, 10, 256) # Power of 2 length often helps wavelets, though not strictly required for PyWavelets
    trend = 2.0 * np.sin(0.5 * t)
    signal = 0.5 * np.cos(20 * t)
    y = trend + signal
    
    y_det, est_trend = detrend_ibi(t, y, method=DetrendMethod.WAVELET)
    
    # Check correlation with true trend
    correlation = np.corrcoef(est_trend, trend)[0, 1]
    assert correlation > 0.90

