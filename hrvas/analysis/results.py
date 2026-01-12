from dataclasses import dataclass
from typing import Optional

from hrvas.analysis.time_domain.statistical import TimeDomainResults
from hrvas.analysis.time_domain.geometric import GeometricResults


@dataclass
class HRVMetrics:
    """
    Container for all HRV analysis results.
    """
    time_domain: Optional[TimeDomainResults] = None
    geometric: Optional[GeometricResults] = None
    # frequency_domain: Optional[FrequencyDomainResults] = None # To be implemented
    # nonlinear: Optional[NonLinearResults] = None # To be implemented
