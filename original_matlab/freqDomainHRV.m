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

function output = freqDomainHRV(ibi,VLF,LF,HF,AR_order,window, ...
    noverlap,nfft,fs,methods,flagPlot)
%freqDomainHRV - calculates freq domain HRV using FFT, AR, and Lomb-Scargle
%methods
%
%Inputs:    ibi = 2Dim array of time (s) and inter-beat interval (s)
%           AR_order = order of AR model
%           window = # of samples in window
%           noverlap = # of samples to overlap
%           fs = cubic spline interpolation rate / resample rate (Hz)
%           nfft = # of points in the frequency axis
%           methods = cell array of strings that defines the methods used to
%               calculate freqDomain. The default is all to use
%               all three methods. 
%               methods={'welch','ar','lomb'}
%           flagPlot = flag to tell function to plot PSD. 1=plot,
%           0=don't plot, default is 0.
%Outputs:   output is a structure containg all HRV. One field for each 
%           PSD method.
%           Output units include:
%               peakHF,LF,VLF (Hz)
%               aHF,aLF,aVLF (ms^2)
%               pHF,pLF,pVLF (%)
%               nHF,nLF,nVLF (%)
%               PSD (ms^2/Hz)
%               F (Hz)
%Usage:  (1) To compute freq. domain HRV on a ibi data set named dIBI 
%        using VLF=[0.0-0.16], LF =[0.16-0.6], HF=[0.6 3], 
%        AR model order = 16, welch window width = 256, 
%        # of overlap pnts in welch window (50%) = 128, # of pnts in fft = 512, 
%        IBI resample rate = 10Hz
%        
%        Use: output = freqDomainHRV(sampledata,[0 .16],[.16 .6],[.6 3], ...
%                       16, 256, 128, 512, 10);
%
%        (2) To do the above and also plot all three power
%        spectrum densities (PSD)
%
%        Use: output = freqDomainHRV(sampledata,[0 .16],[.16 .6],[.6 3], ...
%                       16,256,128,512,10,{'welch','ar','lomb'},1);


    %check input
    if nargin<9
        error('Not enough input arguments!')
    elseif nargin<10
        methods={'welch','ar','lomb'};
        flagPlot=false;
    elseif nargin<11
        flagPlot=false;
    end    
    
    flagWelch=false; flagAR=false; flagLomb=false;
    for m=1:length(methods)
        if strcmpi(methods{m},'welch')
            flagWelch=true;
        elseif strcmpi(methods{m},'ar')
            flagAR=true;
        elseif strcmpi(methods{m},'lomb')
            flagLomb=true;
        end
    end 
    
    t=ibi(:,1); %time (s)
    y=ibi(:,2); %ibi (s)     
    
    y=y.*1000; %convert ibi to ms
    %assumes ibi units are seconds
    
    maxF=fs/2;
    
    %prepare y
    y=detrend(y,'linear');
    y=y-mean(y);
    
    %Welch FFT
    if flagWelch
        [output.welch.psd,output.welch.f] = ...
            calcWelch(t,y,window,noverlap,nfft,fs);
        output.welch.hrv = ...
            calcAreas(output.welch.f,output.welch.psd,VLF,LF,HF);
    else
        output.welch=emptyData(nfft,maxF);
    end
    
    %AR
    if flagAR
        [output.ar.psd,output.ar.f]=calcAR(t,y,fs,nfft,AR_order);
        output.ar.hrv=calcAreas(output.ar.f,output.ar.psd,VLF,LF,HF);
    else
        output.ar=emptyData(nfft,maxF);
    end
    
    %Lomb
    if flagLomb
        [output.lomb.psd,output.lomb.f]=calcLomb(t,y,nfft,maxF);
        output.lomb.hrv = ...
            calcAreas(output.lomb.f,output.lomb.psd,VLF,LF,HF,true);
    else
        output.lomb=emptyData(nfft,maxF);
    end
    
    %plot all three psd
    if flagPlot
    figure;
    h1=subplot(3,1,1);
    plotPSD(h1,output.welch.f,output.welch.psd,VLF,LF,HF,[0 0.6],[]);
    legend('welch')
    h2=subplot(3,1,2);
    plotPSD(h2,output.ar.f,output.ar.psd,VLF,LF,HF,[0 0.6],[]);
    legend('AR')
    h3=subplot(3,1,3);
    plotPSD(h3,output.lomb.f,output.lomb.psd,VLF,LF,HF,[0 0.6],[]);
    legend('Lomb-Scargle')
    end
end

function [PSD,F]=calcWelch(t,y,window,noverlap,nfft,fs)
%calFFT - Calculates the PSD using Welch method.
%
%Inputs:
%Outputs:
    
    %Prepare y
    t2 = t(1):1/fs:t(length(t));%time values for interp.
    y=interp1(t,y,t2','spline')'; %cubic spline interpolation
    y=y-mean(y); %remove mean
    
    %Calculate Welch PSD using hamming windowing    
    [PSD,F] = pwelch(y,window,noverlap,(nfft*2)-1,fs,'onesided'); 
    
end

function [PSD,F]=calcAR(t,y,fs,nfft,AR_order)
%calAR - Calculates the PSD using Auto Regression model.
%
%Inputs:
%Outputs:
    
    %Prepare y    
    t2 = t(1):1/fs:t(length(t)); %time values for interp.
    y=interp1(t,y,t2,'spline')'; %cubic spline interpolation
    y=y-mean(y); %remove mean
    y = y.*hamming(length(y)); %hamming window
    
    %Calculate PSD
    %Method 1
%     [A, variance] = arburg(y,AR_order); %AR using Burg method
%     [H,F] = freqz(1,A,nfft,fs);
%     PSD=(abs(H).^2).*(variance/fs); %malik, p.67    
    %Method 2
    [PSD,F]=pburg(y,AR_order,(nfft*2)-1,fs,'onesided');
    %Method 3
%      h=spectrum.burg;
%      hpsd = psd(h, y, 'NFFT', nfft, 'Fs', 2);
%      F=hpsd.Frequencies;
%      PSD=hpsd.Data;
     
end

function [PSD,F]=calcLomb(t,y,nfft,maxF)
%calLomb - Calculates the PSD using Lomb-Scargle method.
%
%Inputs:
%Outputs:
        
    %Calculate PSD
    deltaF=maxF/nfft;
    F = linspace(0.0,maxF-deltaF,nfft);
    PSD=lomb2(y,t,F,false); %calc lomb psd
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
%   Modified from Gary Clifford's ECG Toolbox: calc_lfhf.m   

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

function plotPSD(aH,F,PSD,VLF,LF,HF,limX,limY)

    color.vlf=[.5 .5 1];    %vlf color
    color.lf=[.7 .5 1];     %lf color
    color.hf=[.5 1 1];      %hf color

    % find the indexes corresponding to the VLF, LF, and HF bands
    iVLF= find( (F>=VLF(1)) & (F<VLF(2)) );
    iLF = find( (F>=LF(1)) & (F<LF(2)) );
    iHF = find( (F>=HF(1)) & (F<HF(2)) );

    %plot area under PSD curve
    area(aH,F(:),PSD(:),'FaceColor',[.8 .8 .8]);        
    hold(aH);
    area(aH,F(iVLF(1):iVLF(end)+1),PSD(iVLF(1):iVLF(end)+1), ...
        'FaceColor',color.vlf);
    area(aH,F(iLF(1):iLF(end)+1),PSD(iLF(1):iLF(end)+1), ...
        'FaceColor',color.lf);
    area(aH,F(iHF(1):iHF(end)+1),PSD(iHF(1):iHF(end)+1), ...
        'FaceColor',color.hf);
    
    if ~isempty(limX)
        set(aH,'xlim',limX)
    else
        limX=[min(F) max(F)];
    end
    if ~isempty(limY)
        set(aH,'ylim',limY)
    else
        limY=[min(PSD) max(PSD)];
    end
    
    %draw vertical lines around freq bands
    line1=line([VLF(2) VLF(2)],[limY(1) limY(2)]);
    set(line1,'color',[1 0 0],'parent',aH);
    line2=line([LF(2) LF(2)],[limY(1) limY(2)]);
    set(line2,'color',[1 0 0],'parent',aH);
    line3=line([HF(2) HF(2)],[limY(1) limY(2)]);
    set(line3,'color',[1 0 0],'parent',aH);
   
    hold(aH)
        
end

function output=emptyData(nfft,maxF)
%create output structure of zeros
    
    output.hrv.aVLF=0;
    output.hrv.aLF=0;
    output.hrv.aHF=0;
    output.hrv.aTotal=0;
    output.hrv.pVLF=0;
    output.hrv.pLF=0;
    output.hrv.pHF=0;
    output.hrv.nLF=0;
    output.hrv.nHF=0;
    output.hrv.LFHF=0;
    output.hrv.peakVLF=0;
    output.hrv.peakLF=0;
    output.hrv.peakHF=0;
        
    %PSD with all zeros
    deltaF=maxF/nfft;    
    output.f = linspace(0.0,maxF-deltaF,nfft);
    output.psd=zeros(length(output.f),1);

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
