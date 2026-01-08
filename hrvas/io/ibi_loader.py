import pandas as pd
import numpy as np
from pathlib import Path
from typing import Union, Optional

def load_ibi(file_path: Union[str, Path], header_row: Optional[int] = 0) -> pd.DataFrame:
    """
    Load an IBI (Inter-Beat Interval) file.
    
    Supports:
    - CSV files with 'Time' and 'IBI' columns (header=0)
    - CSV files without header (assumes col 0=Time or incremental, col 1=IBI)
    
    Args:
        file_path: Path to the input file.
        header_row: Row number of the header, or None if no header.
    
    Returns:
        pd.DataFrame: DataFrame with columns ['Time', 'IBI']. 
                      'Time' in seconds, 'IBI' in seconds.
    """
    path = Path(file_path)
    if not path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")
        
    # Attempt to read
    try:
        # First pass: try reading with pandas default
        df = pd.read_csv(file_path, header=header_row)
        
        # Normalize columns
        # Case 1: Standard 'Time', 'IBI' headers exist
        clean_cols = [c.lower() for c in df.columns]
        if 'time' in clean_cols and 'ibi' in clean_cols:
            # Rename for consistency
            rename_map = {old: new for old, new in zip(df.columns, clean_cols)}
            df = df.rename(columns=rename_map)
            df = df.rename(columns={'time': 'Time', 'ibi': 'IBI'})
            
        # Case 2: No header or unknown headers, but 2 columns
        elif len(df.columns) == 2:
            df.columns = ['Time', 'IBI']
            
        # Case 3: 1 Column (IBI only) -> Generate Time
        elif len(df.columns) == 1:
            df.columns = ['IBI']
            # Create cumulative time from IBI
            df['Time'] = df['IBI'].cumsum()
            # Reorder
            df = df[['Time', 'IBI']]
            
    except Exception as e:
        raise ValueError(f"Error parsing IBI file: {e}")
        
    return df[['Time', 'IBI']]
