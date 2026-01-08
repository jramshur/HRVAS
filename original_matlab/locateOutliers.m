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

function outliers = locateOutliers(t,s, method, opt1, opt2)
%locateOutliers: locates artifacts/outliers from data series
%
%  Inputs:  s = array containg data series
%           method = artifact removal method to use.
%  methods: 'percent' = percentage filter: locates data > x percent diff
%                       than previous data point.               
%           'sd' = standard deviation filter: locates data > x stdev 
%                  away from mean.
%           'above' = Threshold filter: locates data > threshold value
%           'below' = Threshold filter: locates data < threshold value
%           'median' = median filter. Outliers are located.
%Outputs:   outliers = logical array of whether s is artifact/outlier or not
%                       eg. - [0 0 0 1 0], 1=artifact, 0=normal
%                       
%Examples:
%   Locate outliers with 20% percentage filter:
%       outliers = locateOutlers(s,'percent',0.2)
%   Locate outliers that are above a threshold of 0.5:
%       outliers = locateOutlers(s,'thresh','above',0.5)
%   Locate outliers with median filter:
%       outliers = locateOutlers(s,'median',4,5)
%


    %check inputs
    if nargin < 2
       error('Not enough input arguments')
       return;
    end
    [m,n]=size(s);    
    if ((m>n)&&(n>1)) || ((n>m)&&(m>1))
        error('Input array must be 1-dim')
        return;
    end
    if m<n
        s=s';
    end

    switch lower(method)
        case 'percent' %percentage filter
            outliers = percentFilter(s,opt1);
        case 'sd' %sd filter
            outliers = sdFilter(t,s,opt1);
        case 'thresh' %threshold filter
            outliers = threshFilter(s,opt1,opt2);
        case 'median' %median filter
            [outliers] = medianFilter(s,opt1);
        otherwise
            outliers=repmat(false,length(s),1);
    end
    
    outliers=logical(outliers); %convert to logical array
    
    function [outliers]=percentFilter(s,perLimit)
        
        if perLimit>1 
            perLimit=perLimit/100; %assume incorrect input and correct it.
        end
        
        outliers=false(length(s),1); %preallocate        
        pChange=abs(diff(s))./s(1:end-1); %percent chage from previous
        %find index of values where pChange > perLimit
        outliers(2:end) = (pChange >perLimit);
        
        % Reference: 
        % Clifford, G. (2002). "Characterizing Artefact in the Normal 
        % Human 24-Hour RR Time Series to Aid Identification and Artificial 
        % Replication of Circadian Variations in Human Beat to Beat Heart
        % Rate using a Simple Threshold."
        %
        % Aubert, A. E., D. Ramaekers, et al. (1999). "The analysis of heart 
        % rate variability in unrestrained rats. Validation of method and 
        % results." Comput Methods Programs Biomed 60(3): 197-213.
      
    end

    function [outliers]=sdFilter(t,s,sdLimit)
    %sdFilter: Locate outliers based on standard deviation
        
        s=detrend(s,'linear');
        
        mu = mean(s); %mean
        sigma = std(s); %standard deviation
      
        n = length(s);
        % Create a matrix of mean values by replicating the mu vector 
        % for n rows
        MeanMat = repmat(mu,n,1);
        % Create a matrix of standard deviation values by replicating 
        % the sigma vector for n rows
        SigmaMat = repmat(sigma,n,1);
        % Create a matrix of zeros and ones, where ones indicate the 
        % location of outliers
        outliers = abs(s-MeanMat) > sdLimit*SigmaMat;
    
        % Reference: 
        % Aubert, A. E., D. Ramaekers, et al. (1999). "The analysis of heart 
        % rate variability in unrestrained rats. Validation of method and 
        % results." Comput Methods Programs Biomed 60(3): 197-213.
    end

    function [outliers]=threshFilter(s,type,thresh)
    %threshFilter: Locate outliers based on a threshold

        n = length(s);
        % Create a matrix of thresh values by replicating the thresh 
        % for n rows
        thresh = repmat(thresh,n,1);
        % Create a matrix of zeros and ones, where ones indicate the %
        % location of outliers
        if strcmp(type,'above')        
            outliers = s > thresh;
        elseif strcmp(type,'below')
            outliers = s < thresh;        
        end
    end

    function [outliers]=medianFilter(s,t)
    %medianFilter: 
    %   s=input data array
    %   t=tau
    
        sM=median(s);
        med=median(abs(s-sM));
        D=abs(s-sM)./(1.483*med);
        outliers=D>t;                
        
        % Reference:
        % Thuraisingham, R. A. (2006). "Preprocessing RR interval time 
        % series for heart rate variability analysis and estimates of
        % standard deviation of RR intervals." 
        % Comput. Methods Programs Biomed.
    end

end