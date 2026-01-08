function [Pn] = lomb2(y, t, f,flagNorm)
%
%  [Pn] = lomb(t, y, f)
%
%  Uses Lomb's method to compute normalized
%  periodogram values "Pn" as a function of
%  supplied vector of frequencies "f" for
%  input vectors "t" (time) and "y" (observations).
%  Also returned is probability "Prob" of same
%  length as Pn (and f) that the null hypothesis
%  is valid. If f is not supplied it assumes
%  f =  [1/1024 : 1/1024 : 0.5/min(diff(t))];		
%  x and y must be the same length.

% See also:  
%
% [1] N.R. Lomb, ``Least-squares frequency analysis of 
% unequally spaced data,'' Astrophysical and Space Science, 
% (39) pp. 447--462, 1976.   ... and 
%
% [2] J.~D. Scargle, ``Studies in astronomical time series analysis. 
% II. Statistical aspects of spectral analysis of unevenly spaced data,''
% Astrophysical Journal, vol. 263, pp. 835--853, 1982.
%
% [3] T. Thong, "Lomb-Welch Periodogram for Non-uniform Sampling",
% Proceedings for the 26th anual international conference of the IEEE EMBS,
% Sept 1-5, 2004.

if nargin<4
    flagNorm=true;
end

if nargin<3
 upper_freq = 0.5/min(diff(t));
 f =  [1/1024 : 1/1024 : upper_freq];
end

if nargin < 2
 fprintf('assuming y=diff(t)\n');
 y=diff(t); % RR tachogram?
 t=t(1:length(y)); % shorter by one time stamp now
end

% check inputs
if length(t) ~= length(y); 
 error('t and y not same length');
 exit; 
end;

% subtract mean, compute variance, initialize Pn
z = y - mean(y);
var = std(y)^2;
N=length(f);
Pn=zeros(size(f));

%	now do main loop for all frequencies
for i=1:length(f)
    w=2*pi*f(i);
    if w > 0 
       twt = 2*w*t;
       tau = atan2(sum(sin(twt)),sum(cos(twt)))/2/w;
       wtmt = w*(t - tau);
       Pn(i) = (sum(z.*cos(wtmt)).^2)/sum(cos(wtmt).^2) + ...
		(sum(z.*sin(wtmt)).^2)/sum(sin(wtmt).^2);
     else
	Pn(i) = (sum(z.*t).^2)/sum(t.^2);
     end
end

if flagNorm %normalize by variance
    Pn=Pn./(2*var);
else % return denormalized spectrum (see T. Thong)
    Pn=Pn./length(y);
end
