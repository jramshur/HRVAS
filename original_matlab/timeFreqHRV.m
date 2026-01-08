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
% Any functions with a reference to another author may have where
% obtained or modified from another source. Those functions are
% not property or copyrighted for this author. Please see the
% source for licences and usage.

% You should have received a copy of the GNU General Public License
% along with HRVAS.  If not, see <http://www.gnu.org/licenses/>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function output = timeFreqHRV(ibi,nibi,VLF,LF,HF,AR_order,winSize, ...
    overlap,nfft,fs,methods)
%timeFreqHRV - calculates time-freq HRV using ar, lomb, and CWT methods
%
% Inputs:   ibi = 2Dim array of [time (s) ,inter-beat interval (s)]
%           nibi = IBI with trend still present (non-detrended).
%                  Used for CWT.
%           VLF,LF,HF = arrays containing limits of VLF, LF, and HF 
%                       freq. bands
%           winSize = # of samples in window
%           noverlap = # of samples to overlap
%           fs = cubic spline interpolation rate / resample rate (Hz)
%           nfft = # of points in the frequency axis
%           methods = cell array containing UP TO three strings that tell
%           the function what methods to include in calculating HRV
%           {'ar','lomb','wavelet'}
% Outputs:  output is a structure containg all HRV. One field for each
%               PSD method
%           Output units include:
%               peakHF,peakLF,peakVLF (Hz)
%               aHF,aLF,aVLF (ms^2)
%               pHF,pLF,pVLF (%)
%               nHF,nLF,nVLF (%)
%               lfhf,rlfhf
%               PSD (ms^2/Hz)
%               F (Hz)
%               T (s)
% Usage:   n/a     


    %check input
    if nargin<10; error('Not enough input arguments!'); end
    if nargin<11; methods={'ar','lomb','wavelet'}; end
    
    flagAR=false; flagLomb=false; flagWavelet=false;
    for m=1:length(methods)
        if strcmpi(methods{m},'ar')
            flagAR=true;
        elseif strcmpi(methods{m},'lomb')
            flagLomb=true;
        elseif strcmpi(methods{m},'wavelet')
            flagWavelet=true;
        end
    end
    
    %assumes ibi units are seconds
    ibi(:,2)=ibi(:,2).*1000; %convert ibi units from s to ms 
    nibi(:,2)=nibi(:,2).*1000; %convert ibi units from s to ms 
    
    t=ibi(:,1); %time
    y=ibi(:,2);        
    clear ibi; %don't need it anymore
    
    maxF=fs/2;
    
    %AR
    if flagAR
        output.ar.t=t;
        [output.ar.psd,output.ar.f,output.ar.t]= ...
            calcAR(t,y,fs,nfft,AR_order,winSize,overlap);
        output.ar.hrv=calcHRV(output.ar.f,output.ar.psd,VLF,LF,HF);
        %global psd
        output.ar.global.f=output.ar.f;
        globalPSD=mean(output.ar.psd,2);
        output.ar.global.psd=globalPSD;
        output.ar.global.hrv=calcAreas(output.ar.global.f, ...
            globalPSD,VLF,LF,HF);
    else
        output.ar=emptyData(t,nfft,maxF);
    end
    
    
    %Lomb
    if flagLomb
        output.lomb.t=t;
        [output.lomb.psd,output.lomb.f,output.lomb.t]= ...
            calcLomb(t,y,nfft,maxF,winSize,overlap);
        output.lomb.hrv=calcHRV(output.lomb.f,output.lomb.psd,VLF,LF,HF);
        %global psd
        output.lomb.global.f=output.lomb.f;
        globalPSD=mean(output.lomb.psd,2);
        output.lomb.global.psd=globalPSD;
        output.lomb.global.hrv=calcAreas(output.lomb.global.f, ...
            globalPSD,VLF,LF,HF);
    else
        output.lomb=emptyData(t,nfft,maxF);
    end    

    %Wavelet
    if flagWavelet
        %y=nibi(:,2);
        clear nibi; % don't need it anymore
        t2 = t(1):1/fs:t(length(t)); %time values for interp.
        y=interp1(t,y,t2,'spline')'; %cubic spline interpolation
        
        output.wav.t=t2;
        [power,f,scale,Cdelta,n,dj,dt,variance]=calcWavelet(y,fs);
        output.wav.psd=power;
        output.wav.f=f;
        variance=var(y);
        n=length(y);
        output.wav.hrv= ...
            calcWavHRV(f,power,scale,Cdelta,variance,n,dj,dt,VLF,LF,HF);
        
        % Global wavelet power spectrum
        global_ws=variance*(sum(power,2)/n);
        output.wav.global.psd=global_ws;
        output.wav.global.f=f;
        output.wav.global.hrv=calcAreas(f,global_ws,VLF,LF,HF);
    else
        output.wav=emptyData(t,nfft,maxF);
    end
end

function [PSD,F,T]=calcAR(t,y,fs,nfft,AR_order,winSize,overlap)
%calAR - Calculates PSD using windowed Burg method.
%
%Inputs:
%Outputs:          

    winSize=winSize*fs; % (samples)
    overlap=overlap*fs; % (samples)
    
    %resample
    tint = t(1):1/fs:t(length(t)); %time values for interp.
    y=interp1(t,y,tint,'spline')'; %cubic spline interpolation            
        
    %get limits of windows    
    if tint(end)>=winSize
        idx=slidingWindow(tint,winSize,overlap,0); %(sample #)
    else
        idx=[1 length(tint)];
    end
    T=tint(idx(:,1)+round(winSize/2)); %calculate center time of window (s)
                                       %used for plotting    
    
    %preallocate memory
    nPSD=size(idx,1); %number of PSD/windows
    PSD=zeros(nfft,nPSD);    
        
    %Calculate PSD
     for i=1:nPSD
        %Prepare y2 and t2
        y2=y(idx(i,1):idx(i,2));
        t2=tint(idx(i,1):idx(i,2));        
        
        %remove linear trend
%        y=detrend(y,'linear');
        y2=y2-mean(y2); %remove mean
        y2 = y2.*hamming(length(y2)); %hamming window

        %Calculate PSD                 
        [psd,f]=pburg(y2,AR_order,(nfft*2)-1,fs,'onesided');        
        PSD(:,i)=psd;
     end
     F=f;
end

function [PSD,F,T]=calcLomb(t,y,nfft,maxF,winSize,overlap)
%calLomb - Calculates PSD using windowed Lomb-Scargle method.
%
%Inputs:
%Outputs:            
    
    %get limits of windows
    if t(end)>=winSize
        idx=slidingWindow(t,winSize,overlap,1);
    else
        idx=[1 length(t)];
    end
    %estimate the center of the windows for plotting
    T=t(idx(:,1))+round(winSize/2);
    
    %preallocate memory
    nPSD=size(idx,1); %number of PSD/windows
    PSD=zeros(nfft,nPSD);
    t2=zeros(nPSD,1);
    
    deltaF=maxF/nfft;        
    F = linspace(0.0,maxF-deltaF,nfft)';
    for i=1:nPSD
        %Prepare y2 and t2
        y2=y(idx(i,1):idx(i,2));
        t2=t(idx(i,1):idx(i,2));
        
        %remove linear trend
        y2=detrend(y2,'linear');
        
        y2=y2-mean(y2); %remove mean
        
        %Calculate un-normalized lomb PSD        
        PSD(:,i)=lomb2(y2,t2,F,false); 
        
    end
end

function [cwtpower,f,scale,Cdelta,n,dj,dt,variance]=calcWavelet(y,fs)
    
    variance = std(y)^2;
    y = (y - mean(y))/sqrt(variance) ;

    n = length(y);
    dt = 1/fs;   
    %xlim = [0,t2(end)];  % plotting range
    pad = 1;      % pad the time series with zeroes (recommended)
    dj = 1/64;    % this will do 4 sub-octaves per octave
    s0 = 2*dt;    % this says start at a scale of 0.5 s
    j1 = 7/dj;    % this says do 7 powers-of-two with dj sub-octaves each
    lag1 = 0.72;  % lag-1 autocorrelation for red noise background

    mother = 'Morlet';
    %mother = 'DOG';
    %mother = 'Paul';
    Cdelta = 0.776;   % this is for the MORLET wavelet
    
    % Wavelet transform
    [wave,period,scale,coi] = wavelet(y,dt,pad,dj,s0,j1,mother);
    % Reference: Torrence, C. and G. P. Compo, 1998: A Practical Guide to
    % Wavelet Analysis. <I>Bull. Amer. Meteor. Soc.</I>, 79, 61-78.    
    
    cwtpower = (abs(wave)).^2 ; % compute wavelet power spectrum              
    
    f=fliplr(1./period); %frequency in ascending order
    cwtpower=flipud(cwtpower); %flip to match freq. order
end

function output=calcWavHRV(f,power,scale,Cdelta,variance,n,dj,dt,VLF,LF,HF)
%calcAreas - Calulates areas/energy under the PSD curve within the freq
%bands defined by VLF, LF, and HF. Returns areas/energies as ms^2,
%percentage, and normalized units. Also returns LF/HF ratio.
%
%Inputs:
%   PSD: PSD vector
%   F: Freq vector
%   VLF, LF, HF: array containing VLF, LF, and HF freq limits
%   flagNormalize: option to normalize PSD to max(PSD)
%Output:
%
%Usage:
%   

    % Scale-average between VLF, LF, and HF bands/scales
    % f=fliplr(f); %put f in it's original order
    iVLF = find((f >= VLF(1)) & (f < VLF(2)));
    iLF = find((f >= LF(1)) & (f < LF(2)));
    iHF = find((f >= HF(1)) & (f < HF(2)));
    scale_avg = (scale')*(ones(1,n));  % expand scale --> (J+1)x(N) array
    scale_avg = power ./ scale_avg;   % [Eqn(24)]
    vlf_scale_avg = variance*dj*dt/Cdelta*sum(scale_avg(iVLF,:));%[Eqn(24)]
    lf_scale_avg = variance*dj*dt/Cdelta*sum(scale_avg(iLF,:));
    hf_scale_avg = variance*dj*dt/Cdelta*sum(scale_avg(iHF,:));
    
     % calculate raw areas (power under curve), within the freq bands (ms^2)
    output.aVLF=vlf_scale_avg;
    output.aLF=lf_scale_avg;
    output.aHF=hf_scale_avg;
    output.aTotal=output.aVLF+output.aLF+output.aHF;
        
    %calculate areas relative to the total area (%)
    output.pVLF=(output.aVLF./output.aTotal)*100;
    output.pLF=(output.aLF./output.aTotal)*100;
    output.pHF=(output.aHF./output.aTotal)*100;
    
    %calculate normalized areas (relative to HF+LF, n.u.)
    output.nLF=output.aLF./(output.aLF+output.aHF);
    output.nHF=output.aHF./(output.aLF+output.aHF);
    
    %calculate LF/HF ratio
    output.LFHF =output.aLF./output.aHF;
    output.rLFHF=sum(output.LFHF>1)/sum(output.LFHF<=1);
    
    %calculate peaks
    output.peakVLF=zeros(size(vlf_scale_avg));
    output.peakLF=output.peakVLF;
    output.peakHF=output.peakVLF;
    
end

function output=calcHRV(F,PSD,VLF,LF,HF)
% calcAreas - Calulates areas/energy under the PSD curve within the freq
% bands defined by VLF, LF, and HF. Returns areas/energies as ms^2,
% percentage, and normalized units. Also returns LF/HF ratio.
%
% Inputs:
%   PSD: PSD vector
%   F: Freq vector
%   VLF, LF, HF: array containing VLF, LF, and HF freq limits
%   flagVLF: flag to decide whether to calculate VLF hrv
% Output:
%
% Usage:
%   
%
% Ref: Modified from Gary Clifford's ECG Toolbox: calc_lfhf.m   
    
    nPSD=size(PSD,2);
    z=zeros(nPSD,1);
    output= struct('aVLF',z, 'aLF',z, 'aHF',z, 'aTotal',z, 'pVLF',z, ...
        'pLF',z, 'pHF',z, 'nLF',z, 'nHF',z, 'LFHF',z, 'rLFHF',0, ...
        'peakVLF',z, 'peakLF',z, 'peakHF',z);
        
    for p=1:nPSD
        a=calcAreas(F,PSD(:,p),VLF,LF,HF);

        %create output structure
        output.aVLF(p)=a.aVLF;
        output.aLF(p)=a.aLF;
        output.aHF(p)=a.aHF;
        output.aTotal(p)=a.aTotal;
        output.pVLF(p)=a.pVLF;
        output.pLF(p)=a.pLF;
        output.pHF(p)=a.pHF;
        output.nLF(p)=a.nLF;
        output.nHF(p)=a.nHF;
        output.LFHF(p)=a.LFHF;
        output.peakVLF(p)=a.peakVLF;
        output.peakLF(p)=a.peakLF;
        output.peakHF(p)=a.peakHF;
    end
        rlfhf=sum(output.LFHF>1)/sum(output.LFHF<=1);
        output.rLFHF=rlfhf;    
end

function output=calcAreas(F,PSD,VLF,LF,HF,flagNorm)
%calcAreas - Calulates areas/energy under the PSD curve within the freq
%bands defined by VLF, LF, and HF. Returns areas/energies as ms^2,
%percentage, and normalized units. Also returns LF/HF ratio.
%
%Inputs:
%   PSD: PSD vector
%   F: Freq vector
%   VLF, LF, HF: array containing VLF, LF, and HF freq limits
%   flagNormalize: option to normalize PSD to max(PSD)
%Output:
%
%Usage:
%   
%
% Reference: This code is based on the calc_lfhf.m function from Gary
% Clifford's ECG Toolbox.    

    if nargin<6
       flagNorm=false;
    end
    
    %normalize PSD if needed
    if flagNorm
        PSD=PSD/max(PSD);
    end

    % find the indexes corresponding to the VLF, LF, and HF bands
    iVLF= (F>=VLF(1)) & (F<=VLF(2));
    iLF = (F>=LF(1)) & (F<=LF(2));
    iHF = (F>=HF(1)) & (F<=HF(2));
      
    %Find peaks
      %VLF Peak
      tmpF=F(iVLF);
      tmppsd=PSD(iVLF);
      [pks,ipks] = zipeaks(tmppsd);
      if ~isempty(pks)
        [tmpMax i]=max(pks);        
        peakVLF=tmpF(ipks(i));
      else
        [tmpMax i]=max(tmppsd);
        peakVLF=tmpF(i);
      end
      %LF Peak
      tmpF=F(iLF);
      tmppsd=PSD(iLF);
      [pks,ipks] = zipeaks(tmppsd);
      if ~isempty(pks)
        [tmpMax i]=max(pks);
        peakLF=tmpF(ipks(i));
      else
        [tmpMax i]=max(tmppsd);
        peakLF=tmpF(i);
      end
      %HF Peak
      tmpF=F(iHF);
      tmppsd=PSD(iHF);
      [pks,ipks] = zipeaks(tmppsd);
      if ~isempty(pks)
        [tmpMax i]=max(pks);        
        peakHF=tmpF(ipks(i));
      else
        [tmpMax i]=max(tmppsd);
        peakHF=tmpF(i);
      end 
      
    % calculate raw areas (power under curve), within the freq bands (ms^2)
    aVLF=trapz(F(iVLF),PSD(iVLF));
    aLF=trapz(F(iLF),PSD(iLF));
    aHF=trapz(F(iHF),PSD(iHF));
    aTotal=aVLF+aLF+aHF;
        
    %calculate areas relative to the total area (%)
    pVLF=(aVLF/aTotal)*100;
    pLF=(aLF/aTotal)*100;
    pHF=(aHF/aTotal)*100;
    
    %calculate normalized areas (relative to HF+LF, n.u.)
    nLF=aLF/(aLF+aHF);
    nHF=aHF/(aLF+aHF);
    
    %calculate LF/HF ratio
    lfhf =aLF/aHF;
            
     %create output structure
    if flagNorm
        output.aVLF=round(aVLF*1000)/1000;
        output.aLF=round(aLF*1000)/1000;
        output.aHF=round(aHF*1000)/1000;
        output.aTotal=round(aTotal*1000)/1000;
    else
        output.aVLF=round(aVLF*100)/100; % round
        output.aLF=round(aLF*100)/100;
        output.aHF=round(aHF*100)/100;
        output.aTotal=round(aTotal*100)/100;
    end    
    output.pVLF=round(pVLF*10)/10;
    output.pLF=round(pLF*10)/10;
    output.pHF=round(pHF*10)/10;
    output.nLF=round(nLF*1000)/1000;
    output.nHF=round(nHF*1000)/1000;
    output.LFHF=round(lfhf*1000)/1000;
    output.peakVLF=round(peakVLF(1)*100)/100;
    output.peakLF=round(peakLF(1)*100)/100;
    output.peakHF=round(peakHF(1)*100)/100;
end

function output=emptyData(t,nfft,maxF)
%create output structure of zeros
   
    %iStart = 1:(winSize-overlap):(N-winSize+1);
    nPSD=1;
    
    %PSD with all zeros
    output.psd=zeros(nfft,nPSD);
    output.t=linspace(0,max(t),nPSD);
    deltaF=maxF/nfft;
    output.f = linspace(0.0,maxF-deltaF,nfft);
    
    %HRV with zeros
    for p=1:nPSD      
        %create output structure
        output.hrv.aVLF(p)=0;
        output.hrv.aLF(p)=0;
        output.hrv.aHF(p)=0;   
        output.hrv.aTotal(p)=0;
        output.hrv.pVLF(p)=0;
        output.hrv.pLF(p)=0;
        output.hrv.pHF(p)=0;
        output.hrv.nLF(p)=0;
        output.hrv.nHF(p)=0;
        output.hrv.LFHF(p)=0;
        output.hrv.peakVLF(p)=0;
        output.hrv.peakLF(p)=0;
        output.hrv.peakHF(p)=0;        
    end
        output.hrv.rLFHF=0;

    %global
    output.global.psd=output.psd(:,1);
    output.global.f=output.f;
    output.global.hrv.aVLF=0;
    output.global.hrv.aLF=0;
    output.global.hrv.aHF=0;   
    output.global.hrv.aTotal=0;
    output.global.hrv.pVLF=0;
    output.global.hrv.pLF=0;
    output.global.hrv.pHF=0;
    output.global.hrv.nLF=0;
    output.global.hrv.nHF=0;
    output.global.hrv.LFHF=0;
    output.global.hrv.peakVLF=0;
    output.global.hrv.peakLF=0;
    output.global.hrv.peakHF=0;                

end

function [pks locs]=zipeaks(y)
%zippeaks: finds local maxima of input signal y
%Usage:  peak=zipeaks(y);
%Returns 2x(number of maxima) array
%pks = value at maximum
%locs = index value for maximum
%
%Reference:  2009, George Zipfel (Mathworks File Exchange #24797)

%check dimentions
if isempty(y)
    Warning('Empty input array')
    pks=[]; locs=[];
    return
end
[rows cols] = size(y);
if cols==1 && rows>1 %all data in 1st col
    y=y';
elseif cols==1 && rows==1 
    Warning('Short input array')
    pks=[]; locs=[];
    return    
end         
    
%Find locations of local maxima
%yD=1 at maxima, yD=0 otherwise, end point maxima excluded
    N=length(y)-2;
    yD=[0 (sign(sign(y(2:N+1)-y(3:N+2))-sign(y(1:N)-y(2:N+1))-.1)+1) 0];
%Indices of maxima and corresponding values of y
    Y=logical(yD);
    I=1:length(Y);
    locs=I(Y);
    pks=y(Y);
end
