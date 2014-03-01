%% Compute HRV
%
%  To compute freq. domain HRV on a ibi data set named dIBI 
%  using VLF=[0.0-0.16], LF =[0.16-0.6], HF=[0.6 3], 
%  AR model order = 16, welch window width = 256, 
%  # of overlap pnts in welch window (50%) = 128, # of pnts in fft = 512, 
%  IBI resample rate = 10Hz
%        

myibi=load('sampledata.ibi','ascii'); % Load IBI data into variable

output1 = freqDomainHRV(myibi,[0 .16],[.16 .6],[.6 3], ...
           16, 256, 128, 512, 10);

%% Compute HRV and Plot
%
% To do the above and also plot all three power spectrum densities (PSD) use:
%
output2 = freqDomainHRV(myibi,[0 .16],[.16 .6],[.6 3], ...
          16,256,128,512,10,{'welch','ar','lomb'},1);
