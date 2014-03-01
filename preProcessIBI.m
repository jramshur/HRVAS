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

function [dibi,nibi,trend,art]=preProcessIBI(ibi, varargin)
% preProcessIBI: detects ectopic IBI, corrects ectopic IBI, and then 
% detrends IBI
%
% TODO: build function description and usage

    %% PARSE INPUTS
    p = inputParser;   % Create instance of inputParser class.
    p.addRequired('ibi', @(x)size(x,1)>1);
    %Detect/Locate artifacts settings
    p.addParamValue('locateMethod', {}, @iscell);
    p.addParamValue('locateInput', [], @isnumeric);
    %Correction/replace artifacts
    p.addParamValue('replaceMethod', 'None', ...
        @(x)any(strcmpi(x,{'none','remove','mean','spline', ...
        'median','priors'})));
    p.addParamValue('replaceInput', 5, @(x)mod(x,1)==0);
    %Detrend IBI
    p.addParamValue('detrendMethod', 'none', ...
        @(x)any(strcmpi(x,{'none','wavelet','matlab smooth','smooth', ...
        'polynomial', 'wavelet packet','priors','smothness priors'})));
    p.addParamValue('smoothMethod', 'moving', ...
        @(x)any(strcmpi(x,{'moving','lowess','loess','sgolay', ...
        'rlowess','rloess'})));
    p.addParamValue('smoothSpan', 5, @(x)x>0 && mod(x,1)==0);
    p.addParamValue('smoothDegree', 0.01, @(x)x>0);
    p.addParamValue('polyOrder', 1, @(x)x>0 && x<4 && mod(x,1)==0);
    p.addParamValue('waveletType', 'db3', @ischar);
    p.addParamValue('waveletLevels', 6, @(x)x>0 && mod(x,1)==0);
    p.addParamValue('lambda', 500, @(x)x>0 && mod(x,1)==0);    
    %other
    p.addParamValue('resampleRate', 4, @(x)x>0 && mod(x,1)==0);
    p.addParamValue('meanCorrection', false, @islogical);
    p.parse(ibi, varargin{:});
    opt=p.Results;
    
    %% correct ectopic ibi
    [nibi,art]=correctEctopic(ibi,opt);
    
    %% Detrending
    [dibi,nibi,trend]=detrendIBI(nibi,opt);
        
end

function [nibi,art]=correctEctopic(ibi,opt)
    y=ibi(:,2);
    t=ibi(:,1);
    %locate ectopic
    if any(cell2mat(strfind(lower(opt.locateMethod),'percent')))
        i=find(ismember(opt.locateMethod, 'percent')==1);
        artPer=locateOutliers(t,y,'percent',opt.locateInput(i));
    else
        artPer=false(size(y,1),1);
    end
    if any(cell2mat(strfind(lower(opt.locateMethod),'sd')))
        i=find(ismember(opt.locateMethod, 'sd')==1);
        artSD=locateOutliers(t,y,'sd',opt.locateInput(i));
    else
        artSD=false(size(y,1),1);
    end
    if any(cell2mat(strfind(lower(opt.locateMethod),'median')))
        i=find(ismember(opt.locateMethod, 'median')==1);
        artMed=locateOutliers(t,y,'median',opt.locateInput(i));
    else
        artMed=false(size(y,1),1);
    end
    art=artPer | artSD | artMed; %combine all logical arrays    
    
    %replace ectopic
     switch lower(opt.replaceMethod)
        case 'mean'
            [y t]=replaceOutliers(t,y,art,'mean',opt.replaceInput);
        case 'median'
            [y t]=replaceOutliers(t,y,art,'median',opt.replaceInput);
        case 'spline'
            [y t]=replaceOutliers(t,y,art,'cubic');
        case 'remove'
            [y t]=replaceOutliers(t,y,art,'remove');            
        otherwise %none
            %do nothing
     end
    
     nibi=[t,y];
end

function [dibi,nibi,trend]=detrendIBI(ibi,opt)
    y=ibi(:,2);
    t=ibi(:,1);
    % preallocate memory and create default trend of 0.
    nibi=[t,y];
    trend=zeros(length(y),2);
    trend(:,1)=t; %time values    
    
    meanIbi=mean(y);
    switch lower(opt.detrendMethod)
        case 'wavelet'                   
            % Perform wavelet decomposition
            [c,l] = wavedec(y,opt.waveletLevels,opt.waveletType);
            % Reconstruct approximation at lowest freq level,
            % from the wavelet decomposition structure [c,l].
            trend(:,2) = wrcoef('a',c,l,opt.waveletType,opt.waveletLevels);       
        case {'smooth','matlab smooth'} %smooth detrend
            switch lower(opt.smoothMethod)
                case {'loess','lowess'} % use % not # of points
                    span=opt.smoothSpan/100; %convert to decimal percent
                    trend(:,2)=smooth(t,y,span,opt.smoothMethod, ...
                        opt.smoothDegree);
                otherwise
                    span=opt.SmoothSpan; %otherwise us number of points
                    trend(:,2)=smooth(t,y,span,opt.smoothMethod);
            end
        case 'polynomial' %linear detrend
            %center and normalize t vals to satisfy polyfit warning
            t2=(t-mean(t))./std(t);
            %fit
            [p,S]= polyfit(t2,y,opt.polyOrder);
            trend(:,2) = polyval(p,t2);
        case 'wavelet packet' %wavelet packet detrend                
            % WARNING: this code only works for signals sampled at 4 Hz.
            % ds = detrended signal
            % w = wavelet object
            % S =size of the coefficients at nodes which will be made
            %   equal to zero to remove the trend
            fs=4;  %resample rate (4 Hz)
            t2 = ibi(1,1):1/fs:ibi(end,1);  %time values for interp.
            y2=interp1(ibi(:,1),ibi(:,2),t2,'spline')'; %interpolation
            w=wpdec(y2,8,'db12');
            w = wpjoin(w,[2;4;8;16;32;63;129]);
            S = read(w,'sizes',[261,63,2]);
            w = write(w,'cfs',261,zeros(S(1,1),S(1,2)),'cfs',63,...
                zeros(S(2,1),S(2,2)),'cfs',2,zeros(S(3,1),S(3,2)));
            ds = wprec(w); %detrended signal
            tmp=y2-ds; %trend
            %resample trend back to original time points
            trend(:,2)=interp1(t2,tmp,ibi(:,1),'spline')';            
        case {'priors','smothness priors'} %smoothness priors detrend
            %WARNING: cutoff freq depends on lambda and resample rate            
            fs=opt.resampleRate;  %resample rate
            t2 = t(1):1/fs:t(end); %time values for interp.
            y2=interp1(t,y,t2,'spline')'; %resample
            T=length(y2);
            lambda=opt.lambda;
            I=speye(T);
            D2=spdiags(ones(T-2,1)*[1 -2 1], [0:2], T-2, T);
            z_stat = (I - inv(I+lambda^2*D2'*D2))*y2; %detrened signal
            y2=y2-z_stat; %trend
            %resample trend back to original time points
            trend(:,2)=interp1(t2,y2,t,'spline')'; %interpolation
    end
    dibi=[t,y-trend(:,2)]; %detrended IBI

        %%% Note: After removing the trend, the mean value of the ibi
        % series is near zero and some of the artifact detection methods 
        % detect two many outlers due to a mean near zero
        % Solution: shift detrended ibi back up to it's orignal mean
        % by adding orignal mean to detrended ibi.                        
         if opt.meanCorrection
             dibi(:,2) = dibi(:,2) + meanIbi; % see note above
         end  
end