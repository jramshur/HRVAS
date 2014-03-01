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

function output = nonlinearHRV(ibi,m,r,n1,n2,breakpoint)
%nonlinearHRV(IBI,opt) - calculates nonlinear HRV
%
%Inputs:    IBI = inter-beat interval (s) and time locations (s)
%           opt = analysis options from gui
%           
%Outputs:   output is a structure containg all HRV.
  

    %check inputs
    ibi(:,2)=ibi(:,2).*1000; %convert ibi to ms
    %assumes ibi units are seconds

%     if abs(range(ibi(:,2)))<50 %assume ibi units are seconds            
%             ibi(:,2)=ibi(:,2).*1000; %convert ibi to ms
%     end
%     if abs(range(diff(ibi(:,1))))>50 %assume time unites are ms
%         ibi(:,1)=ibi(:,1)./1000; %convert time to s
%     end

    output.sampen=sampen(ibi(:,2),m,r,0,0);
    output.dfa=DFA(ibi(:,2),n1,n2,breakpoint);
end



function [e,se,A,B]=sampen(y,m,r,sflag,vflag)
%function e=sampen(y,M,r);
%
%Input Parameters
%
%   y:  input signal vector
%   m:  maximum template length (default m=5)
%   r:  matching threshold in standard deviations (default r=.2)
%
%Output Parameters
%
%   e sample entropy estimates for m=0,1,...,M-1
%
%Full usage:
%
%   [e,se,A,B]=sampen(y,m,r,sflag,cflag,vflag)
%
%Input Parameters
%
%   sflag    flag to standardize signal(default yes/sflag=1) 
%   vflag    flag to calculate standard errors (default no/vflag=0) 
%
%Output Parameters
%
%   se standard error estimates for m=0,1,...,M-1
%   A number of matches for m=1,...,M
%   B number of matches for m=0,...,M-1
%   (excluding last point in Matlab version)
%
% Ref: http://www.physionet.org/physiotools/sampen/matlab/1.1/

    if ~exist('m','var')||isempty(m),m=5;end
    if ~exist('r','var')||isempty(r),r=.2;end
    if ~exist('sflag','var')||isempty(sflag),sflag=1;end
    if ~exist('vflag','var')||isempty(vflag),vflag=0;end

    y=y(:);
    n=length(y);
    %normalize ?
    if sflag>0
       y=y-mean(y);
       s=sqrt(mean(y.^2));   
       y=y/s;
    end
    if vflag>0
        se=sampense(y,m,r);
    else
        se=[];
    end        
    
    r=r*std(y);
    [e,A,B]=sampenc(y,m,r);
    
    %format decimal places
    e=round(e.*1000)./1000;
    
    return    
end

function [e,A,B]=sampenc(y,M,r)
%function [e,A,B]=sampenc(y,M,r);
%
%Input
%
%   y input data
%   M maximum template length
%   r matching tolerance
%
%Output
%
%   e sample entropy estimates for m=0,1,...,M-1
%   A number of matches for m=1,...,M
%   B number of matches for m=0,...,M-1 excluding last point
%
% http://www.physionet.org/physiotools/sampen/matlab/1.1/
    n=length(y);
    lastrun=zeros(1,n);
    run=zeros(1,n);
    A=zeros(M,1);
    B=zeros(M,1);
    p=zeros(M,1);
    e=zeros(M,1);
    for i=1:(n-1)
       nj=n-i;
       y1=y(i);
       for jj=1:nj
          j=jj+i;      
          if abs(y(j)-y1)<r
             run(jj)=lastrun(jj)+1;
             M1=min(M,run(jj));
             for m=1:M1           
                A(m)=A(m)+1;
                if j<n
                   B(m)=B(m)+1;
                end            
             end
          else
             run(jj)=0;
          end      
       end
       for j=1:nj
          lastrun(j)=run(j);
       end
    end
    N=n*(n-1)/2;
    B=[N;B(1:(M-1))];
    p=A./B;
    e=-log(p);
end

function output=DFA(data,n1,n2,breakpoint)
%DFA(IBI,nn) - calculates alpha from detrended fluctuation analysis
%
%Inputs:    y = inter-beat interval signal (s)
%           n1,n2 = limits of window sizes
%           breakpoint = value of n that determines where alpha1 ends and
%           alpha2 begins
%           
%Outputs:   alpha = slope of log-log plot of integrated y vs window size.
%
%Example:   alpha=DFA(y,4,300)
%
% Reference: Heart rate analysis in normal subjects of various age groups
% Rajendra Acharya U*, Kannathal N, Ong Wai Sing, Luk Yi Ping and
% TjiLeng Chua

    if nargin < 4 || isempty(breakpoint); breakpoint=13; end
    if nargin < 3
       n1=4;
       n2=300;
       breakpoint=13;
    end
    
    [r c]=size(data);
    if r>c; data=data'; end
    
    n=[n1:1:n2]; %array of window sizes
    nLen=length(n);

    %preallocate memory
    F_n=zeros(1,nLen);        

    mu=mean(data); %mean value
    
    for i=1:nLen
        N=length(data);
        nWin=floor(N/n(i)); %number of windows
        N1=nWin*n(i); %length of data minus rem
        
        %preallocate memory
        yk=zeros(1,N1);
        Yn=zeros(1,N1);
        %fitcoef=zeros(2,n(i)); 
        
        yk=cumsum(data(1:N1)-mu); %integrate        
        
        for j=1:nWin
            %linear fit coefs
            p=polyfit(1:n(i),yk(((j-1)*n(i)+1):j*n(i)),1);
            %create linear fit
            Yn(((j-1)*n(i)+1):j*n(i))=polyval(p,1:n(i));
        end
        
        % RMS fluctuation of integraged and detrended series
        F_n(i) = sqrt( sum((yk-Yn).^2)/N1 );
    end
    
    %fit all values of n
    a=polyfit(log10(n),log10(F_n),1);
    
    bp=find(n==breakpoint);
    %fit short term n=1:bp
    a1=polyfit(log10(n(1:bp)),log10(F_n(1:bp)),1);
    %fit long term n=bp+1:end
    a2=polyfit(log10(n(bp+1:end)),log10(F_n(bp+1:end)),1);
    
%     lfit=polyval(a,log10(n));
%     figure; loglog(n,F_n)
%     hold on; loglog(n,10.^lfit,'r')

    output.alpha=round(a.*1000)./1000; % total slope
    output.alpha1=round(a1.*1000)./1000; % short range scaling exponent
    output.alpha2=round(a2.*1000)./1000; % long range scaling exponent
    output.F_n=F_n';
    output.n=n';
    
end

