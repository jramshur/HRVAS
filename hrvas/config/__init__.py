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
    window_size: int = 1024  # Points (default 256s * 4Hz = 1024)
    overlap: int = 512       # Points (default 50% of 1024)
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
        
        # --- Time Domain ---
        td_raw = data.get("time_domain", {})
        time_domain = TimeDomainConfig(
            pnn_threshold_ms=float(td_raw.get("pnnx_ms", 50.0))
        )

        # --- Frequency Domain ---
        fd_raw = data.get("freq_domain", {})
        bands = fd_raw.get("frequency_bands", {})
        interp = fd_raw.get("ibi_interpolation", {})
        welch = fd_raw.get("welch_options", {})
        
        # Calculate derived values
        rate = float(interp.get("rate_hz", 4.0))

        frequency_domain = FrequencyDomainConfig(
            interpolation_rate=rate,
            window_size=int(welch.get("window_width_pts", 1024)),
            overlap=int(welch.get("window_overlap_pts", 512)),
            nfft=int(fd_raw.get("points_in_psd", 512)),
            vlf_band=tuple(bands.get("vlf_hz", (0.0033, 0.04))),
            lf_band=tuple(bands.get("lf_hz", (0.04, 0.15))),
            hf_band=tuple(bands.get("hf_hz", (0.15, 0.40)))
        )

        # --- Geometric ---
        # Did not appear in settings.mat or screenshot explicit list, defaulting
        geometric = GeometricConfig()

        # TODO: Parse 'ibi_preprocessing', 'nonlinear', 'time_freq' 
        # when we add those Dataclasses to HRVASConfig.

        return cls(
            time_domain=time_domain,
            geometric=geometric,
            frequency_domain=frequency_domain
        )
