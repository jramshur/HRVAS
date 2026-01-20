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
class ArtifactLimit:
    enabled: bool = True
    threshold: float = 20.0

@dataclass
class ArtifactDetectionConfig:
    percent: ArtifactLimit = field(default_factory=lambda: ArtifactLimit(True, 20.0))
    std_dev: ArtifactLimit = field(default_factory=lambda: ArtifactLimit(True, 4.0))
    median: ArtifactLimit = field(default_factory=lambda: ArtifactLimit(False, 4.0))

@dataclass
class ArtifactReplaceConfig:
    method: str = "Remove"
    mean_val: float = 9.0
    median_val: float = 30.0

@dataclass
class DetrendingConfig:
    method: str = "Smoothness Priors"
    wavelet_type: str = "db"
    wavelet_param: int = 12
    wavelet_levels: int = 6
    smoothness_priors_lambda: float = 155.0

@dataclass
class PreprocessingConfig:
    artifact_detection: ArtifactDetectionConfig = field(default_factory=ArtifactDetectionConfig)
    artifact_replace: ArtifactReplaceConfig = field(default_factory=ArtifactReplaceConfig)
    detrending: DetrendingConfig = field(default_factory=DetrendingConfig)

@dataclass
class NonlinearConfig:
    sampen_r: float = 0.15
    sampen_m: int = 2
    dfa_n_min_max: tuple = (4, 64)
    dfa_break_point: int = 10

@dataclass
class HRVASConfig:
    time_domain: TimeDomainConfig = field(default_factory=TimeDomainConfig)
    geometric: GeometricConfig = field(default_factory=GeometricConfig)
    frequency_domain: FrequencyDomainConfig = field(default_factory=FrequencyDomainConfig)
    preprocessing: PreprocessingConfig = field(default_factory=PreprocessingConfig)
    nonlinear: NonlinearConfig = field(default_factory=NonlinearConfig)

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
        geometric = GeometricConfig()

        # --- Preprocessing ---
        pp_raw = data.get("ibi_preprocessing", {})
        
        # Artifacts
        art_det_raw = pp_raw.get("artifact_detection", {})
        ad_percent = art_det_raw.get("percent", {})
        ad_std = art_det_raw.get("std_dev", {})
        ad_median = art_det_raw.get("median", {})
        
        artifact_detection = ArtifactDetectionConfig(
            percent=ArtifactLimit(ad_percent.get("enabled", True), float(ad_percent.get("threshold", 20.0))),
            std_dev=ArtifactLimit(ad_std.get("enabled", True), float(ad_std.get("threshold", 4.0))),
            median=ArtifactLimit(ad_median.get("enabled", False), float(ad_median.get("threshold", 4.0)))
        )
        
        art_rep_raw = pp_raw.get("artifact_replace", {})
        artifact_replace = ArtifactReplaceConfig(
            method=art_rep_raw.get("method", "Remove"),
            mean_val=float(art_rep_raw.get("mean_val", 9.0)),
            median_val=float(art_rep_raw.get("median_val", 30.0))
        )
        
        det_raw = pp_raw.get("detrending", {})
        detrending = DetrendingConfig(
            method=det_raw.get("method", "Smoothness Priors"),
            wavelet_type=det_raw.get("wavelet_type", "db"),
            wavelet_param=int(det_raw.get("wavelet_param", 12)),
            wavelet_levels=int(det_raw.get("wavelet_levels", 6)),
            smoothness_priors_lambda=float(det_raw.get("smoothness_priors_lambda", 155.0))
        )
        
        preprocessing = PreprocessingConfig(
            artifact_detection=artifact_detection,
            artifact_replace=artifact_replace,
            detrending=detrending
        )
        
        # --- Nonlinear ---
        nl_raw = data.get("nonlinear", {})
        nl_sampen = nl_raw.get("sampen", {})
        nl_dfa = nl_raw.get("dfa", {})
        
        nonlinear = NonlinearConfig(
            sampen_r=float(nl_sampen.get("r", 0.15)),
            sampen_m=int(nl_sampen.get("m", 2)),
            dfa_n_min_max=tuple(nl_dfa.get("n_min_max", (4, 64))),
            dfa_break_point=int(nl_dfa.get("break_point", 10))
        )

        return cls(
            time_domain=time_domain,
            geometric=geometric,
            frequency_domain=frequency_domain,
            preprocessing=preprocessing,
            nonlinear=nonlinear
        )
