import numpy as np
import pandas as pd
import argparse
from pathlib import Path

def generate_synthetic_ibi(
    duration_sec=300, 
    mean_hr_bpm=60, 
    resp_rate_hz=0.25, 
    resp_amp_ms=50, 
    noise_amp_ms=10, 
    artifacts=0
):
    """
    Generate synthetic Inter-Beat Interval (IBI) series with respiratory sinus arrhythmia (RSA).
    
    Args:
        duration_sec: Total duration in seconds.
        mean_hr_bpm: Mean heart rate in beats per minute.
        resp_rate_hz: Respiratory frequency (RSA) in Hz.
        resp_amp_ms: Amplitude of RSA modulation in milliseconds.
        noise_amp_ms: Amplitude of random Gaussian noise in ms.
        artifacts: Number of ectopic beats to insert (randomly).
    
    Returns:
        pd.DataFrame: columns ['Time', 'IBI']
    """
    # Base IBI in seconds
    mean_ibi_s = 60.0 / mean_hr_bpm
    
    # Estimate number of beats
    n_beats = int(duration_sec / mean_ibi_s)
    
    # Generate time vector (approximate) - this will be corrected by cumsum
    # but for the RSA sine wave we need a continuous time base.
    # We'll generate beats iteratively to be more realistic?
    # For testing PSD, a sampled sine wave added to mean is sufficient.
    
    # 1. Generate indices
    t_approx = np.arange(n_beats) * mean_ibi_s
    
    # 2. Generate RSA component (Sine wave modulation)
    # IBI varies: mean + amp * sin(2*pi*f*t)
    rsa = (resp_amp_ms / 1000.0) * np.sin(2 * np.pi * resp_rate_hz * t_approx)
    
    # 3. Add Noise
    noise = np.random.normal(0, noise_amp_ms / 1000.0, n_beats)
    
    # 4. Construct IBI series
    ibi_vals = mean_ibi_s + rsa + noise
    
    # 5. Insert Artifacts (outliers)
    if artifacts > 0:
        indices = np.random.choice(n_beats, artifacts, replace=False)
        for idx in indices:
            # Randomly shorten or lengthen by 20-50%
            factor = np.random.choice([0.5, 1.5]) 
            ibi_vals[idx] *= factor

    # 6. Construct Time axis (cumsum)
    time_vals = np.cumsum(ibi_vals)
    
    df = pd.DataFrame({
        'Time': time_vals,
        'IBI': ibi_vals
    })
    
    return df

def main():
    parser = argparse.ArgumentParser(description="Generate synthetic IBI data for HRVAS validation.")
    parser.add_argument("--out", type=str, default="tests/fixtures/sample_data/synthetic_sine.ibi", help="Output file path")
    parser.add_argument("--duration", type=int, default=300, help="Duration in seconds")
    parser.add_argument("--bpm", type=int, default=60, help="Mean HR in BPM")
    parser.add_argument("--freq", type=float, default=0.25, help="RSA Frequency in Hz")
    parser.add_argument("--artifacts", type=int, default=0, help="Number of artifacts to insert")
    
    args = parser.parse_args()
    
    # Ensure directory exists
    output_path = Path(args.out)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    print(f"Generating synthetic IBI data...")
    print(f"Parameters: {args.duration}s, {args.bpm} BPM, {args.freq} Hz, {args.artifacts} artifacts")
    
    df = generate_synthetic_ibi(
        duration_sec=args.duration,
        mean_hr_bpm=args.bpm,
        resp_rate_hz=args.freq,
        artifacts=args.artifacts
    )
    
    # Save as CSV (simulating IBI file) without header to match some simple formats, 
    # or with header if sticking to standard CSV. 
    # HRVAS Matlab read various formats. Let's use a standard CSV with header for Python 2.0 default,
    # but we can also support the simple "Time, IBI" format.
    df.to_csv(output_path, index=False)
    
    print(f"Saved to {output_path}")
    print(df.head())

if __name__ == "__main__":
    main()
