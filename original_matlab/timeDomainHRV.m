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

function output = timeDomainHRV(ibi,win,xx)
%timeDomainHRV: calculates time-domain hrv of ibi interval series	
% ibi = 2dim ibi array
% win = window size to use for sdnni (s)
% xx = value to use for NNx and pNNx (ms)

    t=ibi(:,1)-ibi(1,1);
    ibi=ibi(:,2);
    %check inputs
    ibi=ibi.*1000; %convert ibi to ms
    %assumes ibi units are seconds
    
%     if abs(range(ibi))<50 %assume ibi units are seconds            
%             ibi=ibi.*1000; %convert ibi to ms
%     end
%     if abs(range(diff(t)))>50 %assume time unites are ms
%         t=t./1000; %convert time to s
%     end
    
%     if t<1000 %assume win units are (s)
%         t=t*1000; %convert to (ms)
%     end        

    %calculate and round to nearest 1 decimal point
    output.max=round(max(ibi)*10)/10;
    output.min=round(min(ibi)*10)/10;
    output.mean=round(mean(ibi)*10)/10;
    output.median=round(median(ibi)*10)/10;
    output.SDNN=round(std(ibi)*10)/10;
    output.SDANN=round(SDNNi(ibi,win*1000)*10)/10;
    [p n]=pNNx(ibi,xx);
    output.NNx=round(n*10)/10;
    output.pNNx=round(p*10)/10;
    output.RMSSD=round(RMSSD(ibi)*10)/10;
    output.SDNNi=round(SDANN(ibi,win*1000)*10)/10;
    %heart rate
    hr=60./(ibi./1000);
    output.meanHR=round(mean(hr)*10)/10;
    output.sdHR=round(std(hr)*10)/10;
        
    %GEOMETRIC HRV
    
    %calculate number of bins to use in histogram    
    dt=max(ibi)-min(ibi);
    %1/128 seconds. Reference: (1996) Heart rate variability:
    %standards of measurement, physiological interpretation and
    %clinical use.
    binWidth=1/128*1000; 
    nBins=round(dt/binWidth);
    
    %temp
    nBins=32;
    
    output.HRVTi=round(hrvti(ibi,nBins)*10)/10;
    output.TINN=round(tinn(ibi,nBins)*10)/10;
            
end

function output = SDANN(ibi,t)
%SDANN: SDANN index is the std of all the mean NN intervals from each 
%segment of lenght t.
    a=0;i1=1;
    tmp=zeros(ceil(sum(ibi)/t),1);
    for i2=1:length(ibi)
        if sum(ibi(i1:i2)) >= t
            a=a+1;
            tmp(a)=mean(ibi(i1:i2));
            i1=i2;
        end
    end
    output=std(tmp);
end

function output = SDNNi(ibi,t)
%SDNNi: SDNN index is the mean of all the standard deviations of
%NN (normal RR) intervals for all windows of lenght t.
    a=0;i1=1;
    tmp=zeros(ceil(sum(ibi)/t),1);
    for i2=1:length(ibi)
        if sum(ibi(i1:i2)) >= t
            a=a+1;
            tmp(a)=std(ibi(i1:i2));
            i1=i2;
        end
    end
    output=mean(tmp);
end

function [p n] = pNNx(ibi,x)
%pNNx: percentage of successive/adjacent NN intervals differing by x (ms) 
%or more
    differences=abs(diff(ibi)); %successive ibi diffs (ms)    
    n=sum(differences>x);
    p=(n/length(differences))*100;
end

function output = RMSSD(ibi)
%RMSSD: root mean square of successive RR differences
   differences=abs(diff(ibi)); %successive ibi diffs 
   output=sqrt(sum(differences.^2)/length(differences));
end

function output=hrvti(ibi,nbin)
%hrvti: HRV triangular index    
    
    %calculate samples in bin (n) and x location of bins (xout)
    [n,xout]=hist(ibi,nbin);    
    output=length(ibi)/max(n); %hrv ti
    
end

function output=tinn(ibi,nbin)
%tinn: triangular interpolation of NN interval histogram
%Reference: Standards of Measurement, Physiological Interpretation, 
%and Clinical Use
%           Circulation. 1996; 93(5):1043-1065.
    
    %calculate histogram of ibi using nbin bins
    [nout,xout]=hist(ibi,nbin);        
    
    D=nout;
    peaki=find(D==max(D));
    if length(peaki)>1 %if more than one equal peak
        peaki=round(mean(peaki)); % use round(mean)
    end

    % Check the location of peak bin. If it occurs on first bin we cannot
    % computer TINN. Thus return NaN and exit function.
    if peaki==1 % if peak occurs on first bin
        output=nan; % set output as nan
        return;
    end
    
    i=1;
    d=zeros((peaki-1)*(nbin-peaki),3); %create variable to hold difference values

    for m=(peaki-1):-1:1
        for n=(peaki+1):nbin
            %define triangle that fits the histogram
            q=zeros(1,length(D));            
            q(1:m)=0; 
            q(n:end)=0;
            q(m:peaki)=linspace(0,D(peaki),peaki-m+1);
            q(peaki:n)=linspace(D(peaki),0,n-peaki+1);

            %integrate squared difference
            d(i,1)=trapz((D-q).^2);
            d(i,2:3)=[m,n];        
            %plot(D); hold on; plot(q,'r'); hold off;
            %title(['d^2 = ' num2str(d(i,1))])
            i=i+1;
        end
    end
    %find where minimum square diff occured
    i=find(d(:,1)==min(d(:,1)));
    i=i(1); %make sure there is only one choise
    m=d(i,2); n=d(i,3);
    %calculate TINN in (ms)
    output=abs(xout(n)-xout(m));

    %plot    
%     X=xout(peaki); M=xout(m); N=xout(n); Y=nout(peaki);
%     figure;
%     hist(ibi,nbin)
%     xlimits=get(gca,'xlim');
%     hold on;
%     plot(xout,nout,'k')
%     line([M X N M],[0 Y 0 0],'color','r','linewidth',1.5,'LineStyle','--')
%     line([X X],[0 1000],'LineStyle','-.','color','k')
%     line([0 2000],[Y Y],'LineStyle','-.','color','k')
%     colormap white
%     
%     xlabel('IBI (ms)');
%     ylabel('Number of IBI')
%     legend({'Histogram','D(t)','q(t)'})
%     set(gca,'xtick',[xout(m) xout(peaki) xout(n)], ...
%       'xticklabel',{'N','X','M'}, ...
%       'ytick',Y,'yticklabel','Y')
%     set(gca,'xlim',xlimits);


end