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

function batchHRV(opt)
%batchHRV: function that calculates hrv on all ibi files in selected
%           directory
%
%Inputs:
%
%Outputs:
%


%check inputs
% if (nargin < 1) || ~isstruct(opt)
% 
% end


    %choose file containing HRV analysis options
    reply = input('Enter full file path of HRV analysis option file: ', 's');
    if isempty(reply) || exist(reply,'file')~=2
        error('Please choose valid file path!')
        return;
    end
    opt=load(reply);
    opt=opt.settings;
    
    %choose dir containing input files
    reply = input('Enter dir path containing IBI files: ', 's');
    if isempty(reply) || exist(reply,'dir')~=7
        error('Please choose valid input dir path!')
        return;
    end
    
    %check input directory
    fileList = dir(fullfile(reply, '*.ibi')); %get list of files
    fileList(any([fileList.isdir],1))=[]; %remove folders/dir from the list
    fnames = {fileList.name}; %get file names only from fileList structure  
    %build array of full file paths    
    fpaths=cell(length(fnames),1);
    for ff=1:length(fnames)
        fpaths{ff}=fullfile(reply,fnames{ff});
    end        
    
    %display results of input dir
    disp([reply ' contains ' num2str(length(fpaths)) ' .ibi files.'])
    
    %choose output file name to save hrv reslts    
    outPath = input('Enter file name for exported HRV data: ', 's');
    if isempty(outPath)
        error('Please choose valid input dir path!')
        return;
    end
    
    %Batch process HRV
    hrv=batchGetHRV(fpaths,opt);        

    %Export/save HRV
    saveHRV(hrv,opt,fpaths,outPath)
    disp('batchHRV Done!')

end

function saveHRV(hrv,opt,fList,outPath)   
       exportHRV(outPath,fList,hrv,opt)    
end

function hrv=batchGetHRV(fList,opt)
    %Preallocate hrv array
    %hrv=repmat(struct('b',0,'a',0),1,length(fList));

    %display time remaining
    disp('Processing: 0% complete.')
    tic; avgElapsed=0;
    
    %get hrv for each file
    nFiles=length(fList);
    for f=1:nFiles 
        hrv(f)=getHRV(fList{f},opt);

        %calculate remaining time for waitbar
        elapsedTime=toc; %total time elapsed since start
        %average time elapsed to process a single file
        avgElapsed=elapsedTime/f; 
        %time remaining in processing (min)
        timeRem=ceil(avgElapsed*(nFiles-f)/60);
        bar=round(f/nFiles*100);
        disp(['Processing: ' num2str(bar) ...
            '% complete. (~' num2str(timeRem) ' min)'])        
    end    
        
end      

function output=getHRV(f,settings)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % LOAD IBI
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    nIBI=[]; dIBI=[];
    IBI=loadIBI(f,settings);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Preprocess Data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    %build cell array of locate artifacts methods
    methods={}; methInput=[];
    if settings.ArtLocatePer
        methods=[methods,'percent'];
        methInput=[methInput,settings.ArtLocatePerVal];
    end
    if settings.ArtLocateSD
        methods=[methods,'sd'];
        methInput=[methInput,settings.ArtLocateSDVal];
    end
    if settings.ArtLocateMed
        methods=[methods,'median'];
        methInput=[methInput,settings.ArtLocateMedVal];
    end
    %determine which window/span to use
    if strcmpi(settings.ArtReplace,'mean')
        replaceWin=settings.ArtReplaceMeanVal;
    elseif strcmpi(settings.ArtReplace,'median')
        replaceWin=settings.ArtReplaceMedVal;
    else
        replaceWin=0;
    end

    %Note: We don't need to use all the input arguments,but we will let the
    %function handle all inputs
    [dIBI,nIBI,trend,art] = preProcessIBI(IBI, ...
        'locateMethod', methods, 'locateInput', methInput, ...
        'replaceMethod', settings.ArtReplace, ...
        'replaceInput',replaceWin, ...
        'detrendMethod', settings.Detrend, ...
        'smoothMethod', settings.SmoothMethod, ...
        'smoothSpan', settings.SmoothSpan, ...
        'smoothDegree', settings.SmoothDegree, ...
        'polyOrder', settings.PolyOrder, ...
        'waveletType', ...
        [settings.WaveletType num2str(settings.WaveletType2)], ...
        'waveletLevels', settings.WaveletLevels, ...
        'lambda', settings.PriorsLambda,...
        'resampleRate',settings.Interp,...
        'meanCorrection',true);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Calculate HRV
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    output.ibiinfo.count=size(IBI,1); % total # of ibi
    output.ibiinfo.outliers=sum(art); % number of outliers

    %Time-Domain (using non-detrented ibi)
    output.time=timeDomainHRV(nIBI,settings.SDNNi*60,settings.pNNx);
    %output.time.mean=round(mean(nIBI(:,2).*1000)*10)/10;
    %output.time.meanHR=round(mean(60./nIBI(:,2))*10)/10;

    %Freq-Domain
    output.freq=freqDomainHRV(dIBI,settings.VLF,settings.LF, ...
        settings.HF,settings.AROrder,settings.WinWidth, ...
        settings.WinOverlap,settings.Points,settings.Interp);            

    %Nonlinear (using non-detrented ibi)
    output.nl=nonlinearHRV(nIBI,settings.m,settings.r, ...
        settings.n1,settings.n2,settings.breakpoint);        
    %Poincare
    output.poincare=poincareHRV(nIBI);

    %Time-Freq          
    output.tf=timeFreqHRV(dIBI,nIBI,settings.VLF,settings.LF, ...
        settings.HF,settings.AROrder, settings.tfWinSize, ...
        settings.tfOverlap,settings.Points,settings.Interp, ...
        {'ar','lomb','wavelet'});
    %%%%%%%%%%%%%%%%%%%%%%%
    
    clear  nIBI dIBI IBI

end

function ibi=loadIBI(f,opt)
    if ~exist(f,'file')
        error(['Error opening file: ' f])
        return
    end                

    ibi=[]; 
    DELIMITER = ',';
    HEADERLINES = opt.headerSize;

    %read ibi
    tmpData = importdata(f, DELIMITER, HEADERLINES);
    if HEADERLINES>0
        tmpData=tmpData.data;        
    end        

    %check ibi dimentions
    [rows cols] = size(tmpData);
    if rows==1
        tmpData=tmpData';
        ibi=zeros(cols,2);
        tmp=cumsum(tmpData);
        ibi(2:end,1)=tmp(1:end-1);
        ibi(:,2)=tmpData;
    elseif cols==1
        ibi=zeros(rows,2);
        tmp=cumsum(tmpData);
        ibi(2:end,1)=tmp(1:end-1);
        ibi(:,2)=tmpData;
    elseif rows<cols
        ibi=tmpData';
    else
        ibi=tmpData;
    end                                      
    clear tmpData       
end