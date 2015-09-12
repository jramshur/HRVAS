## Program Description:

HRVAS is a complete and self-contained heart rate variability analysis software     (HRVAS) package. HRVAS offers several preprocessing options. HRVAS offers time-domeain, freq-domain, time-frequency, and nonlinear HRV analysis. All results can be exported to an Excel file. For processing many files HRVAS offers a bach processing feature. All settings/options can be saved to a .mat file and reloaded for future HRV analysis. Upon starting HRVAS all previously used settings/options are loaded.

![](https://raw.githubusercontent.com/wiki/jramshur/HRVAS/images/TF-Waterfall.png)

## Wiki:

* [Home][home]
* [Installation][install]
* [Quick Start Guide][quickstart]
* [Misc. Info][misc]
* [HRV Analysis & Preprocessing][analysis]
  * [IBI Extraction][ibi]
  * [Preprocessing][pre]
  * [Time-Domain Analysis][time]
  * [Freq-Domain Analysis][freq]
  * [Nonlinear Analysis][nl]
  * [Time-Freq Analysis][tf]

[home]: https://github.com/myproject/wiki/Home
[install]: https://github.com/myproject/wiki/Technical-documentation
[quickstart]: https://github.com/myproject/wiki/User-manual
[misc]: https://github.com/myproject/wiki/Home
[analysis]: https://github.com/myproject/wiki/Home
[ibi]: https://github.com/myproject/wiki/Home
[pre]: https://github.com/myproject/wiki/Home
[time]: https://github.com/myproject/wiki/Home
[freq]: https://github.com/myproject/wiki/Home
[nl]: https://github.com/myproject/wiki/Home
[tf]: https://github.com/myproject/wiki/Home

## MATLAB Toolbox Dependencies:

    1. Signal Processing Toolbox (used for PSD estimates)
    2. Wavelet Toolbox (used for wavelet and wavelet packet detrending)
    3. Curvefitting Toolbox (only needed if using the "smooth" function for detrending)

## Contact Information:
    
    John T. Ramshur, PhD
    jramshur@gmail.com
    Project was done at:
    University of Memphis
    Department of Biomedical Engineering
    Memphis, TN
    
    jramshur@memphis.edu

## License Information:

Copyright (C) 2010, John T. Ramshur

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.