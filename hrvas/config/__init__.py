from dataclasses import dataclass, field
from typing import Optional

@dataclass
class TimeDomainConfig:
    pnn_threshold_ms: float = 50.0

@dataclass
class GeometricConfig:
    bin_width_ms: float = 7.8125 # 1/128s

@dataclass
class FrequencyDomainConfig:
    """
    Configuration for Frequency Domain Analysis.
    
    Attributes:
        interpolation_rate: Sampling rate in Hz for interpolating IBI series (default 4.0 Hz).
        window_size_s: Window size for Welch's method in seconds (default 256.0 s).
        overlap: Overlap ratio for Welch's method (0.0 to 1.0, default 0.5).
        nfft: Number of points for FFT. If None, uses next power of 2 of window size.
        vlf_band: Tuple of (low, high) frequency in Hz (default (0.0033, 0.04)).
        lf_band: Tuple of (low, high) frequency in Hz (default (0.04, 0.15)).
        hf_band: Tuple of (low, high) frequency in Hz (default (0.15, 0.40)).
    """
    interpolation_rate: float = 4.0
    window_size_s: float = 256.0
    overlap: float = 0.5
    nfft: Optional[int] = None
    vlf_band: tuple = (0.0033, 0.04)
    lf_band: tuple = (0.04, 0.15)
    hf_band: tuple = (0.15, 0.40)


@dataclass
class HRVASConfig:
    time_domain: TimeDomainConfig = field(default_factory=TimeDomainConfig)
    geometric: GeometricConfig = field(default_factory=GeometricConfig)
    frequency_domain: FrequencyDomainConfig = field(default_factory=FrequencyDomainConfig)

    @classmethod
    def from_yaml(cls, path: str) -> "HRVASConfig":
        """Load configuration from a YAML file."""
        import yaml
        with open(path, 'r') as f:
            data = yaml.safe_load(f)
        
        # Helper to recursively load dicts into dataclasses
        td_data = data.get("time_domain", {})
        time_domain = TimeDomainConfig(**td_data)

        geo_data = data.get("geometric", {})
        geometric = GeometricConfig(**geo_data)

        fd_data = data.get("frequency_domain", {})
        frequency_domain = FrequencyDomainConfig(**fd_data)

        return cls(
            time_domain=time_domain,
            geometric=geometric,
            frequency_domain=frequency_domain
        )
