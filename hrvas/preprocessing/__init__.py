from .artifact import DetectionMethod, ReplacementMethod, detect_outliers, replace_outliers
from .detrend import DetrendMethod, detrend_ibi

__all__ = [
    "DetectionMethod", 
    "ReplacementMethod", 
    "detect_outliers", 
    "replace_outliers",
    "DetrendMethod",
    "detrend_ibi"
]
