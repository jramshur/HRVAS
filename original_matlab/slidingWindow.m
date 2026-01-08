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

function [idx]=slidingWindow(s,winSize,overlap,method)
%windowArray - Seperates the input array s into smaller segments/windows 
%with %lengths of winSize. winSize can be either in units of time or 
%samples. If winSize is given in units of time the first column of the
%input array must containg time and method should be set to a value of 1. 
%
%INPUTS:
%   s: input array OR length of array. If outputing segs or using the time
%       methods, the 1st dim must contain time values.
%   winSize: size of segments to return
%   method: method of segmenting array (0=by samples, 1=by time)
%   overlap: amount that segments/windows overlap. 
%   flagCenters: decides whether to output center of windows instead of
%   beginning
%
%OUTPUTS:
%   idx: 2dim array that contains the start and end of each segment/window
%   centers: array containg locations of center of windows (useful when
%   using the time method)
%
%EXAMPLES:
%   1. Seperate input using window size of 100 seconds and overlap
%   of 50 seconds.
%   idx=slidingWindow(input,100,50,1);
%
%   2. Seperate input using window size of 128 samples and overlap
%   of 64 samples.
%   idx=slidingWindow(input,128,64,0);
%
%   3. Seperate input using window size of 128 samples and overlap
%   of 64 samples. Also outputs a cell array containing the actual segments
%   [idx, segs]=slidingWindow(input,128,64,0,1);


%Check inputs
if nargin<5
    flagCenters=false;
    c=[];
    %includeSeg=0;
elseif nargin<4
    overlap=0;
    includeSeg=0;
elseif nargin<3
    overlap=0;
    method=0;
    includeSeg=0;
elseif nargin<3
    error('slidingWindow: Too few input arguments.')
    return;
end

%check inputs
if overlap>=winSize
    error('slidingWindow: overlap cannot be >= winSize.')
end

[m,n]=size(s);
if (m==1) && (n==1) && (method==1)
    error('slidingWindow: Invalid input array for this windowing method.')
    return;
end

if (m==1) && (n==1)
    N=s;
%     if includeSeg
%         warning('SlidingWindow: Cannot output segs if input is scalar');
%     end
    includeSeg=false;
else
    N=length(s);
end

if method==1 %segment/window data based on time
    %don't know how many segments there will be...so assume no
    %more than N/2
    nSeg=floor(N/2); 
    cnt=0; i=0; iStart=1; iNext=1; flag=true;
    idx=zeros(nSeg,2); %preallocate idx array
    s(:,1)=s(:,1)-s(1,1); %offset all to make 1st time point = 0
    %if overlap is zero use this method to get win limits...faster
    if overlap == 0 
        t=s(:,1); %time
        b=diff(floor(t./5)); %
        b=find(b==1); %locations of the end of all windows
        
        iEnd=b;
        iStart=[1;b+1];
        
        idx=[iStart(1:end-1),iEnd];
        
    else %overlap > 0 ... use loops
    
        while i<=N-1
            i=i+1;
            t=s(i,1)-s(iStart,1); %add time values
            if flag && ((winSize-t)<=overlap)
                iNext=i;          
                flag=false;                        
            elseif t>=winSize
                cnt=cnt+1;
                idx(cnt,:)=[iStart i-1];
                i=iNext-1;
                iStart=iNext;           
                flag=true;                
            end         
        end    
        idx(cnt+1:end,:)=[];%remove extra zeros created during preallocation
    end
else %segment/window data based on samples
    
    iStart = 1:(winSize-overlap):(N-winSize+1);
    iEnd = iStart + (winSize-1);
    nseg = length(iStart);
        
    idx=[iStart;iEnd]';

end

% if includeSeg
%     segs=cell(size(idx,1));
%     for i=1:size(idx,1)
%         segs{i}=s(idx(i,1):idx(i,2));%code here for outputing
%     end
% end


end