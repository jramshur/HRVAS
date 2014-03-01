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
if (nargin < 1) || ~isstruct(opt)
    flagNoGui=true;
else
    flagNoGui=false;
end

if ~flagNoGui
    bcolor=[0.702 0.7216 0.8235]; %background color

    h.batchFigure=figure('Name','Batch Prcccess HRV', ...
        'Position',[20 50 500 500 ],...
        'Toolbar','none','Menubar','none');
    
    h.panel = uipanel('Parent',h.batchFigure,...
        'Units', 'normalized', 'Position',[0 0 1 1]);   
    h.lbl=uicontrol(h.panel,'Style','text', ...
        'String','Choose Directory to perform batch HRV analysis:',...
        'HorizontalAlignment','left',...
        'FontWeight', 'bold', 'FontSize',12,...
        'Units', 'normalized', 'Position',[.02 .9 .8 .08]);
    h.lblDir=uicontrol(h.panel,'Style','text', 'String','',...
        'Units', 'normalized', 'Position',[.02 .85 .8 .05],...
        'BackgroundColor','white',...
        'HorizontalAlignment','left');
    h.btnChooseDir=uicontrol(h.panel,'Style','pushbutton', ...
        'String','Choose Dir',...
        'Units', 'normalized', 'Position',[.83 .85 .14 .05],...
        'Callback', @btnChooseDir_Callback);
    
    h.list = uicontrol(h.panel,'Style','list',...
        'Units', 'normalized','Position',[.02 .34 .8 .5],'max',3,'min',1,...
        'Callback',@list_Callback);
    h.lblProcessing=uicontrol(h.panel,'Style','edit', ...
        'String','!!! PROCESSING !!!',...
        'Units', 'normalized', 'Position',[.15 .55 .5 .1],...
        'BackgroundColor','white', 'FontSize',12, ...
        'ForegroundColor', 'red',...
        'HorizontalAlignment','center','visible','off');
    h.lblType = uicontrol(h.panel,'Style','text',...
                'String','File Type:','HorizontalAlignment','right',...
                'Units', 'normalized','Position',[.45 .25 .2 .05],...
                'Callback',@updateList);
    h.popupType = uicontrol(h.panel,'Style','popupmenu',...
                'String',{'Any (*.*)','ibi (*.ibi)','text (*.txt)'},...
                'Units', 'normalized','Position',[.67 .25 .15 .05],...
                'Value',2,'BackgroundColor','white','Callback',@updateList);

    h.lblHeader = uicontrol(h.panel,'Style','text',...
                'String','# of Header Rows:', ...
                'HorizontalAlignment','right',...
                'Units', 'normalized','Position',[.45 .21 .2 .04]);
    h.txtHeader = uicontrol(h.panel,'Style','edit',...
                'String','0',...
                'Units', 'normalized','Position',[.67 .21 .15 .04],...
                'BackgroundColor','white');
            
    h.btnProc = uicontrol(h.panel,'Style','pushbutton',...
                'String','Run Batch',...
                'Units', 'normalized','Position',[.02 .06 .8 .11],...
                'fontsize',10,...
                'Callback',@btnProc_Callback);
    h.chkAll = uicontrol(h.panel,'Style','checkbox',...
                'String','Include all files.',...
                'Units', 'normalized','Position',[.02 .02 .8 .03],...
                'fontsize',10,'value',1);
            
else %procede without GUI
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
    hrv=batchGetHRV(fpaths,opt,flagNoGui);        

    %Export/save HRV
    saveHRV(hrv,opt,fpaths,outPath)
    disp('batchHRV Done!')
end
   
    function btnChooseDir_Callback(hObject, eventdata)
        % Callback function executed when btnChooseDir is pressed

        %get directory path
      path = uigetdir('Select directory containg subject files to export:');
        if path~=0
            set(h.lblDir,'String',path)

            extVal=get(h.popupType,'value');
            switch extVal
                case 1
                    ext='*.*';
                case 2
                    ext='*.ibi';
                case 3
                    ext='*.txt';
            end
            fileList = dir(fullfile(path, ext)); %get list of files
            %remove folders/dir from the list
            fileList(any([fileList.isdir],1))=[]; 
            %get file names only from fileList structure
            fnames = {fileList.name}; 

            set(h.list,'String',fnames)
            set(h.chkAll,'value',1)            
            str=['Run Batch (' num2str(size(fnames,2)) ' files)'];
            set(h.btnProc,'string',str)

        end
    end

    function updateList(hObject, eventdata)
        path = get(h.lblDir,'String');
        if ~isempty(path)
            extVal=get(h.popupType,'value');
            switch extVal
                case 1
                    ext='*.*';
                case 2
                    ext='*.ibi';
                case 3
                    ext='*.txt';
            end
            fileList = dir(fullfile(path, ext)); %get list of files
            %remove any folder/dir from the list
            fileList(any([fileList.isdir],1))=[]; 
            %get file names only from fileList structure
            fnames = {fileList.name}; 

            set(h.list,'String',fnames)
            set(h.chkAll,'value',1)            
            str=['Run Batch (' num2str(size(fnames,2)) ' files)'];
            set(h.btnProc,'string',str)
        end
    end

    function btnProc_Callback(hObject, eventdata)        
        [fname, pathname] = uiputfile(...
        {'*.csv','Comma Delimited (*.csv)';...
        '*.xlsx','Excel (*.xlsx)'},...
        'Export HRV as',...
        'hrv.csv');
        if isequal(fname,0) || isequal(pathname,0)
            error('Please choose a export file name.')
            return
        else
            outPath=fullfile(pathname,fname);
        end
        
        set(h.lblProcessing,'visible','on');
        drawnow;
        
        %get list of files
        fnames=get(h.list,'String');
        if get(h.chkAll,'value')==0 % 
            iselected = get(h.list,'Value');
            fnames = fnames(iselected);
        end
        if isempty(fnames)
            error('No files to process.')
            return
        end
        %build array of full file paths
        path=get(h.lblDir,'String');
        fpaths=cell(length(fnames),1);
        for f=1:length(fnames)
            fpaths{f}=fullfile(path,fnames{f});
        end
        
        %get HRV
        hrv=batchGetHRV(fpaths,opt,flagNoGui);        
        
        %Export HRV
        saveHRV(hrv,opt,fpaths,outPath)
        set(h.lblProcessing,'visible','off');
        drawnow;
        
        clear hrv
    end       

    function list_Callback(hObject, eventdata)
        %get count of selected
        fnames=get(h.list,'String');
        iselected = get(h.list,'Value');
        fnames = fnames(iselected);                 
        
        if ~isempty(fnames)
            set(h.chkAll,'value',0)            
        else
            set(h.chkAll,'value',1)
        end
        
        if get(h.chkAll,'value')            
            str=['Run Batch (' num2str(sum(iselected)) ' files)'];            
        else
            str=['Run Batch (' num2str(size(fnames,1)) ' files)'];
        end
        set(h.btnProc,'string',str)

    end
end

function saveHRV(hrv,opt,fList,outPath)   
       exportHRV(outPath,fList,hrv,opt)    
end

function hrv=batchGetHRV(fList,opt,flagNoGui)
    %Preallocate hrv array
    %hrv=repmat(struct('b',0,'a',0),1,length(fList));

    %create waitbar to display time remaining
    if ~flagNoGui
        abort=false;
        h=waitbar(0,'Processing: 0% complete.','CreateCancelBtn',@cancelcb);
        pause(0.05); drawnow;    
    else
        disp('Processing: 0% complete.')
    end
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
        %Update waitbar
         bar=round(f/nFiles*100);
        if ~flagNoGui           
            waitbar(bar/100,h,['Processing: ' num2str(bar)  ...
                '% complete. (~' num2str(timeRem) ' min)'])
            drawnow;
            if abort
                warning('Batch canceled.');
                delete(h)
                return; 
            end
        else
            disp(['Processing: ' num2str(bar) ...
                '% complete. (~' num2str(timeRem) ' min)'])
        end
    end
    if ~flagNoGui; delete(h); end;
    
    
    function cancelcb(a1, a2)
        abort = true;    
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