%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) 2010, John T. Ramshur, jramshur@gmail.com
% 
% This file is part of HRVAS
%
% HRVAS is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% HRVAS is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with HRVAS.  If not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [y2,t2] = replaceOutliers(t,y,outliers, method, opt1, opt2)
%replaceOutliers: replaces artifacts/outliers from data series
%
%Inputs:    t = time
%           y = ibi values
%           outliers = logical array of outliers. 0=normal, 1=outlier
%           method = artifact replacement method to use.
%   methods:    'remove' = Outliers are removed
%               'mean' = Outliers are replaced with mean value from 
%                        nearest +- m ibi values.
%               'spline' = Outliers are replaced by cubic spline
%                          interpolation
%               'median' = Outliers are replaced with median value from
%                          nearest +- m ibi values.
%Outputs:   t2, y2 = arrays with replaced artifacts
%Examples: 
%   remove outliers from ibi series
%       [t2 y2] = replaceOutlers(t,y, outlierArray,'remove')

    
    if nargin < 3
        error('Not enough input arguments')
    elseif nargin < 4
        opt1=nan;
        opt2=nan;
    elseif nargin < 5
        opt2=nan;
    end        
    
    switch lower(method)
        case 'remove' %remove outliers
            y2=y;
            t2=t;
            y2(outliers,:) = [];
            t2(outliers,:) = [];
        case 'mean' %mean replacement            
            y2=y; %preallowcate newIBI series with old values
            t2=t;
            l=length(y); %number of ibi
            if ~isnan(opt1) %check input argument
                m=floor((opt1-1)/2); %calculate half window width
            end
            
            i=find(outliers); %index location of outliers                        
            i=(i(i>m+1 & i<l-m))'; %index location of outliers within range
            y(i)=nan;
            for n=i;
                tmpy=y(n-m:n+m);
                %replace with mean, ignore NaN values
                y2(n)=mean(tmpy(~isnan(tmpy))); 
            end
        case {'spline','cubic'} %Cubic spline replacment            
            y(outliers) = NaN; %replace outliers with nan
            t2=t;            
            y2=interp1(t2,y,t2,'spline','extrap');
        case 'median' %medianFilter
            y2=y; %preallowcate newIBI series with old values
            t2=t;
            l=length(y); %number of ibi
            if ~isnan(opt1) %check input argument
                m=floor((opt1-1)/2); %calculate half window width
            end
            
            i=find(outliers); %index location of outliers
            i=(i(i>m+1 & i<l-m))'; %index location of outliers within range
            y(i)=nan;
            for n=i;
                tmpy=y(n-m:n+m);
                %replace with median, ignore NaN values
                y2(n)=median(tmpy(~isnan(tmpy))); 
            end
            
            % Reference:
            % Thuraisingham, R. A. (2006). "Preprocessing RR interval time
            % series for heart rate variability analysis and estimates of
            % standard deviation of RR intervals." Comput.Methods
            % Programs Biomed.
        otherwise % do nothing
            y2=y;
            t2=t;            
    end

end