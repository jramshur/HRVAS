%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Copyright (C) 2010, John T. Ramshur, jramshur@gmail.com
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
% See gpl.txt for license information. See version_log.rtf for version
% and update information.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function HRVAS
% HRVAS: GUI to calculate heart rate variability (HRV) measures
%
% Version: 1.0.3
% - uitab/uitabgroup controls have been changed to accomidate
%  Matlab 2016a
% - added explicit font sizes for several GUI elements. The defaults apperantly
%   that have changed during MATLAB updates. 
%
% Notes: 
% TODO: 
%   -clean up code
%   -add option to specify number of bins in IBI histogram and 
%       used for tinn/HRVi
%   -add option to set freq range for PSD plot
%   -insert captions to aid in adding future analysis
%       modules/tabs
%   -add error handling

    %% GUI Defaults

    figH=650;   %height of GUI (pixels)
    figW=1000;  %width of GUI (pixels)
    ctlHpx=20;  %height wanted for controls (pixels)
    ctlWpx=45;  %width wanted for controls (pixels)    
    color.back=[0.8 0.8 0.8]; %background color
    color.hist.face=[.5 .5 .9]; %histogram color
    color.hist.edge='black';
    color.vlf=[.5 .5 1];    %vlf color
    color.lf=[.7 .5 1];     %lf color
    color.hf=[.5 1 1];      %hf color
    color.waterfall.face=[.9 .9 .9];
    color.status.back=[1 1 .4];  %status indicator background
    color.status.face=[1 .4 .4]; %status indicator face

    %% Global Variables

    global HRV h flagProcessed flagPreviewed nIBI dIBI IBI trend
    settings=[];%analysis options/settings
    IBI=[]; %ibi data
    nIBI=[]; %non-detrended ibi
    dIBI=[]; %detrended ibi data
    HRV=[]; %hrv data
    h=[];   %gui handles
    flagProcessed=false; %flag to indicate that HRV has been proc
    flagPreviewed=false; %flag to indicate previewing IBI

    %% GUI: Main Figure
    
    %Main Figure
    h.MainFigure = figure('Name','HRVAS','NumberTitle','off', ...
        'HandleVisibility','on', ...
        'Position',[20 50 figW figH ],...
        'Toolbar','none','Menubar','none',...
        'CloseRequestFcn',@closeGUI);
    %Set Icon
    warning('off', ...
        'MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame');
    jframe=get(h.MainFigure,'javaframe');
    jIcon=javax.swing.ImageIcon('hrvas_icon.png');
    jframe.setFigureIcon(jIcon);
    
    %File Menu
    h.menuFile = uimenu('Label','File','Parent',h.MainFigure);
    uimenu(h.menuFile,'Label','Load Settings','Callback', ...
        @loadSet_Callback);
    uimenu(h.menuFile,'Label','Save Settings','Callback', ...
        @saveSet_Callback);
    uimenu(h.menuFile,'Label','Export HRV Results', ...
        'Separator','on','Callback',@menu_exportHRV);
    uimenu(h.menuFile,'Label','Export IBI', ...
        'Callback',@menu_exportIBI_1);
    uimenu(h.menuFile,'Label','Export IBI (ibi only)', ...
        'Callback',@menu_exportIBI_2);
    uimenu(h.menuFile,'Label','Export IBI (processed)', ...
        'Callback',@menu_exportIBI_3);
    uimenu(h.menuFile,'Label','Batch Process', ...
        'Separator','on','Callback', @batch_Callback);    
    uimenu(h.menuFile,'Label','Set File Header Size', ...
        'Separator','on','Callback',@getHeaderSize);
    %View Menu
    h.menuView = uimenu('Label','View','Parent',h.MainFigure);
     uimenu(h.menuView,'Label','Trendline FFT', ...
         'Callback',@trendlineFFT);
     uimenu(h.menuView,'Label','Show/Hide Menu', ...
         'Callback',@showMenubar);
     uimenu(h.menuView,'Label','Show/Hide Toolbar', ...
         'Callback',@showToolbar);    
    %Help Menu
     h.menuHelp = uimenu('Label','Help','Parent',h.MainFigure);
     uimenu(h.menuHelp,'Label','About','Callback',@showAbout);
     uimenu(h.menuHelp,'Label','User''s Guide','Callback','');
     
    %% GUI: Select IBI File Controls

    h.panelFile = uipanel('Parent',h.MainFigure,...
        'Units', 'normalized', 'Position',[0 .95 1 .05],...
        'BackgroundColor',color.back);
    h.txtFile=uicontrol(h.panelFile,'Style','edit', ...
        'String','C:/', 'Units', 'normalized', ...
        'Position',[.01 .08 .83 .8],'BackgroundColor','white',...
        'HorizontalAlignment','left');
    h.btnChooseFile=uicontrol(h.panelFile, ...
        'Style','pushbutton', 'String','Choose IBI File',...
        'Units', 'normalized', 'Position',[.845 .08 .1 .8],...
        'Callback', @btnChooseFile_Callback);    
    h.btnRun=uicontrol(h.panelFile,'Style','pushbutton', ...
        'String','Run', 'Units', 'normalized', ...
        'Position',[.947 .08 .05 .8],'Callback', @btnRun_Callback);
    
    %%  GUI: Preview Controls
          
    %preview IBI panel
    h.panelIBI = uipanel('Parent',h.MainFigure,...
        'Units', 'normalized', 'Position',[0 .7 1 .25]);                       
    %axes handle        
    h.axesIBI = axes('Parent', h.panelIBI, ...
        'HandleVisibility','callback', ...
        'Units', 'normalized', 'Position',[.05 0.27 0.93 0.65],...
        'FontSize',8,'Box','on');
    xlabel(h.axesIBI,'Time (hh:mm:ss)','FontSize',10);
    ylabel(h.axesIBI,'IBI (s)','FontSize',10);
    h.lblStatus=uicontrol(h.panelIBI,'Style','edit', 'String','',...
        'Units', 'normalized', 'Position',[.42 .5 .2 .2],...
        'BackgroundColor',color.status.back, 'FontSize',12, ...
        'ForegroundColor', color.status.face, 'fontweight','b',...
        'HorizontalAlignment','center','visible','off');
        
    %% GUI: Analysis Options
    
    %Options panel
    h.panelOptions = uipanel('Parent',h.MainFigure,...
        'Units', 'normalized', 'Position',[0 0 .5 .7],...
        'BackgroundColor',color.back);            
    h.lblHRV=uicontrol(h.panelOptions,'Style','text', ...
        'String','HRV Analysis Options',...
        'Units', 'normalized', 'Position',[.01 .93 .48 .07],...
        'FontWeight', 'bold', 'FontSize',12,...
        'BackgroundColor',color.back,...
        'HorizontalAlignment','left');
    
    %% GUI: Analysis Options - Preprocessing   

    h.panelPre = uipanel('Parent',h.panelOptions, ...
        'title','IBI Preprocessing',...
        'Units', 'normalized', 'Position',[.01 .17 .48 .77],...
        'FontWeight','bold','BackgroundColor',color.back);        
    
    %calcuate normalized units to use for controls in this panel
    posParent1=get(h.panelOptions,'position');
    posParent2=get(h.panelPre,'position');
    ctlH=ctlHpx/(figH*posParent1(4)*posParent2(4));
    ctlW=ctlWpx/(figW*posParent1(3)*posParent2(3));

    %Preview Button
     h.btnPreview=uicontrol(h.panelPre,'Style','pushbutton', ...
        'String','Preview', 'Units', 'normalized', ...
        'Position',[.72 .93 .25 .06],'FontSize',8,...
        'Callback', @btnPreview_Callback);
    
    %Ectopic Detection
    h.lblArtLocate=uicontrol(h.panelPre,'Style','text', ...
        'String','Ectopic Detection',...
        'Units', 'normalized', 'Tag','lbl1', 'fontweight','b',...
        'HorizontalAlignment','left','BackgroundColor', color.back,...
        'Position',[.05 .92 .6 ctlH]);
    h.chkArtLocPer = uicontrol(h.panelPre,'Style','checkbox',...
        'String','percent','Value',0,'BackgroundColor',color.back,...
        'Units', 'normalized', 'Tag','lblArtLoc1',...
        'Position',[.07 .8 .3 ctlH]);
    h.txtArtLocPer=uicontrol(h.panelPre,'Style','edit', 'String','20',...
        'Units', 'normalized', 'Tag','txtArtLoc1',...
        'HorizontalAlignment', 'center','BackgroundColor','w',...
        'Position',[.35 .8 ctlW ctlH]);
    h.chkArtLocSD = uicontrol(h.panelPre,'Style','checkbox',...
        'String','std dev','Value',0,'BackgroundColor',color.back,...
        'Units', 'normalized','Tag','lblArtLoc2',...
        'Position',[.07 .75 .3 ctlH]);
    h.txtArtLocSD=uicontrol(h.panelPre,'Style','edit', 'String','3',...
        'Units', 'normalized', 'Tag','txtArtLoc2',...
        'HorizontalAlignment', 'center','BackgroundColor','w',...
        'Position',[.35 .75 ctlW ctlH]);
    h.chkArtLocMed = uicontrol(h.panelPre,'Style','checkbox',...
        'String','median','Value',0,'BackgroundColor',color.back,...
        'Units', 'normalized', 'Tag','lblArtLoc3',...
        'Position',[.07 .7 .3 ctlH]);
    h.txtArtLocMed=uicontrol(h.panelPre,'Style','edit', 'String','4',...
        'Units', 'normalized', 'Tag','txtArtLoc3',...
        'HorizontalAlignment', 'center','BackgroundColor','w',...
        'Position',[.35 .7 ctlW ctlH]);
    %Ectopic replacment
    h.lblArtReplace=uicontrol(h.panelPre,'Style','text', ...
        'String','Ectopic Replacement',...
        'Units', 'normalized', 'fontweight','b', 'Tag','lblArtReplace',...
        'HorizontalAlignment','left','BackgroundColor',color.back,...
        'Position',[.05 .65 .6 ctlH]);
    h.btngrpArtReplace = uibuttongroup('Parent',h.panelPre, ...
        'Units','normalized','bordertype','none', ...
        'BackgroundColor',color.back ,'Visible','on', ...         
        'Position',[0 .6 1 ctlH*5.4]);
    posParent3=get(h.btngrpArtReplace,'position');
    h.lblTmp=uicontrol(h.panelPre,'Style','text', 'Units', 'normalized',...
        'Tag','lblTmp',...
        'Position',posParent3, 'visible','off');    
    ctlH2=ctlHpx/(figH*posParent1(4)*posParent2(4)*posParent3(4));
    ctlW2=ctlWpx/(figW*posParent1(3)*posParent2(3)*posParent3(3));
    h.radioArtReplaceNone = uicontrol(h.btngrpArtReplace, ...
        'Style','radiobutton', 'String','None', 'Units','normalized', ...
        'BackgroundColor',color.back, 'Tag','lblArtReplace1', ...
        'HorizontalAlignment','left', 'Position',[.07 1-ctlH2 .35 ctlH2]);
    h.radioArtReplaceMean = uicontrol(h.btngrpArtReplace, ...
        'Style','radiobutton', 'String','Mean', 'Units','normalized', ...
        'BackgroundColor',color.back,'Tag','lblArtReplace2', ...
        'HorizontalAlignment','left', 'Position',[.07 .68 .35 ctlH2]);
    h.radioArtReplaceMed = uicontrol(h.btngrpArtReplace, ...
        'Style','radiobutton','String','Median', 'Units','normalized', ...
        'BackgroundColor',color.back,'Tag','lblArtReplace3', ...
        'HorizontalAlignment','left', 'Position',[.07 .67 .35 ctlH2]);
    h.radioArtReplaceSpline = uicontrol(h.btngrpArtReplace, ...
        'Style','radiobutton','String','Spline','Units','normalized', ...
        'BackgroundColor',color.back,'Tag','lblArtReplace4', ...
        'HorizontalAlignment','left', 'Position',[.07 .66 .35 ctlH2]);
    h.radioArtReplaceRem = uicontrol(h.btngrpArtReplace, ...
        'Style','radiobutton','String','Remove','Units','normalized', ...
        'BackgroundColor',color.back, 'Tag','lblArtReplace5', ...
        'HorizontalAlignment','left', 'Position',[.07 0 .35 ctlH2]);
    h.txtArtReplaceMean=uicontrol(h.btngrpArtReplace, ...
        'Style','edit', 'String','9', 'Units', 'normalized', ...
        'HorizontalAlignment', 'center','BackgroundColor','w',...
        'Position',[.35 1-ctlH2 ctlW2 ctlH2]);  
    h.txtArtReplaceMed=uicontrol(h.btngrpArtReplace,'Style','edit', ...
        'String','5', 'Units', 'normalized', ...
        'HorizontalAlignment', 'center','BackgroundColor','w',...
        'Position',[.35 1 ctlW2 ctlH2]);
    %align radiobutton within buttongroup
    align(findobj(h.btngrpArtReplace,'-regexp','Tag','lbl(\w*)'),...
        'VerticalAlignment','Distribute')
    %align textboxes within buttongroup
    plbl=get(h.radioArtReplaceMean,'position');
    ptxt=get(h.txtArtReplaceMean,'position');
    set(h.txtArtReplaceMean,'position',[ptxt(1) plbl(2) ptxt(3) ptxt(4)])
    plbl=get(h.radioArtReplaceMed,'position');
    ptxt=get(h.txtArtReplaceMed,'position');
    set(h.txtArtReplaceMed,'position',[ptxt(1) plbl(2) ptxt(3) ptxt(4)])
    
    %Detrending
    h.lblDetrend=uicontrol(h.panelPre,'Style','text', ...
        'String','Detrending','Units','normalized', 'Tag','lblDetrend', ...
        'fontweight','b','HorizontalAlignment','left', ...
        'BackgroundColor',color.back,'Position',[.05 .55 .4 ctlH]);
    h.lblDetrendMethod=uicontrol(h.panelPre,'Style','text', ...
        'String','Method :','Units', 'normalized', ...
        'Tag','lblDetrendMethod', 'HorizontalAlignment','left', ...
        'BackgroundColor',color.back, 'Position',[.07 .5 ctlW ctlH]);
    h.listDetrend = uicontrol(h.panelPre,'Style','popupmenu',...
        'tag','txtDetrendMethod',...
        'String',{'None','Wavelet','Matlab Smooth','Polynomial', ...
        'Wavelet Packet', 'Smothness Priors'}, ...
        'Value',1,'BackgroundColor','white', 'Units', 'normalized',...
        'Position',[.35 .5 .5 ctlH], ...
        'Callback', @detrendChange_Callback);
    %Matlab Smoothing Options
    h.lblSmoothMethod=uicontrol(h.panelPre,'Style','text', ...
        'String','Method :','Units', 'normalized', 'Visible','off', ...
        'Tag','txtWav1', 'HorizontalAlignment','left', ...
        'BackgroundColor',color.back, 'Position',[.07 .4 .3 ctlH]);
    h.lblSmoothSpan=uicontrol(h.panelPre,'Style','text', ...
        'String','Span :', 'Units', 'normalized', 'Visible','off', ...
        'Tag','txtWav2', 'HorizontalAlignment','left', ...
        'BackgroundColor',color.back, 'Position',[.07 .27 .2 ctlH]);
    h.lblSmoothDegree=uicontrol(h.panelPre,'Style','text', ...
        'String','Degree :','Units', 'normalized', 'Visible','off', ...
        'Tag','txtWav3','HorizontalAlignment','left', ...
        'BackgroundColor',color.back, 'Position',[.07 .16 .2 ctlH]);
    h.listSmoothMethod = uicontrol(h.panelPre,'Style','popupmenu',...
        'String',{'moving','lowess','loess','sgolay','rlowess', ...
        'rloess'},'Value',3,'BackgroundColor','white',...
        'Units', 'normalized', 'Visible','off','Tag','txtWav1',...
        'Position',[.35 .4 .27 ctlH], ...
        'Callback', @detrendChange_Callback);
    h.txtSmoothSpan=uicontrol(h.panelPre,'Style','edit', 'String','5',...
        'Units', 'normalized', 'Visible','off','Tag','txtWav2',...
        'HorizontalAlignment','center','BackgroundColor','white',...
        'Position',[.35 .27 ctlW ctlH],...
        'Callback', @optChange_Callback);
    h.txtSmoothDegree=uicontrol(h.panelPre,'Style','edit','String','0.1',...
        'Units', 'normalized', 'Visible','off','Tag','txtWav3',...
        'HorizontalAlignment','center','BackgroundColor','white',...
        'Position',[.35 .16 ctlW ctlH],...
        'Callback', @optChange_Callback);
    %Polynomial Detrending
    h.lblPoly=uicontrol(h.panelPre,'Style','text', 'String','Order :',...
        'Units', 'normalized', 'Visible','off','Tag','txtWav1',...
        'HorizontalAlignment','left','BackgroundColor',color.back,...
        'Position',[.07 .5 .2 ctlH]);
    h.listPoly = uicontrol(h.panelPre,'Style','popupmenu',...
        'tag','txtWav1', 'visible','off',...
        'String',{'1st Order','2nd Order','3rd Order'}, ...
        'Value',1,'BackgroundColor','white', 'Units', 'normalized',...
        'Position',[.35 .5 .35 ctlH],...
        'Callback', @detrendChange_Callback);    
    %Wavelet Detrending Options
    h.lblWaveletType=uicontrol(h.panelPre,'Style','text', ...
        'String','Type :','Units', 'normalized', 'Visible','off', ...
        'Tag','lblWav1','HorizontalAlignment','left', ...
        'BackgroundColor',color.back, 'Position',[.07 .5 .2 ctlH]);
    h.lblWaveletType2=uicontrol(h.panelPre,'Style','text', ...
        'String','n :','Units', 'normalized', 'Visible','off', ...
        'Tag','lblWav2', 'HorizontalAlignment','left', ...
        'BackgroundColor',color.back, 'Position',[.07 .45 .2 ctlH]);
    h.lblWaveletLevels=uicontrol(h.panelPre,'Style','text', ...
        'String','Levels :', 'Units', 'normalized', 'Visible','off', ...
        'Tag','lblWav3', 'HorizontalAlignment','left', ...
        'BackgroundColor',color.back, 'Position',[.07 .02 .2 ctlH]);
    h.listWaveletType = uicontrol(h.panelPre,'Style','popupmenu',...
        'String',{'db','sym','coif','gaus'},'Value',1, ...
        'BackgroundColor','white','Units','normalized','Visible','off', ...
        'Tag','txtWav1', 'Position',[.35 .4 .27 ctlH],...
        'Callback', @detrendChange_Callback);
    h.txtWaveletType2=uicontrol(h.panelPre,'Style','edit', 'String','3',...
        'Units', 'normalized', 'Visible','off', 'Tag','txtWav2',...
        'HorizontalAlignment','center','BackgroundColor','white',...
        'Position',[.35 .27 ctlW ctlH],...
        'Callback', @optChange_Callback);
    h.txtWaveletLevels=uicontrol(h.panelPre,'Style','edit', 'String','6',...
        'Units', 'normalized', 'Visible','off', 'Tag','txtWav3',...
        'HorizontalAlignment','center','BackgroundColor','white',...
        'Position',[.35 .16 ctlW ctlH],...
        'Callback', @optChange_Callback);
    %Smoothness Priors
    h.lblPriorsLambda=uicontrol(h.panelPre,'Style','text', ...
        'String','Lambda :','Units', 'normalized', 'Visible','off', ...
        'Tag','txtWav1', 'HorizontalAlignment','left', ...
        'BackgroundColor',color.back, 'Position',[.07 .4 .2 ctlH]);
    h.txtPriorsLambda = uicontrol(h.panelPre,'Style','edit',...
        'String','10','BackgroundColor','white', 'Tag','txtWav1',...
        'Units', 'normalized', 'Visible','off', ...
        'Position',[.35 .4 ctlW ctlH],...
        'Callback', @detrendChange_Callback);
    
    %align controls
    lbl=findobj(h.panelPre,'-regexp','Tag','lbl(\w*)','-depth',1);
    txt=findobj(h.panelPre,'-regexp','Tag','txt(\w*)','-depth',1);
    align(lbl, 'VerticalAlignment','Distribute')    
    %loop through all freq panel controls to align controls
    for l=1:length(lbl)
        for t=1:length(txt)
            taglbl=get(lbl(l),'Tag'); %get lbl tag
            tagtxt=get(txt(t),'Tag'); %get txt tag
            %move txt vert position to match lbl position if tags "match"
            if strcmp(taglbl(4:end),tagtxt(4:end))
                poslbl=get(lbl(l),'position'); %get lbl position
                postxt=get(txt(t),'position'); %get txt position
                postxt(2)=poslbl(2); %set vertical position
                set(txt(t),'position',postxt); %move txt control
            end
        end
    end
    set(h.btngrpArtReplace,'position',get(h.lblTmp,'position'))
    clear i j lbl txt postxt poslbl taglbl tagtxt
    
    %% GUI: Analysis Options - Time Domain

    h.panelOptTime = uipanel('Parent',h.panelOptions, ...
        'title','Time Domain',...
        'Units', 'normalized', 'Position',[.01 .01 .235 .15],...
        'FontWeight','bold', 'BackgroundColor',color.back);
    
    %calcuate normalized units to use for controls in this panel
    posParent1=get(h.panelOptions,'position');
    posParent2=get(h.panelOptTime,'position');
    ctlH=ctlHpx/(figH*posParent1(4)*posParent2(4));
    ctlW=ctlWpx/(figW*posParent1(3)*posParent2(3));

    %Future update:
    %add checkbox for user to select whether to calculate time domain hrv
    %p1=get(h.MainFigure,'position'); p2=get(h.panelOptions,'position');
    %p3=get(h.panelOptTime,'position');
    %wh=14/(p1(3)*p2(3)); %convert 15 px to normalized units
    %dw=5/(p1(3)*p2(3));%convert 5px
    %h.chkTime=uicontrol(h.panelOptions,'Style','checkbox',...
    % 'String','','value',1, 'Units', 'normalized', ...
    % 'Position',[p3(1)+dw p3(2)+p3(4)-wh wh wh], ...
    % 'backgroundcolor',color.back); 
        
    h.lblPNNx=uicontrol(h.panelOptTime,'Style','text', 'String','pNNx :',...
        'Units', 'normalized', 'Position',[.05 .55 .35 .35],...
        'HorizontalAlignment','left', 'BackgroundColor',color.back);
    h.txtPNNx=uicontrol(h.panelOptTime,'Style','edit', 'String','50',...
        'Units', 'normalized', 'Position',[.4 .55 .25 .35],...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Callback', @optChange_Callback);
    uicontrol(h.panelOptTime,'Style','text', 'String','(ms)',...
        'Units', 'normalized', 'Position',[.4+.25+.05 .55 .2 .35],...
        'HorizontalAlignment','left', 'BackgroundColor',color.back);
    h.lblSDNNi=uicontrol(h.panelOptTime,'Style','text', ...
        'String','SDNNi :',...
        'Units', 'normalized', 'Position',[.05 .1 .35 .35],...
        'HorizontalAlignment','left', 'BackgroundColor',color.back);
    h.txtSDNNi=uicontrol(h.panelOptTime,'Style','edit', 'String','1',...
        'Units', 'normalized', 'Position',[.4 .1 .25 .35],...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Callback', @optChange_Callback);
    uicontrol(h.panelOptTime,'Style','text', 'String','(min)',...
        'Units', 'normalized', 'Position',[.4+.25+.05 .1 .25 .35],...
        'HorizontalAlignment','left', 'BackgroundColor',color.back);    
    
    %% GUI: Analysis Options - Freq Domain
    
    h.panelOptFreq = uipanel('Parent',h.panelOptions, ...
        'title','Freq Domain',...
        'Units', 'normalized', 'Position',[.51 .27 .48 .67],...
        'FontWeight','bold', 'BackgroundColor',color.back);
    
    %calcuate normalized units to use for controls in this panel
    posParent1=get(h.panelOptions,'position');
    posParent2=get(h.panelOptFreq,'position');
    ctlH=ctlHpx/(figH*posParent1(4)*posParent2(4));
    ctlW=ctlWpx/(figW*posParent1(3)*posParent2(3));

    %LABELS  
    % Bands
    h.lblBands=uicontrol(h.panelOptFreq,'Style','text', ...
        'String','Frequency Bands', 'Units', 'normalized', ...
        'HorizontalAlignment','left','BackgroundColor',color.back, ...
        'fontweight','b',...
        'Position',[.05 .91 .5 ctlH]);
    h.lblVLF=uicontrol(h.panelOptFreq,'Style','text', ...
        'String','VLF (Hz) :',...
        'Units', 'normalized', 'Tag','OptFreq lblVLF', ...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.07 .82 .3 ctlH]);
    h.lblLF=uicontrol(h.panelOptFreq,'Style','text', ...
        'String','LF (Hz) :',...
        'Units', 'normalized', 'Tag','OptFreq lblLF', ...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.07 .73 .3 ctlH]);
    h.lblHF=uicontrol(h.panelOptFreq,'Style','text', ...
        'String','HF (Hz) :',...
        'Units', 'normalized', 'Tag','OptFreq lblHF', ...
        'HorizontalAlignment','left', 'BackgroundColor',color.back, ...
        'Position',[.07 .64 .3 ctlH], ...
        'Callback', @optChange_Callback);    
    h.lblVLFHyph=uicontrol(h.panelOptFreq,'Style','text', 'String','-',...
        'Units', 'normalized', 'Tag','OptFreq txtVLF', ...
        'HorizontalAlignment','center','BackgroundColor',color.back,...
        'Position',[.35+ctlW .82 .6-.35-ctlW ctlH]);    
    h.lblLFhyph=uicontrol(h.panelOptFreq,'Style','text', 'String','-',...
        'Units', 'normalized', 'Tag','OptFreq txtLF',...
        'HorizontalAlignment','center','BackgroundColor',color.back,...
        'Position',[.35+ctlW .73 .6-.35-ctlW ctlH]);    
    h.lblHFhyph=uicontrol(h.panelOptFreq,'Style','text', 'String','-',...
        'Units', 'normalized', 'Tag','OptFreq txtHF', ...
        'HorizontalAlignment','center','BackgroundColor',color.back,...
        'Position',[.35+ctlW .64 .6-.35-ctlW ctlH]);    
    %Interpolation
    h.lblInterp1=uicontrol(h.panelOptFreq,'Style','text', ...
        'String','IBI Interpolation',...
        'Units', 'normalized','Tag','OptFreq lbl', 'fontweight', 'b', ...
        'HorizontalAlignment','left', 'BackgroundColor',color.back, ...
        'Position',[.05 .52 .6 ctlH]);
    h.lblInterp=uicontrol(h.panelOptFreq,'Style','text', ...
        'String','Interpolation Rate (Hz) :',...
        'Units', 'normalized', 'Tag','OptFreq lblInterp',...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.07 .45 .6 ctlH]);       
    %Points in calculated PSD
    h.lblPnts=uicontrol(h.panelOptFreq,'Style','text', ...
        'String','Points in PSD', 'Units', 'normalized', ...
        'Tag','OptFreq lbl', 'HorizontalAlignment','left', ...
        'BackgroundColor',color.back,'fontweight', 'b',...
        'Position',[.05 .4 .6 ctlH]);
    h.lblPoints=uicontrol(h.panelOptFreq,'Style','text',...
        'String','Points in PSD (pts) :',...
        'Units', 'normalized', 'Tag','OptFreq lblPoints', ...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.07 .35 .6 ctlH]);    
    %Welch Windowing
    h.lblWelch=uicontrol(h.panelOptFreq,'Style','text', ...
        'String','Welch Options',...
        'Units', 'normalized', 'Tag','OptFreq lbl', ...
        'HorizontalAlignment','left', 'BackgroundColor',color.back, ...
        'fontweight', 'b', 'Position',[.05 .3 .6 ctlH]);
    h.lblWinWidth=uicontrol(h.panelOptFreq,'Style','text',...
        'String','Window Width (pts) :',...
        'Units', 'normalized', 'Tag','OptFreq lblWinWidth', ...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.07 .25 .6 ctlH]);   
    h.lblWinOverlap=uicontrol(h.panelOptFreq,'Style','text',...
        'String','Window Overlap (pts) :',...
        'Units', 'normalized', 'Tag','OptFreq lblWinOverlap', ...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.07 .2 .6 ctlH]);     
    %Burg AR Model
    h.lblAROrder=uicontrol(h.panelOptFreq,'Style','text', ...
        'String','AR Options',...
        'Units', 'normalized', 'Tag','OptFreq lbl', ...
        'HorizontalAlignment','left', 'BackgroundColor',color.back, ...
        'fontweight', 'b', 'Position',[.05 .15 .6 ctlH]);
    h.lblAROrder=uicontrol(h.panelOptFreq,'Style','text',...
        'String','Burg Model Order :',...
        'Units', 'normalized', 'Tag','OptFreq lblAROrder', ...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.07 .02 .6 ctlH]);   
        
  %TEXTBOX
    %Bands
    h.txtVLF1=uicontrol(h.panelOptFreq,'Style','edit', 'String','0',...
        'Units', 'normalized', 'Tag','OptFreq txtVLF', ...
        'HorizontalAlignment','center','BackgroundColor',color.vlf,...
        'Position',[.35 .82 ctlW ctlH],...
        'Callback', @optChange_Callback);    
    h.txtVLF2=uicontrol(h.panelOptFreq,'Style','edit', 'String','0.04',...
        'Units', 'normalized', 'Tag','OptFreq txtVLF',...
        'HorizontalAlignment','center','BackgroundColor',color.vlf,...
        'Position',[.6 .82 ctlW ctlH],...
        'Callback', @optChange_Callback);
    h.txtLF1=uicontrol(h.panelOptFreq,'Style','edit', 'String','0.04',...
        'Units', 'normalized', 'Tag','OptFreq txtLF',...
        'HorizontalAlignment','center','BackgroundColor',color.lf, ...
        'Position',[.35 .73 ctlW ctlH]);    
    h.txtLF2=uicontrol(h.panelOptFreq,'Style','edit', 'String','0.15',...
        'Units', 'normalized', 'Tag','OptFreq txtLF', ...
        'HorizontalAlignment','center','BackgroundColor',color.lf,...
        'Position',[.6 .73 ctlW ctlH],...
        'Callback', @optChange_Callback);
    h.txtHF1=uicontrol(h.panelOptFreq,'Style','edit', 'String','0.15',...
        'Units', 'normalized', 'Tag','OptFreq txtHF',...
        'HorizontalAlignment','center','BackgroundColor',color.hf,...
        'Position',[.35 .64 ctlW ctlH],...
        'Callback', @optChange_Callback);    
    h.txtHF2=uicontrol(h.panelOptFreq,'Style','edit', 'String','0.4',...
        'Units', 'normalized', 'Tag','OptFreq txtHF', ...
        'HorizontalAlignment','center','BackgroundColor',color.hf,...
        'Position',[.6 .64 ctlW ctlH],...
        'Callback', @optChange_Callback);
    %Interpolation
     h.txtInterp=uicontrol(h.panelOptFreq,'Style','edit', 'String','2',...
        'Units', 'normalized','Tag','OptFreq txtInterp', ...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Position',[.6 .45 ctlW ctlH],...
        'Callback', @optChange_Callback);
    %Points
    h.txtPoints=uicontrol(h.panelOptFreq,'Style','edit', ...
        'String','1024',...
        'Units', 'normalized', 'Tag','OptFreq txtPoints',...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Position',[.6 .35 ctlW ctlH],...
        'Callback', @optChange_Callback);
    %Welch
    h.txtWinWidth=uicontrol(h.panelOptFreq,'Style','edit', ...
        'String','128',...
        'Units', 'normalized', 'Tag','OptFreq txtWinWidth',...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Position',[.6 .25 ctlW ctlH],...
        'Callback', @optChange_Callback);
    h.txtWinOverlap=uicontrol(h.panelOptFreq,'Style','edit', ...
        'String','64',...
        'Units', 'normalized', 'Tag','OptFreq txtWinOverlap',...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Position',[.6 .2 ctlW ctlH],...
        'Callback', @optChange_Callback);
    %Burg
     h.txtAROrder=uicontrol(h.panelOptFreq,'Style','edit', 'String','16',...
        'Units', 'normalized', 'Tag','OptFreq txtAROrder', ...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Position',[.6 .01 ctlW ctlH],...
        'Callback', @optChange_Callback);
    
    %align controls
    lbl=findobj(h.panelOptFreq,'-regexp','Tag','OptFreq lbl(\w*)');
    txt=findobj(h.panelOptFreq,'-regexp','Tag','OptFreq txt(\w*)');
    align(lbl, 'VerticalAlignment','Distribute')
    
    %loop through all freq panel controls to align controls
    for l=1:length(lbl)
        for t=1:length(txt)
            taglbl=get(lbl(l),'Tag'); %get lbl tag
            tagtxt=get(txt(t),'Tag'); %get txt tag
            %move txt vert position to match lbl position if tags "match"
            if strcmp(taglbl(12:end),tagtxt(12:end))
                poslbl=get(lbl(l),'position'); %get lbl position
                postxt=get(txt(t),'position'); %get txt position
                postxt(2)=poslbl(2); %set vertical position
                set(txt(t),'position',postxt); %move txt control
            end
        end
    end
    clear i j lbl txt postxt poslbl taglbl tagtxt
    
%% GUI: Analysis Options - Nonlinear

    h.panelOptNL = uipanel('Parent',h.panelOptions,'title','Nonlinear',...
        'Units', 'normalized', 'Position',[.51 .01 .48 .25],...
        'FontWeight','bold', 'BackgroundColor',color.back);
    
    %calcuate normalized units to use for controls in this panel
    posParent1=get(h.panelOptions,'position');
    posParent2=get(h.panelOptNL,'position');
    ctlH=ctlHpx/(figH*posParent1(4)*posParent2(4));
    ctlW=ctlWpx/(figW*posParent1(3)*posParent2(3));
    
    %SampEn
    h.lblSampEn=uicontrol(h.panelOptNL,'Style','text', 'String','SampEn',...
        'Units', 'normalized', 'fontweight','b','Tag','lbl1',...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.05 .75 .3 ctlH]);
    h.lblSampEnR=uicontrol(h.panelOptNL,'Style','text', 'String','r :',...
        'Units', 'normalized', 'Tag','lbl2',...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.07 .7 .1 ctlH]);
    h.txtSampEnR=uicontrol(h.panelOptNL,'Style','edit', 'String','0.1',...
        'Units', 'normalized', 'Tag','txt2',...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Position',[.07+.1 .7 ctlW ctlH],...
        'Callback', @optChange_Callback);
    h.lblSampEnM=uicontrol(h.panelOptNL,'Style','text', 'String','m :',...
        'Units', 'normalized', 'Tag','txt2',...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.6-.1 .7 .1 ctlH]);
    h.txtSampEnM=uicontrol(h.panelOptNL,'Style','edit', 'String','3',...
        'Units', 'normalized', 'Tag','txt2',...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Position',[.6 .7 ctlW ctlH],...
        'Callback', @optChange_Callback);
    %DFA
    h.lblDFA=uicontrol(h.panelOptNL,'Style','text', 'String','DFA',...
        'Units', 'normalized', 'Tag','lbl3', 'fontweight','b',...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.05 .6 .3 ctlH]);
    h.lblDFAn=uicontrol(h.panelOptNL,'Style','text', 'String','n :',...
        'Units', 'normalized', 'Tag','lbl4',...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.07 .5 .3 ctlH]);
    h.txtDFAn1=uicontrol(h.panelOptNL,'Style','edit', 'String','4',...
        'Units', 'normalized', 'Tag','txt4',...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Position',[.35 .5 ctlW ctlH],...
        'Callback', @optChange_Callback);
    h.txtDFAn2=uicontrol(h.panelOptNL,'Style','edit', 'String','100',...
        'Units', 'normalized', 'Tag','txt4',...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Position',[.6 .5 ctlW ctlH],...
        'Callback', @optChange_Callback);
    h.lblDFAhyph=uicontrol(h.panelOptNL,'Style','text', 'String','-',...
        'Units', 'normalized', 'Tag','txt4',...
        'HorizontalAlignment','center','BackgroundColor',color.back,...
        'Position',[.35+ctlW 5 .6-.35-ctlW ctlH]); 
    h.lblDFAbp=uicontrol(h.panelOptNL,'Style','text', ...
        'String','Break Point :',...
        'Units', 'normalized', 'Tag','lbl5',...
        'HorizontalAlignment','left', 'BackgroundColor',color.back,...
        'Position',[.07 .02 .3 ctlH]);
    h.txtDFAbp=uicontrol(h.panelOptNL,'Style','edit', 'String','13',...
        'Units', 'normalized', 'Tag','txt5',...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Position',[.6 .1 ctlW ctlH],...
        'Callback', @optChange_Callback);
    
    %align controls
    lbl=findobj(h.panelOptNL,'-regexp','Tag','lbl(\w*)');
    txt=findobj(h.panelOptNL,'-regexp','Tag','txt(\w*)');
    align(lbl, 'VerticalAlignment','Distribute')
    
    %loop through all freq panel controls to align controls
    for l=1:length(lbl)
        for t=1:length(txt)
            taglbl=get(lbl(l),'Tag'); %get lbl tag
            tagtxt=get(txt(t),'Tag'); %get txt tag
            %move txt vert position to match lbl position if tags "match"
            if strcmp(taglbl(4:end),tagtxt(4:end))
                poslbl=get(lbl(l),'position'); %get lbl position
                postxt=get(txt(t),'position'); %get txt position
                postxt(2)=poslbl(2); %set vertical position
                set(txt(t),'position',postxt); %move txt control
            end
        end
    end
    clear i j lbl txt postxt poslbl taglbl tagtxt
    
%% GUI: Analysis Options - TimeFreq

    h.panelOptTimeFreq = uipanel('Parent',h.panelOptions, ...
        'title','Time-Freq',...
        'Units', 'normalized', 'Position',[.255 .01 .235 .15],...
        'FontWeight','bold', 'BackgroundColor',color.back);
    
    %calcuate normalized units to use for controls in this panel
    posParent1=get(h.panelOptions,'position');
    posParent2=get(h.panelOptTimeFreq,'position');
    ctlH=ctlHpx/(figH*posParent1(4)*posParent2(4));
    ctlW=ctlWpx/(figW*posParent1(3)*posParent2(3));
    
    h.lblTFwinSize=uicontrol(h.panelOptTimeFreq,'Style','text', ...
        'String','Window :',...
        'Units', 'normalized', 'Position',[.05 .55 .42 .35],...
        'HorizontalAlignment','left', 'BackgroundColor',color.back);
    h.txtTFwinSize=uicontrol(h.panelOptTimeFreq,'Style','edit', ...
        'String','30',...
        'Units', 'normalized', 'Position',[.47 .55 .25 .35],...
        'HorizontalAlignment','center','BackgroundColor',[1 1 1],...
        'Callback', @optChange_Callback);
    uicontrol(h.panelOptTimeFreq,'Style','text', 'String','(s)',...
        'Units', 'normalized', 'Position',[.47+.25+.05 .55 .15 .35],...
        'HorizontalAlignment','left', 'BackgroundColor',color.back);
    h.lblTFoverlap=uicontrol(h.panelOptTimeFreq,'Style','text', ...
        'String','Overlap :',...
        'Units', 'normalized', 'Position',[.05 .1 .42 .35],...
        'HorizontalAlignment','left', 'BackgroundColor',color.back);
    h.txtTFoverlap=uicontrol(h.panelOptTimeFreq,'Style','edit', ...
        'String','15',...
        'Units', 'normalized', 'Position',[.47 .1 .25 .35],...
        'HorizontalAlignment','center','BackgroundColor','w',...
        'Callback', @optChange_Callback);    
    uicontrol(h.panelOptTimeFreq,'Style','text', 'String','(s)',...
        'Units', 'normalized', 'Position',[.47+.25+.05 .1 .15 .35],...
        'HorizontalAlignment','left', 'BackgroundColor',color.back);    
%%  GUI: Results - Tab Group
    %Options panel
    h.panelHRV = uipanel('Parent',h.MainFigure,...
            'Units', 'normalized', 'Position',[.5 0 .5 .7]);   
    warning('off','MATLAB:uitab:DeprecatedFunction')
    warning('off','MATLAB:uitabgroup:DeprecatedFunction')
    h.tabgroup = uitabgroup('Parent',h.panelHRV,'Tag','tabs', ...
        'Units','normalized','Position',[0 0 1 1]);   
    
%% GUI: Results - Time Domain Tab

    h.tab1 = uitab('parent',h.tabgroup, 'title', 'Time Domain');
    h.panelTime = uipanel('Parent',h.tab1, ...
        'Position',[.0 .0 1 1], 'BackgroundColor','white');    
    h.axesHistIBI=axes('parent', h.panelTime, ...
        'Position',[.06 .09 .4 .28], 'FontSize',7,'Box','on');
    xlabel(h.axesHistIBI,'IBI (ms)','FontSize',7); 
    title(h.axesHistIBI,'IBI Histogram','FontSize',9)
    h.axesHistBPM=axes('parent', h.panelTime, ...
        'Position',[.55 .09 .4 .28], 'FontSize',7,'Box','on');
    xlabel(h.axesHistBPM,'HR (bpm)','FontSize',7);
    title(h.axesHistBPM,'HR Histogram','FontSize',9)
    h.axesTimeTbl = axes('parent', h.panelTime, ...
        'Position',[.05 .45 .9 .5],...
        'YColor',[1 1 1],'YTickLabel',{},'ylim',[0 1],...
        'XColor',[1 1 1],'XTickLabel',{},'xlim',[0 1]);
    %create Table for Time Domain Results and return handles of text objects
    h.text.time = createTimeTbl(h.axesTimeTbl);     
    
%% GUI: Results - Freq Doamin Tab

    h.tab2 = uitab(h.tabgroup, 'title', 'Freq Domain');
    h.panelFreq = uipanel('Parent',h.tab2, ...
        'Position',[.0 .0 1 1],'BackgroundColor','white');
    h.axesFreq = axes('parent', h.panelFreq, ...
        'Position',[.1 .57 .8 .36], 'FontSize',7,'Box','on');
    xlabel(h.axesFreq, 'Freq (Hz)','FontSize',8); 
    ylabel(h.axesFreq, 'PSD (ms^2/Hz)','FontSize',8);
    
    h.axesFreqTbl = axes('parent', h. panelFreq, ...
        'Position',[.05 .02 .9 .475],...
        'YColor',[1 1 1],'YTickLabel',{},'ylim',[0 1],...
        'XColor',[1 1 1],'XTickLabel',{},'xlim',[0 1]);
    %create Table for Freq Domain Results and return handles of text objects
    h.text.freq = createFreqTbl(h.axesFreqTbl);
    % Create the button group.
    h.btngrpFreqPlot = uibuttongroup('Parent',h.panelFreq,...
        'Units','normalized', 'Position',[.175 .9355 .726 .054], ...
        'BackgroundColor','white' ,'Visible','on');
    h.lblFreqPlot = uicontrol(h.btngrpFreqPlot,'Style', ...
        'text','String','Meth :', 'Units','normalized', ...
        'Position',[.005 .0 .09 .85],'BackgroundColor','white',...
        'HorizontalAlignment','left');
    h.radioFreqPlotW = uicontrol(h.btngrpFreqPlot,'Style','radiobutton', ...
        'String','Welch', 'Units','normalized', ...
        'Position',[.11 .035 .15 .99],'BackgroundColor','white',...
        'HorizontalAlignment','left');
    h.radioFreqPlotAR =uicontrol(h.btngrpFreqPlot,'Style','radiobutton', ...
        'String','Burg', 'Units','normalized', ...
        'Position',[.27 .035 .15 .99],'BackgroundColor','white',...
        'HorizontalAlignment','left');
    h.radioFreqPlotLS=uicontrol(h.btngrpFreqPlot,'Style','radiobutton', ...
        'String','LS', 'Units','normalized', ...
        'Position',[.41 .035 .1 .99],'BackgroundColor','white',...
        'HorizontalAlignment','left');
%     set(h.btngrpFreqPlot,'SelectionChangeFcn',@optChange_Callback);
    set(h.btngrpFreqPlot,'SelectionChangeFcn',@freqPlotChange_Callback);
    set(h.btngrpFreqPlot,'SelectedObject',h.radioFreqPlotLS);

    
%% GUI: Results - Poincare Tab

    h.tab3 = uitab('Parent',h.tabgroup, 'title', 'Poincare');
    h.panelPoincare = uipanel('Parent',h.tab3, ...
        'Position',[.0 .0 1 1], 'BackgroundColor','white'); 
    h.axesPoincare = axes('parent', h.panelPoincare, ...
        'Position',[.1 .1 .85 .85], 'FontSize',7,'Box','on');        
                         
%% GUI: Results - Nonlinear Tab

    h.tab4 = uitab('Parent',h.tabgroup, 'title', 'Nonlinear'); 
    h.panelNL = uipanel('Parent',h.tab4,'Position',[.0 .0 1 1], ...
        'BackgroundColor','white');            
    h.axesNL = axes('parent', h.panelNL,'Position',[.1 .55 .8 .4], ...
        'FontSize',8,'Box','on');
    title(h.axesNL,'DFA')
    xlabel(h.axesNL,'log_1_0 n')
    ylabel(h.axesNL,'log_1_0 F(n)')    
    h.axesNLTbl = axes('parent', h.panelNL,'Position',[.05 .02 .9 .4],...
        'YColor',[1 1 1],'YTickLabel',{},'ylim',[0 1],...
        'XColor',[1 1 1],'XTickLabel',{},'xlim',[0 1]);
    %create Table for nonlinear Results and return handles of text objects
    h.text.nl = createNLTbl(h.axesNLTbl); 
    
%% GUI: Results - TimeFreq Tab

    h.tab6 = uitab('Parent',h.tabgroup, 'title', 'Time-Freq'); 
    h.panelTF = uipanel('Parent',h.tab6,'Position',[.0 .0 1 1],...
        'BackgroundColor','white');
    h.axesTF = axes('parent', h.panelTF,'Position',[.1 .565 .8 .365], ...
        'FontSize',7, 'Box','on');
    xlabel(h.axesTF, 'Time (s)'); ylabel(h.axesTF, 'Freq (Hz)');  
    
    h.axesTFTbl = axes('parent', h.panelTF,'Position',[.05 .02 .9 .475],...
        'YColor',[1 1 1],'YTickLabel',{},'ylim',[0 1],...
        'XColor',[1 1 1],'XTickLabel',{},'xlim',[0 1]);
    %create Table for Freq Domain Results and return handles of text objects
    h.text.tf = createTFTbl(h.axesTFTbl);
    % Create Method button group.
    h.btngrpTFPlot = uibuttongroup('Parent',h.panelTF,...
        'Units','normalized', 'Position',[.175 .9355 .515 .054],...
        'BackgroundColor','white' ,'Visible','on');
    h.lblTFPlot = uicontrol(h.btngrpTFPlot,'Style','text',...
        'String','Meth :', 'Units','normalized', ...
        'Position',[.005 .0 .15 .85], 'BackgroundColor','white',...
        'HorizontalAlignment','left');
    h.radioTFPlotAR = uicontrol(h.btngrpTFPlot,'Style','radiobutton', ...
        'String','Burg', 'Units','normalized', ...
        'Position',[.15 .035 .18 .99],'BackgroundColor','white',...
        'HorizontalAlignment','left');
    h.radioTFPlotLS = uicontrol(h.btngrpTFPlot,'Style','radiobutton',...
        'String','LS','Units','normalized', ...
        'Position',[.34 .035 .15 .99],'BackgroundColor','white',...
        'HorizontalAlignment','left');
    h.radioTFPlotWav = uicontrol(h.btngrpTFPlot,'Style','radiobutton',...
        'String','Wavelet', 'Units','normalized', ...
        'Position',[.49 .035 .4 .99],'BackgroundColor','white',...
        'HorizontalAlignment','left');
    set(h.btngrpTFPlot,'SelectionChangeFcn',@TFPlotChange_Callback);
    set(h.btngrpTFPlot,'SelectedObject',h.radioTFPlotLS);
    % Create Type button group.
     h.listTFPlot = uicontrol(h.panelTF,'Style','popupmenu',...
        'String',{'Spectrogram', 'Spectrogram (log)','Surface', ...
        'Waterfall', 'Global PSD','LF/HF Ratio','LF & HF Power'}, ...
        'Value',1,'BackgroundColor','white',...
        'Units', 'normalized', 'Position',[.7 .94 .2 .05],...
        'Callback', @TFPlotChange_Callback);
    h.btngrpTFPlot2 = uibuttongroup('Parent',h.panelTF,...
        'Units','normalized', 'Position',[.5 .94 .4 .05], ...
        'BackgroundColor','white', 'Visible','off');
    h.lblTFPlot2 = uicontrol(h.btngrpTFPlot2,'Style','text',...
        'String','Type :', 'Units','normalized', ...
        'Position',[.005 .0 .2 .9],...
        'BackgroundColor','white','HorizontalAlignment','left');
    h.radioTFPlotSpec = uicontrol(h.btngrpTFPlot2,'Style','radiobutton',...
        'String','Spectrogram', 'Units','normalized', ...
        'Position',[.2 .035 .45 .99],'BackgroundColor','white',...
        'HorizontalAlignment','left');
    h.radioTFPlotPSD = uicontrol(h.btngrpTFPlot2,'Style','radiobutton',...
        'String','PSD', 'Units','normalized', ...
        'Position',[.65 .035 .3 .99],'BackgroundColor','white',...
        'HorizontalAlignment','left');
    h.radioTFPlotPSD = uicontrol(h.btngrpTFPlot2,'Style','radiobutton',...
        'String','LFHF', 'Units','normalized', ...
        'Position',[.65 .035 .3 .99],'BackgroundColor','white',...
        'HorizontalAlignment','left');    
    set(h.btngrpTFPlot2,'SelectionChangeFcn',@TFPlotChange_Callback);
    set(h.btngrpTFPlot2,'SelectedObject',h.radioTFPlotSpec);
    
%%  Initialization Tasks
    
    %set default data file
    tmp=what; %get current dir info
    set(h.txtFile,'string', ...
        fullfile(tmp.path,'sampleData','sampleData.ibi'));
    clear tmp
    %load parameters and previous options
    settings = loadSettings('settings.mat'); 
    %set controls to previous options
    setSettings(settings) 
    
%%  UIControl Callback Fxns

    function menu_exportHRV(hObject, eventdata)
    % Export HRV
        
        if flagProcessed %if there are HRV results to export
            [f p]=uiputfile('*.xlsx','Save HRV As');
            if ~isequal(f,0)
                outfile=fullfile(p,f);
                [p2 f2]=fileparts(settings.file);
                exportHRV(outfile,{f2},HRV,settings)
            end
        end    
    end
    
    function menu_exportIBI_1(hObject, eventdata)
    %Exports current raw IBI series (before detrending and beat
    %replacement)
        
        if ~isempty(IBI)
            [f p]=uiputfile('*.ibi','Save IBI As');
            if ~isequal(f,0)                
                dlmwrite(fullfile(p,f),IBI,'delimiter',',','newline','pc')
            end
        end
    end

    function menu_exportIBI_2(hObject, eventdata)
    %Exports current raw IBI series with ibi values only (before
    %detrending and beat replacement)
        
        if ~isempty(IBI)
            [f p]=uiputfile('*.ibi','Save IBI As');
            if ~isequal(f,0)                
                dlmwrite(fullfile(p,f),IBI(:,2),'newline','pc')
            end
        end
    end

    function menu_exportIBI_3(hObject, eventdata)
    %Exports current preprocessed IBI series (after detrending and beat
    %replacement)
        
        if ~isempty(dIBI)
            [f p]=uiputfile('*.ibi','Save IBI As');
            if ~isequal(f,0)
                dlmwrite(fullfile(p,f),dIBI,'delimiter',',','newline','pc')
            end
        end
    end

    function saveSet_Callback(hObject, eventdata)
    % save settings
        
        settings=getSettings;
        [f p]=uiputfile('*.mat','Save HRV Settings As');
        if ~isequal(f,0)
            save(fullfile(p,f),'settings');
        end
    end 

    function loadSet_Callback(hObject, eventdata)
    % load settings
        [f p]=uigetfile('*.mat','Select HRV Settings File');
        if ~isequal(f,0)
            f=fullfile(p,f);
            settings=loadSettings(f);
            setSettings(settings);
        end
    end 

    function showAbout(hObject, eventdata)
        f = figure('Name','About HRVAS','NumberTitle','off', ...
            'Toolbar','none','Menubar','none');
        txt={'Author: John Ramshur',...
             'Location: University of Memphis',...
             'Info: HRV analysis software (HRVAS)...add more info'};
        h.lblProcessing=uicontrol(f,'Style','text', ...
            'String',txt,'horizontalalignment','left',...
            'Units', 'normalized', 'Position',[.01 .01 .98 .98]);
    end

    function copyAxes(gcbo,eventdata,handles)
        s=get(h.MainFigure,'SelectionType'); %type of mouse click
        if strcmpi(s,'open') %if double click            
            f=figure; % Create a new figure
            hNew = copyobj(gcbo,f);       
            
            %remove click events from the new figure
            set(hNew,'buttondownfcn','')
            hAll=allchild(hNew);
            for ih=1:length(hAll)
                set(hAll(ih),'buttondownfcn','')
            end
            
            %adjust settings to default
            fontdef=12;
            set(hNew,'position',[.15 .15 .75 .75], ...
                'fontsize', fontdef) %axes position & fontsize
            lH=get(hNew,'xlabel'); 
            set(lH,'fontsize',fontdef); %xlabel fontsize
            lH=get(hNew,'ylabel'); 
            set(lH,'fontsize',fontdef); %ylabel fontsize
            lH=get(hNew,'title');
            set(lH,'fontsize',fontdef); %title fontsize
            lH=get(hNew,'zlabel'); 
            set(lH,'fontsize',fontdef); %zlabel fontsize
            
        end
    end

    function copyParentAxes(gcbo,eventdata,handles)
        s=get(h.MainFigure,'SelectionType'); %type of mouse click
        if strcmpi(s,'open') %if double click            
            f=figure; % Create a new figure
            parentH=get(gcbo,'parent');
            hNew = copyobj(parentH,f);
            
            %remove click events from the new figure
            set(hNew,'buttondownfcn','')
            hAll=allchild(hNew);
            for ih=1:length(hAll)
                set(hAll(ih),'buttondownfcn','')
            end
            
            %adjust settings to default
            fontdef=12;
            set(hNew,'position',[.15 .15 .75 .75], ...
                'fontsize', fontdef) %axes position & fontsize
            lH=get(hNew,'xlabel'); 
            set(lH,'fontsize',fontdef); %xlabel fontsize
            lH=get(hNew,'ylabel'); 
            set(lH,'fontsize',fontdef); %ylabel fontsize
            lH=get(hNew,'title');
            set(lH,'fontsize',fontdef); %title fontsize
            lH=get(hNew,'zlabel'); 
            set(lH,'fontsize',fontdef); %zlabel fontsize            
        end
    end

    function copyIBIAxes(gcbo,eventdata,handles)
        s=get(h.MainFigure,'SelectionType'); %type of mouse click
        if strcmpi(s,'open') %if double click            
            f=figure; % Create a new figure
            h1=subplot(211);
            h1Pos=get(h1,'position');
            delete(h1);
            h2=subplot(212);
            hNew = copyobj(gcbo,f);
            set(hNew,'position',h1Pos);
            
            %plot detrended IBI
            plot(h2,dIBI(:,1),dIBI(:,2),'.-')
                        
            %remove click events from the new figure
            set(hNew,'buttondownfcn','')
            hAll=allchild(hNew);
            for ih=1:length(hAll)
                set(hAll(ih),'buttondownfcn','')
            end
            
            %adjust settings to default for 1st subplot
            fontdef=10;
            set(hNew,'fontsize', fontdef) %fontsize
            lH=get(hNew,'xlabel'); 
            set(lH,'fontsize',fontdef); %xlabel fontsize
            lH=get(hNew,'ylabel'); 
            set(lH,'fontsize',fontdef); %ylabel fontsize
            lH=get(hNew,'title');
            set(lH,'fontsize',fontdef); %title fontsize
            lH=get(hNew,'zlabel'); 
            set(lH,'fontsize',fontdef); %zlabel fontsize
            title(hNew, 'IBI','fontsize',fontdef)
            
            %adjust settings to default for 2nd subplot            
            axis tight;
            set(h2,'fontsize', fontdef,'xlim',get(hNew,'xlim'));                
            lH=get(hNew,'xlabel'); 
            xlabel(h2,get(lH,'string'),'fontsize',fontdef)
            lH=get(hNew,'ylabel'); 
            ylabel(h2, get(lH,'string'),'fontsize',fontdef)
            title(h2, 'Processed IBI','fontsize',fontdef)                        
        end
    end

    function btnChooseFile_Callback(hObject, eventdata)
    % Callback function executed when btnChooseFile is pressed
        
        %get directory path
        [filename, pathname] = uigetfile( ...
            {'*.ibi;*.rr;*.txt','IBI Files (*.ibi,*.rr,*.txt)';
               '*.ibi',  'IBI (*.ibi)'; ...
               '*.rr','RR (*.rr)'; ...
               '*.txt','Text (*.txt)'; ...
               '*.*',  'All Files (*.*)'}, ...
               'Select IBI data file',...
               settings.file);
        
        if isequal(filename,0)
            return %user selected cancel
        else
            f=fullfile(pathname, filename);
            set(h.txtFile,'String',[' ' f]);
        end

    end

    function btnRun_Callback(hObject, eventdata)
        f=strtrim(get(h.txtFile,'String'));
        if ~isempty(f) || ~exist(f,'file')
            settings=getSettings; %get HRV options from gui
            tic;
            HRV=getHRV(f,settings);
            toc
            displayHRV(h,nIBI,dIBI,HRV,settings);
        end
    end

    function btnPreview_Callback(hObject, eventdata)
        f=strtrim(get(h.txtFile,'String'));
        if ~isempty(f)            
        
        settings=getSettings; %get HRV options from gui
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % LOAD IBI
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        showStatus('< Loading IBI >');        
        nIBI=[]; dIBI=[];
        IBI=loadIBI(f,settings);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Preprocess Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        showStatus('< Preprocessing >');

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

        %Note: don't need to use all the input arguments. Will let the
        %function handle all inputs
        [dIBI,nIBI,trend,art] = preProcessIBI(IBI, ...
            'locateMethod', methods, 'locateInput', methInput, ...
            'replaceMethod', settings.ArtReplace, ...
            'replaceInput',replaceWin,  ...
            'detrendMethod', settings.Detrend, ...
            'smoothMethod', settings.SmoothMethod, ...
            'smoothSpan', settings.SmoothSpan, ...
            'smoothDegree', settings.SmoothDegree, ...
            'polyOrder', settings.PolyOrder, ...
            'waveletType', ...
            [settings.WaveletType num2str(settings.WaveletType2)], ...
            'waveletLevels', settings.WaveletLevels, ...
            'lambda', settings.PriorsLambda,...
            'resampleRate',settings.Interp);
        
        if sum(art)>0
            set(h.lblArtLocate,'string', ...
                ['Ectopic Detection' ' [' ...
                sprintf('%.2f',sum(art)/size(IBI,1)*100) '%]'])
        else
            set(h.lblArtLocate,'string','Ectopic Detection')
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Plot IBI
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        plotIBI(h,settings,IBI,dIBI,nIBI,trend,art);
        
        showStatus('');
        drawnow expose
        
        flagPreviewed=true;
        
        end
    end
        

    function optChange_Callback(hObject, eventdata)
    % Callback function run when HRV options change
        drawnow;        
    %         settings=getSettings; %get HRV options from gui
    %         HRV=getHRV(get(h.txtFile,'String'),settings);
    %         displayHRV(h,IBI,HRV,settings); %display HRV in GUI
    end

    function freqPlotChange_Callback(hObject, eventdata)
    % Callback function run when freq plot type change    
    
        if flagProcessed
            if  strcmp(get(get(h.btngrpFreqPlot,'SelectedObject'), ...
                    'string'), 'Welch')
                psd=HRV.freq.welch.psd;
                f=HRV.freq.welch.f;
                ylbl='PSD (s^2/Hz)';
                flagLS=false;
            elseif strcmp(get(get(h.btngrpFreqPlot,'SelectedObject'), ...
                    'string'), 'Burg')
                psd=HRV.freq.ar.psd;
                f=HRV.freq.ar.f;
                ylbl='PSD (s^2/Hz)';
                flagLS=false;
            else
                psd=HRV.freq.lomb.psd;
                f=HRV.freq.lomb.f;
                ylbl='PSD (normalized)';
                flagLS=true;
            end
            plotPSD(h.axesFreq,f,psd,settings.VLF,settings.LF, ...
                settings.HF,[],[],true,flagLS);
            set(h.axesFreq,'FontSize',7)
            xlabel(h.axesFreq,'Freq (Hz)','FontSize',8);
            ylabel(h.axesFreq,ylbl,'FontSize',8);            
        end
    end

    function TFPlotChange_Callback(hObject, eventdata)
    % Callback function run when time-freq plot type change
        
        % If waterfall plot is selected disable Wavelet option.
        % Waterfall plot takes too long for wavlet b'c it contains many
        % time values.
        pt=get(h.listTFPlot,'string');
        pt=pt{get(h.listTFPlot,'value')};
        if strcmpi(pt,'waterfall')
            if get(h.radioTFPlotWav,'value') % if selected change selection
                set(h.radioTFPlotAR,'value',1)
                warning(['Can not currently plot waterfall using' ...
                ' wavelet transforms.'])
            end
            set(h.radioTFPlotWav, 'enable','off');
        else
            set(h.radioTFPlotWav, 'enable','on');
        end
    
        if flagProcessed
            drawnow expose;
            plotTF(h,HRV,settings);            
        end
    end

    function detrendChange_Callback(hObject, eventdata)
    % Callback function run when Detrend options change
        showDetrendOptions();
        optChange_Callback(hObject,eventdata);
    end    

    function closeGUI(src,evnt)
    %function to close gui
        saveSettings(settings);                               
        delete(gcf);
    end

    function batch_Callback(src,evnt)
        batchHRV(settings);
    end

    function getHeaderSize(src,evnt)
    % function to prompt user for headerSize of IBI files
        prompt = {'# of Rows in Header:'};
        dlg_title = 'Options';        
        def = {num2str(settings.headerSize)};        
        answer = inputdlg(prompt,dlg_title,1,def);
        if ~isempty(answer)
            settings.headerSize=str2double(answer);
        end
    end

    function showMenubar(src,evnt)
    % function to show/hide menubar    
        state=get(h.MainFigure,'menubar');
        if strcmpi(state,'figure')            
            set(h.MainFigure,'menubar','none')
        else
            set(h.MainFigure,'menubar','figure')
        end
    end
    function showToolbar(src,evnt)
    % function to show/hide toolbar    
        state=get(h.MainFigure,'toolbar');
        if strcmpi(state,'figure')            
            set(h.MainFigure,'toolbar','none')
        else
            set(h.MainFigure,'toolbar','figure')
        end
    end

    function trendlineFFT(src,evnt)
    % function to plot FFT of the trendline. It's purpose is to evaluate
    % the freq. response of any detrending methods
        if flagPreviewed
            t=trend(:,1);
            y=trend(:,2);
            fs=str2double(get(h.txtInterp,'string'));
            t2 = t(1):1/fs:t(end); %time values for interp.
            y2=interp1(t,y,t2,'spline')'; %interpolation
            L=length(y2);
            NFFT = 2^nextpow2(L); % Next power of 2 from length of y
            Y = fft(y2,NFFT)/L;
            f = fs/2*linspace(0,1,NFFT/2+1);
            figure;
            plot(f,2*abs(Y(1:(NFFT/2+1))),'r')
            title('FFT of Trendline')
            xlabel('Freq (Hz)')
            ylabel('Magnitude')
        end
    end

%% Helper and Utility Functions

    function ibi=loadIBI(f,opt)
    % loadIBI: function to load ibi data file into array    
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
        if rows==1 %all data in 1st row
            tmpData=tmpData';
            ibi=zeros(cols,2);
            tmp=cumsum(tmpData);
            ibi(2:end,1)=tmp(1:end-1);
            ibi(:,2)=tmpData;
        elseif cols==1 %all data in 1st col
            ibi=zeros(rows,2);
            tmp=cumsum(tmpData);
            ibi(2:end,1)=tmp(1:end-1);
            ibi(:,2)=tmpData;
        elseif rows<cols %need to transpose
            ibi=tmpData';
        else
            ibi=tmpData; %ok
        end                                      
        clear tmpData      
    end

    function output = loadSettings(f)
    % loadSettings: Loads any saved settings. If the file is not
    % present or any settings are not present then defaults will
    % be loaded based values used during GUI creation.
    
        if exist(f,'file')
            tmp=load(f);
            output=tmp.settings;
        else
            output=[];
        end

        % if filename is present in parameter file
        if ~isfield(output,'file') || ~exist(output.file,'file')
            tmp=what;
            output.file=fullfile(tmp.path,'sampleData','sampleData.ibi');
        end            

        %set default header size of input files
        if ~isfield(output,'headerSize') ...
                || isempty(output.headerSize)
           output.headerSize=0; %0 rows in header = no header
        end
        
      %%% Preprocessing %%%
        %ArtLocate
        if ~isfield(output,'ArtLocatePer') ...
            || isempty(output.ArtLocatePer)
           output.ArtLocatePer=get(h.chkArtLocPer,'value');
        end
        if ~isfield(output,'ArtLocatePerVal') ...
                || isempty(output.ArtLocatePerVal)
           output.ArtLocatePerVal=str2double(get(h.txtArtLocPer,'string'));
        end 
        if ~isfield(output,'ArtLocateSD') ...
                || isempty(output.ArtLocateSD)
           output.ArtLocateSD=get(h.chkArtLocSD,'value');
        end 
        if ~isfield(output,'ArtLocateSDVal') ...
                || isempty(output.ArtLocateSDVal)
           output.ArtLocateSDVal=str2double(get(h.txtArtLocSD,'string'));
        end 
        if ~isfield(output,'ArtLocateMed') ...
                || isempty(output.ArtLocateMed)
           output.ArtLocateMed=get(h.chkArtLocMed,'value');
        end
        if ~isfield(output,'ArtLocateMedVal')...
                || isempty(output.ArtLocateMedVal)
           output.ArtLocateMedVal=str2double(get(h.txtArtLocMed,'string'));
        end 
        %ArtReplace
        if ~isfield(output,'ArtReplace') ...
                || isempty(output.ArtReplace)
           output.ArtReplace= ...
               get(get(h.btngrpArtReplace,'selectedobject'),'string');           
        end
        if ~isfield(output,'ArtReplaceMeanVal') ...
                || isempty(output.ArtReplaceMeanVal)
           output.ArtReplaceMeanVal= ...
               str2double(get(h.txtArtReplaceMean,'string'));
        end 
        if ~isfield(output,'ArtReplaceMedVal') ...
                || isempty(output.ArtReplaceMedVal)
           output.ArtReplaceMedVal= ...
               str2double(get(h.txtArtReplaceMed,'string'));
        end 
        %Detrend
        if ~isfield(output,'Detrend') || isempty(output.Detrend)
            tmp=get(h.listDetrend,'string');
            output.Detrend=tmp{get(h.listDetrend,'value')};
        end
        %Matlab Smooth: method
        if ~isfield(output,'SmoothMethod') ...
                || isempty(output.SmoothMethod)
            tmp=get(h.listSmoothMethod,'string');
            output.SmoothMethod=tmp{get(h.listSmoothMethod,'value')};
        end
        %Matlab Smooth: Span
        if ~isfield(output,'SmoothSpan') || isempty(output.SmoothSpan)
           output.SmoothSpan=str2double(get(h.txtSmoothSpan,'string'));
        end
        %Matlab Smooth: Degree
        if ~isfield(output,'SmoothDegree') || isempty(output.SmoothDegree)
           output.SmoothDegree=str2double(get(h.txtSmoothDegree,'string'));
        end
        %Poly: order
        if ~isfield(output,'PolyOrder') || isempty(output.PolyOrder)
           output.PolyOrder=get(h.listPoly,'Value');
        end
        %Wavelet: Type
        if ~isfield(output,'WaveletType') || isempty(output.WaveletType)
            tmp=get(h.listWaveletType,'string');
            output.WaveletType=tmp{get(h.listWaveletType,'value')};
        end
        %Wavelet: type2
        if ~isfield(output,'WaveletType2') || isempty(output.WaveletType2)
           output.WaveletType2=str2double(get(h.txtWaveletType2,'string'));
        end
        %Wavelet: Levels
        if ~isfield(output,'WaveletLevels') || isempty(output.WaveletLevels)
           output.WaveletLevels= ...
               str2double(get(h.txtWaveletLevels,'string'));
        end
        %Smoothness Priors: lambda
        if ~isfield(output,'PriorsLambda') || isempty(output.PriorsLambda)
           output.PriorsLambda=str2double(get(h.txtPriorsLambda,'string'));
        end
        
        %%% time %%%                
        %pNNx
        if ~isfield(output,'pNNx') || isempty(output.pNNx)
           output.pNNx=str2double(get(h.txtPNNx,'string'));
        end
        %SDNNi
        if ~isfield(output,'SDNNi') || isempty(output.SDNNi)
           output.SDNNi=str2double(get(h.txtSDNNi,'string'));
        end                
        
        %%% Freq Domain %%%
        %VLF
        if ~isfield(output,'VLF') || isempty(output.VLF)
            output.VLF(1)=str2double(get(h.txtVLF1,'string'));
            output.VLF(2)=str2double(get(h.txtVLF2,'string'));
        end 
        %LF
        if ~isfield(output,'LF') || isempty(output.LF)
            output.LF(1)=str2double(get(h.txtLF1,'string'));
            output.LF(2)=str2double(get(h.txtLF2,'string'));
        end 
        %HF
        if ~isfield(output,'HF') || isempty(output.HF)
            output.HF(1)=str2double(get(h.txtHF1,'string'));
            output.HF(2)=str2double(get(h.txtHF2,'string'));
        end 
        %Interp
        if ~isfield(output,'Interp') || isempty(output.Interp)
           output.Interp=str2double(get(h.txtInterp,'string'));
        end 
        %Points
        if ~isfield(output,'Points') || isempty(output.Points)
           output.Points=str2double(get(h.txtPoints,'string'));
        end
        %WinWidth
        if ~isfield(output,'WinWidth') || isempty(output.WinWidth)
           output.WinWidth=str2double(get(h.txtWinWidth,'string'));
        end
        %WinOverlap
        if ~isfield(output,'WinOverlap') || isempty(output.WinOverlap)
           output.WinOverlap=str2double(get(h.txtWinOverlap,'string'));
        end
        %AROrder
        if ~isfield(output,'AROrder') || isempty(output.AROrder)
           output.AROrder=str2double(get(h.txtAROrder,'string'));
        end        

        %%% Nonlinear %%%                                       
        %m
        if ~isfield(output,'m') || isempty(output.m)
           output.m=str2double(get(h.txtSampEnM,'string'));
        end
        %r
        if ~isfield(output,'r') || isempty(output.r)
           output.r=str2double(get(h.txtSampEnR,'string'));
        end
        %n1
        if ~isfield(output,'n1') || isempty(output.n1)
           output.n1=str2double(get(h.txtDFAn1,'string'));
        end
        %n2
        if ~isfield(output,'n2') || isempty(output.n2)
           output.n2=str2double(get(h.txtDFAn2,'string'));
        end
        %breakpoint
        if ~isfield(output,'breakpoint') || isempty(output.breakpoint)
           output.breakpoint=str2double(get(h.txtDFAbp,'string'));
        end
                       
        %%% Time-Freq %%%
        %winSize
        if ~isfield(output,'tfWinSize') || isempty(output.tfWinSize)
           output.tfWinSize=str2double(get(h.txtTFwinSize,'string'));
        end
        %overlap
        if ~isfield(output,'tfOverlap') || isempty(output.tfOverlap)
           output.tfOverlap=str2double(get(h.txtTFoverlap,'string'));
        end
    end

    function saveSettings(in)
    %saveSettings: Save any settings
        settings=in;
        save('settings.mat','settings');
    end

    function output = getSettings
    % getSettings: gets current analysis settings from GUI  
        output.file=strtrim(get(h.txtFile,'string'));
        %preprocessing
        %artifact detection
        output.ArtLocatePer=get(h.chkArtLocPer,'value');
        output.ArtLocatePerVal=str2double(get(h.txtArtLocPer,'string'));
        output.ArtLocateSD=get(h.chkArtLocSD,'value');
        output.ArtLocateSDVal=str2double(get(h.txtArtLocSD,'string'));
        output.ArtLocateMed=get(h.chkArtLocMed,'value');
        output.ArtLocateMedVal=str2double(get(h.txtArtLocMed,'string'));
        %artifact correction
        output.ArtReplace= ...
            get(get(h.btngrpArtReplace,'selectedobject'),'string');
        output.ArtReplaceMeanVal= ...
            str2double(get(h.txtArtReplaceMean,'string'));
        output.ArtReplaceMedVal= ...
            str2double(get(h.txtArtReplaceMed,'string'));        
        %detrending
        tmp=get(h.listDetrend,'string');
        output.Detrend=tmp{get(h.listDetrend,'value')};        
        tmp=get(h.listSmoothMethod,'string');
        output.SmoothMethod=tmp{get(h.listSmoothMethod,'value')};
        output.SmoothSpan=str2double(get(h.txtSmoothSpan,'string'));
        output.SmoothDegree=str2double(get(h.txtSmoothDegree,'string'));
        output.PolyOrder=get(h.listPoly,'value');
        tmp=get(h.listWaveletType,'string');
        output.WaveletType=tmp{get(h.listWaveletType,'value')};
        output.WaveletType2=str2double(get(h.txtWaveletType2,'string'));
        output.WaveletLevels=str2double(get(h.txtWaveletLevels,'string'));
        output.PriorsLambda=str2double(get(h.txtPriorsLambda,'string'));        
      %time
        output.pNNx=str2double(get(h.txtPNNx,'string'));
        output.SDNNi=str2double(get(h.txtSDNNi,'string'));                
      %freq
        output.VLF(1)=str2double(get(h.txtVLF1,'string'));
        output.VLF(2)=str2double(get(h.txtVLF2,'string'));
        output.LF(1)=str2double(get(h.txtLF1,'string'));
        output.LF(2)=str2double(get(h.txtLF2,'string'));
        output.HF(1)=str2double(get(h.txtHF1,'string'));
        output.HF(2)=str2double(get(h.txtHF2,'string'));
        output.Interp=str2double(get(h.txtInterp,'string'));
        output.Points=str2double(get(h.txtPoints,'string'));
        output.WinWidth=str2double(get(h.txtWinWidth,'string'));
        output.WinOverlap=str2double(get(h.txtWinOverlap,'string'));
        output.AROrder=str2double(get(h.txtAROrder,'string'));        
      %nonlinear
        output.m=str2double(get(h.txtSampEnM,'string'));
        output.r=str2double(get(h.txtSampEnR,'string'));
        output.n1=str2double(get(h.txtDFAn1,'string'));
        output.n2=str2double(get(h.txtDFAn2,'string'));
        output.breakpoint=str2double(get(h.txtDFAbp,'string'));
      %time-freq
        output.tfWinSize=str2double(get(h.txtTFwinSize,'string'));
        output.tfOverlap=str2double(get(h.txtTFoverlap,'string'));
        output.headerSize=settings.headerSize;
    end

    function setSettings(in)
    % setSettings: sets the current analysis settings within GUI
        set(h.txtFile,'string',[' ' in.file])
        %preprocessing
        %artifact detection
        set(h.chkArtLocPer,'value',in.ArtLocatePer)
        set(h.txtArtLocPer,'string',num2str(in.ArtLocatePerVal))
        set(h.chkArtLocSD,'value',in.ArtLocateSD)
        set(h.txtArtLocSD,'string',num2str(in.ArtLocateSDVal))
        set(h.chkArtLocMed,'value',in.ArtLocateMed)
        set(h.txtArtLocMed,'string',num2str(in.ArtLocateMedVal))        
        %artifact Correction
        switch in.ArtReplace            
            case 'Mean'
                set(h.radioArtReplaceMean,'value',1)
            case 'Median'
                set(h.radioArtReplaceMed,'value',1)
            case 'Spline'
                set(h.radioArtReplaceSpline,'value',1)
            case 'Remove'
                set(h.radioArtReplaceRem,'value',1)
            otherwise
                set(h.radioArtReplaceNone,'value',1)
        end
        set(h.txtArtReplaceMean,'string',num2str(in.ArtReplaceMeanVal))
        set(h.txtArtReplaceMed,'string',num2str(in.ArtReplaceMedVal))        
        %Detrending        
        tmp=get(h.listDetrend,'string');
        i=find(ismember(tmp, settings.Detrend)==1);
        set(h.listDetrend,'value',i)
        tmp=get(h.listSmoothMethod,'string');
        i=find(ismember(tmp, settings.SmoothMethod)==1);
        set(h.listSmoothMethod,'value',i)
        set(h.txtSmoothSpan,'string',num2str(in.SmoothSpan))
        set(h.txtSmoothDegree,'string',num2str(in.SmoothDegree))                            
        set(h.listPoly,'value',in.PolyOrder);
        tmp=get(h.listWaveletType,'string');
        i=find(ismember(tmp, settings.WaveletType)==1);
        set(h.listWaveletType,'value',i)
        set(h.txtWaveletType2,'string',num2str(in.WaveletType2))
        set(h.txtWaveletLevels,'string',num2str(in.WaveletLevels))
        set(h.txtPriorsLambda,'string',num2str(in.PriorsLambda))
        showDetrendOptions();
        
      %time
        set(h.txtPNNx,'string',int2str(in.pNNx))
        set(h.txtSDNNi,'string',num2str(in.SDNNi))              
      %freq
        set(h.txtVLF1,'string',num2str(in.VLF(1)))
        set(h.txtVLF2,'string',num2str(in.VLF(2)))
        set(h.txtLF1,'string',num2str(in.LF(1)))
        set(h.txtLF2,'string',num2str(in.LF(2)))
        set(h.txtHF1,'string',num2str(in.HF(1)))
        set(h.txtHF2,'string',num2str(in.HF(2)))
        set(h.txtInterp,'string',int2str(in.Interp))
        set(h.txtPoints,'string',int2str(in.Points))
        set(h.txtWinWidth,'string',int2str(in.WinWidth))
        set(h.txtWinOverlap,'string',int2str(in.WinOverlap))
        set(h.txtAROrder,'string',int2str(in.AROrder))        
      %nonlinear
        set(h.txtSampEnM,'string',num2str(in.m));
        set(h.txtSampEnR,'string',num2str(in.r));
        set(h.txtDFAn1,'string',num2str(in.n1));
        set(h.txtDFAn2,'string',num2str(in.n2));
        set(h.txtDFAbp,'string',num2str(in.breakpoint));
      %Time-Freq
        set(h.txtTFwinSize,'string',num2str(in.tfWinSize))
        set(h.txtTFoverlap,'string',num2str(in.tfOverlap))
    end

    function showDetrendOptions
    % showDetrendOptions: show/hide detrending options in GUI
        selection=get(h.listDetrend,'Value');
        if selection==2 %Wavelet
            set(h.listSmoothMethod,'Visible','off');
            set(h.lblSmoothMethod,'Visible','off');
            set(h.txtSmoothSpan,'Visible','off');
            set(h.lblSmoothSpan,'Visible','off');
            set(h.txtSmoothDegree,'Visible','off');
            set(h.lblSmoothDegree,'Visible','off')
            set(h.lblPoly,'Visible','off');
            set(h.listPoly,'Visible','off');
            set(h.listWaveletType,'Visible','on');
            set(h.lblWaveletType,'Visible','on');
            set(h.txtWaveletType2,'Visible','on');
            set(h.lblWaveletType2,'Visible','on');
            set(h.txtWaveletLevels,'Visible','on');
            set(h.lblWaveletLevels,'Visible','on');
            set(h.txtPriorsLambda,'Visible','off');
            set(h.lblPriorsLambda,'Visible','off');
        elseif selection==3 %Matlab Smooth
            set(h.listSmoothMethod,'Visible','on');
            set(h.lblSmoothMethod,'Visible','on');
            set(h.txtSmoothSpan,'Visible','on');
            set(h.lblSmoothSpan,'Visible','on');
            set(h.txtSmoothDegree,'Visible','on');
            set(h.lblSmoothDegree,'Visible','on');
            set(h.lblPoly,'Visible','off');
            set(h.listPoly,'Visible','off');
            set(h.listWaveletType,'Visible','off');
            set(h.lblWaveletType,'Visible','off');
            set(h.txtWaveletType2,'Visible','off');
            set(h.lblWaveletType2,'Visible','off');
            set(h.txtWaveletLevels,'Visible','off');
            set(h.lblWaveletLevels,'Visible','off');
            set(h.txtPriorsLambda,'Visible','off');
            set(h.lblPriorsLambda,'Visible','off');
            val=get(h.listSmoothMethod,'value');
            if val==1 % moving
                set(h.lblSmoothSpan,'string','Span :');
                set(h.lblSmoothDegree,'visible','off');
                set(h.txtSmoothDegree,'visible','off');
            elseif val==4 % rgolay
                set(h.lblSmoothSpan,'string','Span :');
                set(h.lblSmoothDegree,'visible','on');
                set(h.txtSmoothDegree,'visible','on');
            else
                set(h.lblSmoothSpan,'string','Span (%) :');
                set(h.lblSmoothDegree,'visible','off');
                set(h.txtSmoothDegree,'visible','off');
            end
        elseif selection==4 %poly detrend
            set(h.listSmoothMethod,'Visible','off');
            set(h.lblSmoothMethod,'Visible','off');
            set(h.txtSmoothSpan,'Visible','off');
            set(h.lblSmoothSpan,'Visible','off');
            set(h.txtSmoothDegree,'Visible','off');
            set(h.lblSmoothDegree,'Visible','off');
            set(h.listWaveletType,'Visible','off');
            et(h.lblWaveletType,'Visible','off');
            set(h.txtWaveletType2,'Visible','off');
            set(h.lblWaveletType2,'Visible','off');
            set(h.txtWaveletLevels,'Visible','off');
            set(h.lblWaveletLevels,'Visible','off');
            set(h.txtPriorsLambda,'Visible','off');
            set(h.lblPriorsLambda,'Visible','off');
            set(h.lblPoly,'Visible','on');
            set(h.listPoly,'Visible','on');
        elseif selection==6 %Smoothness Priors
            set(h.listSmoothMethod,'Visible','off');
            set(h.lblSmoothMethod,'Visible','off');
            set(h.txtSmoothSpan,'Visible','off');
            set(h.lblSmoothSpan,'Visible','off');
            set(h.txtSmoothDegree,'Visible','off');
            set(h.lblSmoothDegree,'Visible','off');
            set(h.lblPoly,'Visible','off');
            set(h.listPoly,'Visible','off');
            set(h.listWaveletType,'Visible','off');
            set(h.lblWaveletType,'Visible','off');
            set(h.txtWaveletType2,'Visible','off');
            set(h.lblWaveletType2,'Visible','off');
            set(h.txtWaveletLevels,'Visible','off');
            set(h.lblWaveletLevels,'Visible','off');
            set(h.txtPriorsLambda,'Visible','on');
            set(h.lblPriorsLambda,'Visible','on');
        else %None
            set(h.listSmoothMethod,'Visible','off');
            set(h.lblSmoothMethod,'Visible','off');
            set(h.txtSmoothSpan,'Visible','off');
            set(h.lblSmoothSpan,'Visible','off');
            set(h.txtSmoothDegree,'Visible','off');
            set(h.lblSmoothDegree,'Visible','off');
            set(h.lblPoly,'Visible','off');
            set(h.listPoly,'Visible','off');
            set(h.listWaveletType,'Visible','off');
            set(h.lblWaveletType,'Visible','off');
            set(h.txtWaveletType2,'Visible','off');
            set(h.lblWaveletType2,'Visible','off');
            set(h.txtWaveletLevels,'Visible','off');
            set(h.lblWaveletLevels,'Visible','off');
            set(h.txtPriorsLambda,'Visible','off');
            set(h.lblPriorsLambda,'Visible','off');
        end
    end
    
    function tH = createTimeTbl(aH)
    % createTimeTbl: creats the table to display time-domain HRV results    
        % define relative x position of cols
        x1=0.02; x2=.5; x3=.9; 
        % define relative y position of rows
        y=linspace(0.8,0.05,12); %evenly space out 12 text items
        
        %Horizontal Lines
        line([0 1],[.95 .95],'Parent',aH,'Color','black')
        line([0 1],[.85 .85],'Parent',aH,'Color','black')
        line([0 1],[0 0],'Parent',aH,'Color','black')
        text(0,1,'Time Domain','Parent',aH, ...
            'Units','normalized', 'fontweight','bold','FontSize',8)
        %Col Headers
        text(x1-.02,.9,'Variable','Parent',aH, ...
            'Units','normalized', 'fontweight','bold','FontSize',8)
        text(x2,.9,'Units','Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8)
        text(x3,.9,'Value','Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8)
        %Column 1
        tH(1,1)=text(x1,y(1),'MeanIBI','Parent',aH,'Units','normalized');
        tH(2,1)=text(x1,y(2),'SDNN','Parent',aH,'Units','normalized');
        tH(3,1)=text(x1,y(3),'MeanHR','Parent',aH,'Units','normalized');
        tH(4,1)=text(x1,y(4),'SDHR','Parent',aH,'Units','normalized');
        tH(5,1)=text(x1,y(5),'RMSSD','Parent',aH,'Units','normalized');
        tH(6,1)=text(x1,y(6),'NNx','Parent',aH,'Units','normalized');
        tH(7,1)=text(x1,y(7),'pNNx','Parent',aH,'Units','normalized');
        tH(8,1)=text(x1,y(8),'SDNNi','Parent',aH,'Units','normalized');
        tH(9,1)=text(x1-.02,y(10),'Geometric Measures','Parent',aH, ...
            'Units','normalized','fontweight','bold');
        tH(10,1)=text(x1,y(11),'HRV Triangular Index','Parent',aH,...
            'Units','normalized');
        tH(11,1)=text(x1,y(12),'TINN','Parent',aH,'Units','normalized');
        %Column 2
        tH(1,2)=text(x2,y(1),'(ms)','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(2,2)=text(x2,y(2),'(ms)','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(3,2)=text(x2,y(3),'(bpm)','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(4,2)=text(x2,y(4),'(bpm)','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(5,2)=text(x2,y(5),'ms','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(6,2)=text(x2,y(6),'(count)','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(7,2)=text(x2,y(7),'(%)','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(8,2)=text(x2,y(8),'(ms)','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(10,2)=text(x2,y(11),'','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(11,2)=text(x2,y(12),'(ms)','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        %Column 3
        tH(1,3)=text(x3,y(1),'0.0','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(2,3)=text(x3,y(2),'0.0','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(3,3)=text(x3,y(3),'0.0','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(4,3)=text(x3,y(4),'0.0','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(5,3)=text(x3,y(5),'0.0','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(6,3)=text(x3,y(6),'0.0','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(7,3)=text(x3,y(7),'0.0','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(8,3)=text(x3,y(8),'0.0','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(10,3)=text(x3,y(11),'0.0','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        tH(11,3)=text(x3,y(12),'0.0','Parent',aH,'Units','normalized',...
            'HorizontalAlignment','right');
        
        %set fonts, and alligments for all text objects of tH
        set(findobj(tH,'type','text','parent',aH),'Fontsize',8)
        set(findobj(tH,'string','0.00','parent',aH), ...
            'HorizontalAlignment','right')        
    end
%% GUI: CreateFreqTbl
    function tH = createFreqTbl(aH)
        %define relative x position of cols
        x1=0.02; x2=.35; x3=.5125; x4=.675; x5=.8375; x6=.98; 
        %define relative y position of rows
        y=linspace(0.75,0.05,12); %evenly space out 12 text items
        
        line([0 1],[.95 .95],'Parent',aH,'Color','black');
        line([0 1],[.8 .8],'Parent',aH,'Color','black');
        line([0 1],[0 0],'Parent',aH,'Color','black');      
        %Header
        text(x1-.02,.88,{'Frequency','Band'},'Parent',aH, ...
            'Units','normalized', 'fontweight','bold','FontSize',8);
        text(x2,.88,{'Peak','(Hz)'},'Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right','fontweight','bold','FontSize',8);
        text(x3,.88,{'Power','(ms^2)'},'Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8);        
        text(x4,.88,{'Power','(%)'},'Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8);
        text(x5,.88,{'Power','(n.u.)'},'Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8);
        text(x6,.88,{'LF/HF','(ratio)'},'Parent',aH, ...
            'Units','normalized', 'fontweight','bold','FontSize',8,  ...
            'HorizontalAlignment','right');
        %Column 1
        tH(1,1)=text(x1-.02,y(1),'Welch PSD','Parent',aH, ...
            'FontWeight','bold');
        tH(2,1)=text(x1,y(2),'VLF','Parent',aH,'Units','normalized');
        tH(3,1)=text(x1,y(3),'LF','Parent',aH,'Units','normalized');
        tH(4,1)=text(x1,y(4),'HF','Parent',aH,'Units','normalized');
        tH(5,1)=text(x1-.02,y(5),'Burg PSD','Parent',aH, ...
            'Units','normalized', 'FontWeight','bold');
        tH(6,1)=text(x1,y(6),'VLF','Parent',aH,'Units','normalized');
        tH(7,1)=text(x1,y(7),'LF','Parent',aH,'Units','normalized');
        tH(8,1)=text(x1,y(8),'HF','Parent',aH,'Units','normalized');
        tH(9,1)=text(x1-.02,y(9),'Lomb-Scargle PSD (norm)','Parent',aH, ...
            'Units','normalized', 'FontWeight','bold');
        tH(10,1)=text(x1,y(10),'VLF','Parent',aH,'Units','normalized');
        tH(11,1)=text(x1,y(11),'LF','Parent',aH,'Units','normalized');
        tH(12,1)=text(x1,y(12),'HF','Parent',aH,'Units','normalized');
        
        %Column 2        
        tH(2,2)=text(x2,y(2),'0.00','Parent',aH,'Units','normalized');
        tH(3,2)=text(x2,y(3),'0.00','Parent',aH,'Units','normalized');
        tH(4,2)=text(x2,y(4),'0.00','Parent',aH,'Units','normalized');
        tH(6,2)=text(x2,y(6),'0.00','Parent',aH,'Units','normalized');
        tH(7,2)=text(x2,y(7),'0.00','Parent',aH,'Units','normalized');
        tH(8,2)=text(x2,y(8),'0.00','Parent',aH,'Units','normalized');
        tH(10,2)=text(x2,y(10),'0.00','Parent',aH,'Units','normalized');
        tH(11,2)=text(x2,y(11),'0.00','Parent',aH,'Units','normalized');
        tH(12,2)=text(x2,y(12),'0.00','Parent',aH,'Units','normalized');
        %Column 3        
        tH(2,3)=text(x3,y(2),'0.00','Parent',aH,'Units','normalized');
        tH(3,3)=text(x3,y(3),'0.00','Parent',aH,'Units','normalized');
        tH(4,3)=text(x3,y(4),'0.00','Parent',aH,'Units','normalized');
        tH(6,3)=text(x3,y(6),'0.00','Parent',aH,'Units','normalized');
        tH(7,3)=text(x3,y(7),'0.00','Parent',aH,'Units','normalized');
        tH(8,3)=text(x3,y(8),'0.00','Parent',aH,'Units','normalized');
        tH(10,3)=text(x3,y(10),'0.00','Parent',aH,'Units','normalized');
        tH(11,3)=text(x3,y(11),'0.00','Parent',aH,'Units','normalized');
        tH(12,3)=text(x3,y(12),'0.00','Parent',aH,'Units','normalized');
        %Column 4
        tH(2,4)=text(x4,y(2),'0.00','Parent',aH,'Units','normalized');
        tH(3,4)=text(x4,y(3),'0.00','Parent',aH,'Units','normalized');
        tH(4,4)=text(x4,y(4),'0.00','Parent',aH,'Units','normalized');        
        tH(6,4)=text(x4,y(6),'0.00','Parent',aH,'Units','normalized');
        tH(7,4)=text(x4,y(7),'0.00','Parent',aH,'Units','normalized');
        tH(8,4)=text(x4,y(8),'0.00','Parent',aH,'Units','normalized');        
        tH(10,4)=text(x4,y(10),'0.00','Parent',aH,'Units','normalized');
        tH(11,4)=text(x4,y(11),'0.00','Parent',aH,'Units','normalized');
        tH(12,4)=text(x4,y(12),'0.00','Parent',aH,'Units','normalized');
        %Column 5
        tH(3,5)=text(x5,y(3),'0.00','Parent',aH,'Units','normalized');
        tH(4,5)=text(x5,y(4),'0.00','Parent',aH,'Units','normalized');
        tH(7,5)=text(x5,y(7),'0.00','Parent',aH,'Units','normalized');
        tH(8,5)=text(x5,y(8),'0.00','Parent',aH,'Units','normalized');
        tH(11,5)=text(x5,y(11),'0.00','Parent',aH,'Units','normalized');
        tH(12,5)=text(x5,y(12),'0.00','Parent',aH,'Units','normalized');
        %Column 6
        tH(2,6)=text(x6,y(2),'0.00','Parent',aH,'Units','normalized');
        tH(6,6)=text(x6,y(6),'0.00','Parent',aH,'Units','normalized');
        tH(10,6)=text(x6,y(10),'0.00','Parent',aH,'Units','normalized');

        %set fonts, and alligments for all text objects of tH
        set(findobj(tH,'type','text','parent',aH),'Fontsize',8)
        set(findobj(tH,'string','0.00','parent',aH), ...
            'HorizontalAlignment','right')
        
    end
%% GUI: CreateNLTbl
    function tH = createNLTbl(aH)
        %define relative x position of cols
        x1=0.02; x2=.5; x3=.9; 
        
        %Horizontal Lines
        line([0 1],[.95 .95],'Parent',aH,'Color','black')
        line([0 1],[.85 .85],'Parent',aH,'Color','black')
        line([0 1],[0 0],'Parent',aH,'Color','black')
        text(0,1,'Nonlinear Statistics','Parent',aH, ...
            'Units','normalized', 'fontweight','bold','FontSize',8)
        %Col Headers
        text(x1-.02,.9,'Variable','Parent',aH,'Units','normalized' ...
            , 'fontweight','bold','fontsize',8)
        text(x2,.9,'Units','Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8)
        text(x3,.9,'Value','Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8)
        %Column 1
        tH(1,1)=text(x1-.02,.75,'Entropy','Parent',aH, ...
            'Units','normalized', 'fontweight','bold');
        tH(2,1)=text(x1,.65,'SampEn','Parent',aH,'Units', ...
            'normalized');
        tH(3,1)=text(x1-.02,.55,'DFA','Parent',aH,'Units', ...
            'normalized', 'fontweight','bold');
        tH(4,1)=text(x1,.45,'\alpha_a_l_l','Parent',aH, ...
            'Units','normalized');
        tH(5,1)=text(x1,.35,'\alpha_1','Parent',aH, 'Units','normalized');
        tH(6,1)=text(x1,.25,'\alpha_2','Parent',aH, 'Units','normalized');
        %Column 2
        tH(2,2)=text(x2,.65,'-','Parent',aH,'Units','normalized');        
        tH(4,2)=text(x2,.45,'-','Parent',aH,'Units','normalized');
        tH(5,2)=text(x2,.35,'-','Parent',aH,'Units','normalized');
        tH(6,2)=text(x2,.25,'-','Parent',aH,'Units','normalized');
        %Column 3
        tH(2,3)=text(x3,.65,'0.00','Parent',aH,'Units','normalized');
        tH(4,3)=text(x3,.45,'0.00','Parent',aH,'Units','normalized');
        tH(5,3)=text(x3,.35,'0.00','Parent',aH,'Units','normalized');
        tH(6,3)=text(x3,.25,'0.00','Parent',aH,'Units','normalized');
        
        %set fonts, and alligments for all text objects of tH
        set(findobj(tH,'flat','string','-','parent',aH), ...
            'HorizontalAlignment','right')
        set(findobj(tH,'flat','string','0.00','parent',aH), ...
            'HorizontalAlignment','right')
        set(findobj(tH,'type','text','parent',aH),'Fontsize',8)
    end
%% GUI: CreateTFTbl
    function tH = createTFTbl(aH)        
        %define relative x position of cols
        x1=0.02; x2=.35; x3=.5125; x4=.675; x5=.8375; x6=.98;
        %define relative y position of rows
        y=linspace(0.75,0.05,12); %evenly space out 12 text items
        
        line([0 1],[.95 .95],'Parent',aH,'Color','black')
        line([0 1],[.8 .8],'Parent',aH,'Color','black')
        line([0 1],[0 0],'Parent',aH,'Color','black')        
        %Header
        text(x1-.02,.88,{'Frequency','Band'},'Parent',aH, ...
            'Units','normalized', 'fontweight','bold','FontSize',8)
        text(x2,.88,{'Peak','(Hz)'},'Parent',aH,'Units','normalized', ...
           'HorizontalAlignment','right', 'fontweight','bold','FontSize',8)
        text(x3,.88,{'Power','(ms^2)'},'Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8)
        text(x4,.88,{'Power','(%)'},'Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8)
        text(x5,.88,{'Power','(n.u.)'},'Parent',aH,'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8)
        text(x6,.88,{'LF/HF','(ratio)'},'Parent',aH, ...
            'Units','normalized', ...
            'HorizontalAlignment','right', 'fontweight','bold','FontSize',8)
        %Column 1
        tH(1,1)=text(x1-.02,y(1),'Burg PSD','Parent',aH, ...
            'Units','normalized', 'FontWeight','bold');
        tH(2,1)=text(x1,y(2),'VLF','Parent',aH,'Units','normalized');
        tH(3,1)=text(x1,y(3),'LF','Parent',aH,'Units','normalized');
        tH(4,1)=text(x1,y(4),'HF','Parent',aH,'Units','normalized');
        tH(5,1)=text(x1-.02,y(5),'Lomb-Scargle PSD','Parent',aH, ...
            'Units','normalized','FontWeight','bold');
        tH(6,1)=text(x1,y(6),'VLF','Parent',aH,'Units','normalized');
        tH(7,1)=text(x1,y(7),'LF','Parent',aH,'Units','normalized');
        tH(8,1)=text(x1,y(8),'HF','Parent',aH,'Units','normalized');
        tH(9,1)=text(x1-.02,y(9),'Wavelet PSD','Parent',aH, ...
            'Units','normalized', 'FontWeight','bold');
        tH(10,1)=text(x1,y(10),'VLF','Parent',aH,'Units','normalized');
        tH(11,1)=text(x1,y(11),'LF','Parent',aH,'Units','normalized');
        tH(12,1)=text(x1,y(12),'HF','Parent',aH,'Units','normalized');
        
        %Column 2        
        tH(2,2)=text(x2,y(2),'0.00','Parent',aH,'Units','normalized');
        tH(3,2)=text(x2,y(3),'0.00','Parent',aH,'Units','normalized');
        tH(4,2)=text(x2,y(4),'0.00','Parent',aH,'Units','normalized');
        tH(6,2)=text(x2,y(6),'0.00','Parent',aH,'Units','normalized');
        tH(7,2)=text(x2,y(7),'0.00','Parent',aH,'Units','normalized');
        tH(8,2)=text(x2,y(8),'0.00','Parent',aH,'Units','normalized');
        tH(10,2)=text(x2,y(10),'0.00','Parent',aH,'Units','normalized');
        tH(11,2)=text(x2,y(11),'0.00','Parent',aH,'Units','normalized');
        tH(12,2)=text(x2,y(12),'0.00','Parent',aH,'Units','normalized');
        %Column 3        
        tH(2,3)=text(x3,y(2),'0.00','Parent',aH,'Units','normalized');
        tH(3,3)=text(x3,y(3),'0.00','Parent',aH,'Units','normalized');
        tH(4,3)=text(x3,y(4),'0.00','Parent',aH,'Units','normalized');
        tH(6,3)=text(x3,y(6),'0.00','Parent',aH,'Units','normalized');
        tH(7,3)=text(x3,y(7),'0.00','Parent',aH,'Units','normalized');
        tH(8,3)=text(x3,y(8),'0.00','Parent',aH,'Units','normalized');
        tH(10,3)=text(x3,y(10),'0.00','Parent',aH,'Units','normalized');
        tH(11,3)=text(x3,y(11),'0.00','Parent',aH,'Units','normalized');
        tH(12,3)=text(x3,y(12),'0.00','Parent',aH,'Units','normalized');
        %Column 4
        tH(2,4)=text(x4,y(2),'0.00','Parent',aH,'Units','normalized');
        tH(3,4)=text(x4,y(3),'0.00','Parent',aH,'Units','normalized');
        tH(4,4)=text(x4,y(4),'0.00','Parent',aH,'Units','normalized');        
        tH(6,4)=text(x4,y(6),'0.00','Parent',aH,'Units','normalized');
        tH(7,4)=text(x4,y(7),'0.00','Parent',aH,'Units','normalized');
        tH(8,4)=text(x4,y(8),'0.00','Parent',aH,'Units','normalized');        
        tH(10,4)=text(x4,y(10),'0.00','Parent',aH,'Units','normalized');
        tH(11,4)=text(x4,y(11),'0.00','Parent',aH,'Units','normalized');
        tH(12,4)=text(x4,y(12),'0.00','Parent',aH,'Units','normalized');
        %Column 5
        tH(3,5)=text(x5,y(3),'0.00','Parent',aH,'Units','normalized');
        tH(4,5)=text(x5,y(4),'0.00','Parent',aH,'Units','normalized');
        tH(7,5)=text(x5,y(7),'0.00','Parent',aH,'Units','normalized');
        tH(8,5)=text(x5,y(8),'0.00','Parent',aH,'Units','normalized');
        tH(11,5)=text(x5,y(11),'0.00','Parent',aH,'Units','normalized');
        tH(12,5)=text(x5,y(12),'0.00','Parent',aH,'Units','normalized');
        %Column 6
        tH(2,6)=text(x6,y(2),'0.00','Parent',aH,'Units','normalized');
        tH(3,6)=text(x6,y(3),'0.00','Parent',aH,'Units','normalized');
        tH(6,6)=text(x6,y(6),'0.00','Parent',aH,'Units','normalized');
        tH(7,6)=text(x6,y(7),'0.00','Parent',aH,'Units','normalized');
        tH(10,6)=text(x6,y(10),'0.00','Parent',aH,'Units','normalized');        
        tH(11,6)=text(x6,y(11),'0.00','Parent',aH,'Units','normalized');  
        
        set(findobj(tH,'type','text','parent',aH),'Fontsize',8)
        set(findobj(tH,'string','0.00','parent',aH), ...
            'HorizontalAlignment','right')
    end
    
    function plotIBI(h,opt,IBI,dIBI,nIBI,trend,art)        
    % plotIBI: plots ibi, trendline, and outliers/artifacts in GUI
    % 
    % Inputs:
    %   h: handle used for plotting
    %   opt: structure containing hrv analysis options
    %   IBI, dIBI, nIBI: original, detrended + ectopic correcton
    %
        cla(h.axesIBI);
        showStatus('< Plotting >');
        %Plot IBI Data            
        if strcmpi(opt.ArtReplace,'none') %highlight Artifacts
            t=IBI(:,1);
            y=IBI(:,2);
            linecolor='y';
        else %plot preprocessed ibi            
            if ~strcmpi(opt.ArtReplace,'remove')
                t=nIBI(:,1);
                y=nIBI(:,2);
                linecolor='r';
            else %if removeing artifacts plot original
                t=IBI(:,1);
                y=IBI(:,2);
                linecolor='r';
            end
        end
        
        %plot IBI
        plot(h.axesIBI,t,y,'.-')
        hold(h.axesIBI,'on');
        plot(h.axesIBI,t(art),y(art),'.r')
        
        %plot trend
        if ~strcmpi(opt.Detrend,'none')
            plot(h.axesIBI,trend(:,1),trend(:,2),'r','LineWidth',2);
        end
        hold(h.axesIBI,'off');
        
        %determine y axes limits
        yrange=abs(max(y)-min(y));
        ylim=[min(y)-(yrange*0.05), max(y)+(yrange*0.05)];                        
        %determine x axes limits and labels
        xlim=[min(t) max(t)];
        %determine xtick labels
        xtick=get(h.axesIBI,'xtick');
        xticklabel=cell(length(xtick),1);
        for i=1:length(xtick)
            xticklabel{i} = ...
                datestr(datenum(num2str(xtick(i)),'SS'),'HH:MM:SS');
        end
        %set tick lables and axes limits
        xlabel(h.axesIBI,'Time (hh:mm:ss)','FontSize',10);
        ylabel(h.axesIBI,'IBI (s)','FontSize',10);
        set(h.axesIBI,'xlim',xlim,'ylim',ylim, ...
            'xtick',xtick,'xticklabel',xticklabel,'FontSize',8)
        
        %set event to copy fig on dblclick
        set(h.axesIBI,'ButtonDownFcn',@copyIBIAxes);
    end   
    
    function output=getHRV(f,opt)
    % getHRV: computes all HRV
    %
    % Inputs:
    %   f: file name of ibi file
    %   opt: structure containing all hrv analysis options
    % Outputs:
    %   output: structure containing all hrv results
    %
    % NOTE: If you change getHRV or detrendIBI functions here you will need
    % to copy the changes over to the batchHRV.m module to use batch
    % proccessing
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % LOAD IBI
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        showStatus('< Loading IBI >');
        nIBI=[]; dIBI=[];
        IBI=loadIBI(f,opt);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Preprocess Data
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        showStatus('< Preprocessing >');

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

        %Note: We don't need to use all the input arguments,but we will
        %let the function handle all inputs
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

        if sum(art)>0
            set(h.lblArtLocate,'string', ...
                ['Ectopic Detection' ' [' ...
                sprintf('%.2f',sum(art)/size(IBI,1)*100) '%]'])
        else
            set(h.lblArtLocate,'string','Ectopic Detection')
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Plot IBI
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        plotIBI(h,opt,IBI,dIBI,nIBI,trend,art);
        flagPreviewed=true;
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %Calculate HRV
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        output.ibiinfo.count=size(IBI,1); % total # of ibi
        output.ibiinfo.outliers=sum(art); % number of outliers
        
        %Time-Domain (using non-detrented ibi)
        showStatus('< Time Domain >');
        output.time=timeDomainHRV(nIBI,opt.SDNNi*60,opt.pNNx);
        %output.time.mean=round(mean(nIBI(:,2).*1000)*10)/10;
        %output.time.meanHR=round(mean(60./nIBI(:,2))*10)/10;
        
        %Freq-Domain
        showStatus('< Freq Domain >');
        output.freq= ...
            freqDomainHRV(dIBI,opt.VLF,opt.LF,opt.HF,opt.AROrder,...
            opt.WinWidth,opt.WinOverlap,opt.Points,opt.Interp);            
        
        %Nonlinear (using non-detrented ibi)
        showStatus('< Nonlinear >');
        output.nl= ...
            nonlinearHRV(nIBI,opt.m,opt.r,opt.n1,opt.n2,opt.breakpoint);        
        %Poincare
        showStatus('< Poincare >');
        output.poincare=poincareHRV(nIBI);
        
        %Time-Freq
        showStatus('< Time Freq >');            
        output.tf=timeFreqHRV(dIBI,nIBI,opt.VLF,opt.LF,opt.HF,opt.AROrder, ...
            opt.tfWinSize,opt.tfOverlap,opt.Points,opt.Interp, ...
            {'ar','lomb','wavelet'});
        %%%%%%%%%%%%%%%%%%%%%%%                            

        showStatus('');
        flagProcessed=true;            
    end

    function plotPSD(aH,F,PSD,VLF,LF,HF,limX,limY,flagVLF,flagLS)
    % plotPSD: plots PSD in the given axis handle
    %
    % Inputs:
    %   aH: axis handle to use for plotting
    %   T,F,PSD: time, freq, and psd arrays
    %   VLF, LF, HF: VLF, LF, HF freq bands
    %   limX, limY:
    %   flagVLF: (true/false) determines if VLF is area is shaded
    %   flagLS: set to (true) if ploting normalized PSD from LS   
            
        if nargin<10; flagLS=false; end
        if nargin<9; flagVLF=true; end                
        if isempty(flagVLF); flagVLF=true; end
        if isempty(flagLS); flagLS=false; end
        
        cla(aH)
        if ~flagLS %LS PSD untis are normalized...don't covert
            PSD=PSD./(1000^2); %convert to s^2/hz or s^2
        end       
        
        % find the indexes corresponding to the VLF, LF, and HF bands
        iVLF= find( (F>=VLF(1)) & (F<VLF(2)) );
        iLF = find( (F>=LF(1)) & (F<LF(2)) );
        iHF = find( (F>=HF(1)) & (F<HF(2)) );
        
        %shade areas under PSD curve
        area(aH,F(:),PSD(:),'FaceColor',[.8 .8 .8]); %shade everything grey       
        hold(aH,'on');
        if flagVLF %shade vlf
            area(aH,F(iVLF(1):iVLF(end)+1),PSD(iVLF(1):iVLF(end)+1),...
                'FaceColor',color.vlf);
        end
        %shade lf
        area(aH,F(iLF(1):iLF(end)+1),PSD(iLF(1):iLF(end)+1), ...
            'FaceColor',color.lf);
        %shade hf
        if (iHF(end)+1)>size(PSD,1)
            area(aH,F(iHF(1):iHF(end)),PSD(iHF(1):iHF(end)),...
                'FaceColor',color.hf);         
            %patch([F(iVLF(1)),F(iVLF),F(iVLF(end))],...
            %[0,abs(PSD(iVLF)),0],[0 0 .8])   
        else
            area(aH,F(iHF(1):iHF(end)+1),PSD(iHF(1):iHF(end)+1),...
                'FaceColor',color.hf);
        end
        hold(aH,'off');
        
        limX=[0 (HF(end)*1.1)];
        %set axes limits
        if ~isempty(limX)
            set(aH,'xlim',[limX(1) limX(2)]);
        else
            dx=(max(F)-min(F))*0.01;
            set(aH,'xlim',[0 max(F)+dx]);
        end
        if ~isempty(limY)
            set(aH,'ylim',[limY(1) limY(2)]);
        else
            if max(PSD)~= 0
                dy=(max(PSD)-min(PSD))*0.01;
                set(aH,'ylim',[0 max(PSD)+dy]);
            end
        end
        
        %set event to copy fig on dblclick
         set(aH,'ButtonDownFcn',@copyAxes);
    end   

    function plotSpectrogram(aH,T,F,PSD,VLF,LF,HF,limX,limY,flagWavelet) 
    % plotSpectrogram: plots a spectrogram in the given axis handle (aH)
    %
    % Inputs:
    %   aH: axis handle to use for plotting
    %   T,F,PSD: time, freq, and psd arrays
    %   VLF, LF, HF: VLF, LF, HF freq bands
    %   plotType: type of plot to produce (mesh, surf, or image)
    %   flagWavelet: (true/false) determines if psd is from wavelet
    %   transform. Wavelet power spectrum requires log scale    
         
        if (nargin < 10), flagWavelet=false; end                        
        %convert to period, see wavelet code for reasons
        if flagWavelet; F=1./F; end 
        
        cla(aH)   
        PSD=PSD./(1000^2); %convert to s^2/hz or s^2                
        xlimit=[nIBI(1,1) nIBI(end,1)];
        
        axes(aH)                
        
        if flagWavelet                
            childH=imagesc(T,log2(F),PSD);
            set(gca,'ydir','reverse')
        else
            nT=100; %define number of time points to plot. This will 
                    %be used to interpolate a smoother spectrogram image.
            T2=linspace(T(1),T(end),nT); %linear spaced time values
            PSD=interp2(T,F,PSD,T2,F); %bilinear interpolation
            childH=imagesc(T2,F,PSD);
            set(gca,'ydir','norm');
        end
        
        %add colorbar
        colormap(jet);
        pos=get(aH,'position');
        hC=colorbar(aH,'fontsize',7,'position',[.95-.03 pos(2) .025 pos(4)]);
        p=get(hC,'position'); p(3)=p(3)/2; 
        
        %draw lines for vlf, lf, and hf bands
        x=xlimit'; x=[x,x,x];
        y=[VLF(2),LF(2),HF(2)]; y=[y;y];
        z=max(max(PSD(:,:))); z=[z,z,z;z,z,z];
        if flagWavelet
            y=log2(1./y); %log2 of period
            Yticks = 2.^(fix(log2(min(F))):fix(log2(max(F))));
            YtickLabels=cell(size(Yticks));
            for i=1:length(Yticks)
                YtickLabels{i}=num2str(1./Yticks(i),'%0.3f');
            end
            set(gca,'YLim',log2([min(Yticks) max(Yticks)]), ...
                'YTick',log2(Yticks(:)), ...
                'YTickLabel',YtickLabels);
        end        
        set(line(x,y,z),'color',[1 1 1]);
                
        %axis limits        
       % xlim(xlimit)
        
        %axis lables
        xlabel('Time (s)', 'FontSize', 8)
        ylabel('F (Hz)', 'FontSize', 8)
        
        %set event to copy fig on dblclick
         set(aH,'ButtonDownFcn',@copyAxes);
         set(childH,'ButtonDownFcn',@copyParentAxes);
    end

    function plotWaterfall(aH,T,F,PSD,VLF,LF,HF,plotType,flagWavelet)
    % plotWaterfall: creates a waterfall plot of consecutive PSD
    %
    % Inputs:
    %   aH: axis handle to use for plotting
    %   T,F,PSD: time, freq, and psd arrays
    %   VLF, LF, HF: VLF, LF, HF freq bands
    %   plotType: type of plot to produce (waterfall or surf)
    %   flagWavelet: (true/false) determines if psd is from wavelet
    %   transform. Wavelet power spectrum requires log scale
        
        if (nargin < 9), flagWavelet=false; end
        if (nargin < 8), plotType = 'surf'; end
        %convert to period, see wavelet code for reason
        if flagWavelet; F=1./F; end 
        
        cla(aH)        
        PSD=PSD./(1000^2); %convert to s^2/hz or s^2
        
        PP=PSD;
        %PP(PP<-2)=-2; %to highlight the peaks, not giving visibility to
        %unnecessary valleys.        
        [TT,FF] = meshgrid(T,F);                
        
        %plot waterfall
        axes(aH)
        if flagWavelet; FF=log2(FF); end
        if strcmpi(plotType,'waterfall')            
            childH=waterfall(TT',FF',PP');
            aP=findobj(gca,'plotType','patch');
            set(aP,'FaceColor',[0.8314 0.8157 0.7843])
        else
            childH=surf(TT,FF,PP,'parent',aH,...
                'LineStyle','none',...
                'FaceColor','interp');
        end
        
        %determin axes limits
        xlim=[min(T) max(T)];
        xrange=abs(max(xlim)-min(xlim)); dx=0.01*xrange;
        xlim=[xlim(1)-2*dx xlim(2)+dx]; % add 1%        
        if flagWavelet
            ylim=[min(log2(F)) max(log2(F))];
        else
            ylim=[0 (HF(end)*1.1)];
            %ylim=[min(F) max(F)];
        end 
        zlim=[min(min(PSD)) max(max(PSD))];
        zrange=abs(max(zlim)-min(zlim)); dz=0.01*zrange;
        zlim=[zlim(1)-dz zlim(2)+dz]; % add 1%
        
        %draw lines for vlf, lf, and hf bands along bottom
        x=[xlim(1);xlim(2)];x=[x,x,x];
        y=[VLF(2),LF(2),HF(2)];y=[y;y];
        z=zlim(1); z=[z,z,z;z,z,z];
        if flagWavelet; y=log2(1./y); end %log2 of period
        set(line(x,y,z),'color','black','linewidth',2.5);
        
        %draw vert lines for vlf, lf, and hf bands along back
        x=[xlim(2);xlim(2)];x=[x,x,x];
        y=[VLF(2),LF(2),HF(2)];y=[y;y];
        z=[zlim(1); zlim(2)]; z=[z,z,z];
        if flagWavelet
            y=log2(1./y); %log2 of period
            Yticks = 2.^(fix(log2(min(F))):fix(log2(max(F))));
            YtickLabels=cell(size(Yticks));
            for i=1:length(Yticks)
                YtickLabels{i}=num2str(1./Yticks(i),'%0.3f');
            end
            set(gca,'YLim',log2([min(Yticks) max(Yticks)]), ...
                'YTick',log2(Yticks(:)), ...
                'YTickLabel',YtickLabels);
        end        
        set(line(x,y,z),'color','black','linewidth',2.5);
                
        view(100,35); %change 3d view
        %set limits and flip x axis dir for better plotting       
        set(aH, 'zlim',zlim, 'xlim', xlim, 'ylim', ylim, ...
            'xdir','reverse')

        %set event to copy fig on dblclick
         set(aH,'ButtonDownFcn',@copyAxes);
         set(childH,'ButtonDownFcn',@copyParentAxes);
    end

    function displayHRV(h,ibi,dibi,hrv,opt)                       
    % displayHRV: displays all HRV results and figures
    
        if isempty(hrv) %if no hrv data present break function
            return
        end
        
        showStatus('< Plotting Results >');
        
        %update hrv results tables
        updateTimeTbl(h,hrv,opt);
        updateFreqTbl(h,hrv,opt);        
        updateNLTbl(h,hrv,opt);
        updateTFTbl(h,hrv,opt);
        
        %plot hrv
        plotTime(h,ibi,opt);                
        plotFreq(h,hrv,opt);
        plotPoincare(h,nIBI,hrv,opt);
        plotNL(h,hrv,opt);
        plotTF(h,hrv,opt);        
        
        showStatus('');
    end

    function plotTime(h,ibi,opt)
    % plotTIme: plots time-doman related figures
    
        %calculate number of bins to use in histogram    
        dt=max(ibi)-min(ibi);
        binWidth=1/128*1000; 
        % 1/128 seconds is recomended bin width for humans. 
        % Reference: (1996) Heart rate variability: standards of 
        % measurement, physiological interpretation and clinical use.        
        nBins=round(dt/binWidth);
        
        %temporay overide of number of bins.
        nBins=32;
        
        %plot histogram of ibi
        axes(h.axesHistIBI)
        hist(h.axesHistIBI,ibi(:,2),nBins); %plot        
        hHist=findobj(gca,'Type','patch'); %get hist handle
        set(hHist,'FaceColor',color.hist.face,'EdgeColor',color.hist.edge)        
        %set axis limits
        axis(h.axesHistIBI,'tight');
        xlim=get(h.axesHistIBI,'xlim'); %get xlim
        ylim=get(h.axesHistIBI,'ylim'); %get ylim
        ylim=ylim.*[1 1.1]; %add 10% to height
        dx=abs(max(xlim)-min(xlim))*0.05; %5percent of xlim range
        xlim=xlim+[-dx dx]; %add dx to each side of hist        
        set(h.axesHistIBI,'ylim',ylim,'xlim',xlim,'FontSize',7)
        %set labels
        xlabel(h.axesHistIBI,'IBI (s)');
        title(h.axesHistIBI,'IBI Histogram','FontSize',9);
        %set event to copy fig on dblclick
        set(h.axesHistIBI,'ButtonDownFcn',@copyAxes);
        set(hHist,'ButtonDownFcn',@copyParentAxes)
        
        %plot histogram of bpm
        axes(h.axesHistBPM)
        hist(h.axesHistBPM,60./ibi(:,2),nBins);        
        hHist=findobj(gca,'Type','patch');
        set(hHist,'FaceColor',color.hist.face,'EdgeColor',color.hist.edge)
        %set axis limits
        axis(h.axesHistBPM,'tight');
        xlim=get(h.axesHistBPM,'xlim'); %get xlim
        ylim=get(h.axesHistBPM,'ylim'); %get ylim
        ylim=ylim.*[1 1.1]; %add 10% to height
        dx=abs(max(xlim)-min(xlim))*0.05; %5percent of xlim range
        xlim=xlim+[-dx dx]; %add dx to each side of hist        
        set(h.axesHistBPM,'ylim',ylim,'xlim',xlim,'FontSize',7)
        %set labels
        xlabel(h.axesHistBPM,'HR (bpm)');
        title(h.axesHistBPM,'HR Histogram','FontSize',9);
        %set event to copy fig on dblclick
        set(h.axesHistBPM,'ButtonDownFcn',@copyAxes);
        set(hHist,'ButtonDownFcn',@copyParentAxes)
    end

    function updateTimeTbl(h,hrv,opt)
    % updateTimeTbl: updates time-domain table with hrv data
        hrv=hrv.time;   %time domain hrv
        tH=h.text.time; %handles of text objects
        
        set(tH(1,3),'string',sprintf('%0.1f',hrv.mean))
        set(tH(2,3),'string',sprintf('%0.1f',hrv.SDNN))
        set(tH(3,3),'string',sprintf('%0.1f',hrv.meanHR))
        set(tH(4,3),'string',sprintf('%0.1f',hrv.sdHR))
        set(tH(5,3),'string',sprintf('%0.1f',hrv.RMSSD))
        set(tH(6,3),'string',sprintf('%0.0f',hrv.NNx))
        set(tH(7,3),'string',sprintf('%0.1f',hrv.pNNx))      
        set(tH(8,3),'string',sprintf('%0.1f',hrv.SDNNi))
        set(tH(10,3),'string',sprintf('%0.1f',hrv.HRVTi))
        set(tH(11,3),'string',sprintf('%0.1f',hrv.TINN))
    end

    function updateFreqTbl(h,hrv,opt)
    % updateFreqTbl: updates freq-domain results table with hrv data
        welch=hrv.freq.welch.hrv;
        ar=hrv.freq.ar.hrv;
        lomb=hrv.freq.lomb.hrv;    
        tH=h.text.freq; %handles of text objects
        
        %column 2            
        set(tH(2,2),'string',sprintf('%0.2f',welch.peakVLF))
        set(tH(3,2),'string',sprintf('%0.2f',welch.peakLF))
        set(tH(4,2),'string',sprintf('%0.2f',welch.peakHF))
        set(tH(6,2),'string',sprintf('%0.2f',ar.peakVLF))
        set(tH(7,2),'string',sprintf('%0.2f',ar.peakLF))
        set(tH(8,2),'string',sprintf('%0.2f',ar.peakHF))
        set(tH(10,2),'string',sprintf('%0.2f',lomb.peakVLF))      
        set(tH(11,2),'string',sprintf('%0.2f',lomb.peakLF))
        set(tH(12,2),'string',sprintf('%0.2f',lomb.peakHF))

        %Column 3
        set(tH(2,3),'string',sprintf('%0.1f',welch.aVLF))
        set(tH(3,3),'string',sprintf('%0.1f',welch.aLF))
        set(tH(4,3),'string',sprintf('%0.1f',welch.aHF))
        set(tH(6,3),'string',sprintf('%0.1f',ar.aVLF))
        set(tH(7,3),'string',sprintf('%0.1f',ar.aLF))
        set(tH(8,3),'string',sprintf('%0.1f',ar.aHF))
        set(tH(10,3),'string',sprintf('%0.1f',lomb.aVLF))      
        set(tH(11,3),'string',sprintf('%0.1f',lomb.aLF))
        set(tH(12,3),'string',sprintf('%0.1f',lomb.aHF))
                
        %Column 4
        set(tH(2,4),'string',sprintf('%0.1f',welch.pVLF))
        set(tH(3,4),'string',sprintf('%0.1f',welch.pLF))
        set(tH(4,4),'string',sprintf('%0.1f',welch.pHF))       
        set(tH(6,4),'string',sprintf('%0.1f',ar.pVLF))
        set(tH(7,4),'string',sprintf('%0.1f',ar.pLF))
        set(tH(8,4),'string',sprintf('%0.1f',ar.pHF))       
        set(tH(10,4),'string',sprintf('%0.1f',lomb.pVLF))      
        set(tH(11,4),'string',sprintf('%0.1f',lomb.pLF))
        set(tH(12,4),'string',sprintf('%0.1f',lomb.pHF))        
       
        %Column 5)
        set(tH(3,5),'string',sprintf('%0.3f',welch.nLF))
        set(tH(4,5),'string',sprintf('%0.3f',welch.nHF))
        set(tH(7,5),'string',sprintf('%0.3f',ar.nLF))
        set(tH(8,5),'string',sprintf('%0.3f',ar.nHF))
        set(tH(11,5),'string',sprintf('%0.3f',lomb.nLF))
        set(tH(12,5),'string',sprintf('%0.3f',lomb.nHF))
        
        %Column 6
        set(tH(2,6),'string',sprintf('%0.3f',welch.LFHF))
        set(tH(6,6),'string',sprintf('%0.3f',ar.LFHF))
        set(tH(10,6),'string',sprintf('%0.3f',lomb.LFHF))
    end

    function updateNLTbl(h,hrv,opt)
    % updateNLTbl: update Nonlinear results table with hrv data    
        hrv=hrv.nl;   %nonlinear hrv
        tH=h.text.nl; %handles of text objects
        
        set(tH(2,3),'string',sprintf('%0.3f',hrv.sampen(end)))
        set(tH(4,3),'string',sprintf('%0.3f',hrv.dfa.alpha(1)))
        set(tH(5,3),'string',sprintf('%0.3f',hrv.dfa.alpha1(1)))
        set(tH(6,3),'string',sprintf('%0.3f',hrv.dfa.alpha2(1))) 
    end

    function updateTFTbl(h,hrv,opt)
    % updateTFTbl: updates time-freq results table with hrv data    
        ar=hrv.tf.ar.global.hrv;
        lomb=hrv.tf.lomb.global.hrv;
        wav=hrv.tf.wav.global.hrv;
        tH=h.text.tf; %handles of text objects
        
        %column 2            
        set(tH(2,2),'string',sprintf('%0.2f',ar.peakVLF))
        set(tH(3,2),'string',sprintf('%0.2f',ar.peakLF))
        set(tH(4,2),'string',sprintf('%0.2f',ar.peakHF))
        set(tH(6,2),'string',sprintf('%0.2f',lomb.peakVLF))
        set(tH(7,2),'string',sprintf('%0.2f',lomb.peakLF))
        set(tH(8,2),'string',sprintf('%0.2f',lomb.peakHF))
        set(tH(10,2),'string',sprintf('%0.2f',wav.peakVLF))      
        set(tH(11,2),'string',sprintf('%0.2f',wav.peakLF))
        set(tH(12,2),'string',sprintf('%0.2f',wav.peakHF))

        %Column 3
        set(tH(2,3),'string',sprintf('%0.1f',ar.aVLF))
        set(tH(3,3),'string',sprintf('%0.1f',ar.aLF))
        set(tH(4,3),'string',sprintf('%0.1f',ar.aHF))
        set(tH(6,3),'string',sprintf('%0.1f',lomb.aVLF))
        set(tH(7,3),'string',sprintf('%0.1f',lomb.aLF))
        set(tH(8,3),'string',sprintf('%0.1f',lomb.aHF))
        set(tH(10,3),'string',sprintf('%0.1f',wav.aVLF))
        set(tH(11,3),'string',sprintf('%0.1f',wav.aLF))
        set(tH(12,3),'string',sprintf('%0.1f',wav.aHF))
                
        %Column 4
        set(tH(2,4),'string',sprintf('%0.1f',ar.pVLF))
        set(tH(3,4),'string',sprintf('%0.1f',ar.pLF))
        set(tH(4,4),'string',sprintf('%0.1f',ar.pHF))        
        set(tH(6,4),'string',sprintf('%0.1f',lomb.pVLF))
        set(tH(7,4),'string',sprintf('%0.1f',lomb.pLF))
        set(tH(8,4),'string',sprintf('%0.1f',lomb.pHF))        
        set(tH(10,4),'string',sprintf('%0.1f',wav.pVLF))      
        set(tH(11,4),'string',sprintf('%0.1f',wav.pLF))
        set(tH(12,4),'string',sprintf('%0.1f',wav.pHF))
               
        %Column 5)
        set(tH(3,5),'string',sprintf('%0.3f',ar.nLF))
        set(tH(4,5),'string',sprintf('%0.3f',ar.nHF))        
        set(tH(7,5),'string',sprintf('%0.3f',lomb.nLF))
        set(tH(8,5),'string',sprintf('%0.3f',lomb.nHF))        
        set(tH(11,5),'string',sprintf('%0.3f',wav.nLF))
        set(tH(12,5),'string',sprintf('%0.3f',wav.nHF))
                
        %Column 6
        set(tH(2,6),'string',sprintf('%0.3f',ar.LFHF))
        set(tH(3,6),'string',sprintf('%0.3f',hrv.tf.ar.hrv.rLFHF))
        set(tH(6,6),'string',sprintf('%0.3f',lomb.LFHF))
        set(tH(7,6),'string',sprintf('%0.3f',hrv.tf.lomb.hrv.rLFHF))
        set(tH(10,6),'string',sprintf('%0.3f',wav.LFHF))
        set(tH(11,6),'string',sprintf('%0.3f',hrv.tf.wav.hrv.rLFHF))
        
    end

    function plotFreq(h,hrv,opt)
    % plotFreq: plots freq-domain related figures
        if  strcmp(get(get(h.btngrpFreqPlot,'SelectedObject'), ...
                'string'), 'Welch')
            psd=hrv.freq.welch.psd;
            f=hrv.freq.welch.f;
            ylbl='PSD (s^2/Hz)';
            flagLS=false;
        elseif strcmp(get(get(h.btngrpFreqPlot,'SelectedObject'), ...
                'string'), 'Burg')
            psd=hrv.freq.ar.psd;
            f=hrv.freq.ar.f;
            ylbl='PSD (s^2/Hz)';
            flagLS=false;
        else
            psd=hrv.freq.lomb.psd;
            f=hrv.freq.lomb.f;
            ylbl='PSD (normalized)';
            flagLS=true;
        end
        plotPSD(h.axesFreq,f,psd,opt.VLF,opt.LF,opt.HF,[],[],true,flagLS);
        % configure the labels
        set(h.axesFreq,'FontSize',7);
        xlabel(h.axesFreq,'Freq (Hz)','FontSize',9); 
        ylabel(h.axesFreq,ylbl,'FontSize',9);
        
        
    end

%% Helper: Plot - Poincare
    function plotPoincare(h,ibi,hrv,opt)
        hrv=hrv.poincare;
                
        %create poincare plot
        x=ibi(1:end-1,2);
        y=ibi(2:end,2);
        dx=abs(max(x)-min(x))*0.05; xlim=[min(x)-dx max(x)+dx];
        dy=abs(max(y)-min(y))*0.05; ylim=[min(y)-dy max(y)+dy]; 
        plot(h.axesPoincare,x,y,'o','MarkerSize',3)
        
        %calculate new x axis at 45 deg counterclockwise. new x axis = a
        a=x./cos(pi/4);     %translate x to a
        b=sin(pi/4)*(y-x);  %tranlsate x,y to b
        ca=mean(a);         %get the center of values along the 'a' axis
        %tranlsate center to xyz
        [cx cy cz]=deal(ca*cos(pi/4),ca*sin(pi/4),0); 
        
        hold(h.axesPoincare,'on');   
        %draw y(x)=x (CD2 axis)
        hEz=ezplot(h.axesPoincare,'x',[xlim(1),xlim(2),ylim(1),ylim(2)]);
        set(hEz,'color','black')
        %draw y(x)=-x+2cx (CD2 axis)
        eqn=['-x+' num2str(2*cx)];
        hEz2=ezplot(h.axesPoincare,eqn,[xlim(1),xlim(2),ylim(1),ylim(2)]);
        set(hEz2,'color','black')
               
        %plot ellipse
        width=hrv.SD2/1000; %convert to s
        height=hrv.SD1/1000; %convert to s
        hE = ellipsedraw(h.axesPoincare,width,height,cx,cy,pi/4,'-r');
        set(hE,'linewidth', 2)                
        %plot SD2 inside of ellipse
        lsd2=line([cx-width cx+width],[cy cy],'color','r', ...
            'Parent',h.axesPoincare, 'linewidth',2);
        rotate(lsd2,[0 0 1],45,[cx cy 0])
        %plot SD1 inside of ellipse
        lsd1=line([cx cx],[cy-height cy+height],'color','r', ...
            'Parent',h.axesPoincare, 'linewidth',2);
        rotate(lsd1,[0 0 1],45,[cx cy 0])        
        
        hold(h.axesPoincare,'off');
        
      %  set(h.axesPoincare,'FontSize',7);
       % title(eqn,'FontSize',10)
        
        a = get(gca,'XTickLabel');
        set(gca,'XTickLabel',a,'FontSize',7)
        
        xlabel(h.axesPoincare,'IBI_N (s)','FontSize',9);
        ylabel(h.axesPoincare,'IBI_N_+_1 (s)','FontSize',9);
        h.text.p(1,1)=text(.05,.95,'SD1:','Parent',h.axesPoincare, ...
            'Units','normalized','Fontsize',8);
        h.text.p(2,1)=text(.05,.9,'SD2:','Parent',h.axesPoincare, ...
            'Units','normalized','Fontsize',8);
        h.text.p(1,2)=text(.15,.95,...
            [sprintf('%0.1f',hrv.SD1) ' ms'],...
            'Parent',h.axesPoincare,'Units','normalized','Fontsize',8);
        h.text.p(2,2)=text(.15,.9,...
            [sprintf('%0.1f',hrv.SD2) ' ms'],...
            'Parent',h.axesPoincare,'Units','normalized','Fontsize',8);
        
        axis(h.axesPoincare,'square')
        %set event to copy fig on dblclick
        set(h.axesPoincare,'ButtonDownFcn',@copyAxes);
        
    end

%% Helper: Plot - NL
    function plotNL(h,hrv,opt)
        hrv=hrv.nl;   %nonlinear hrv      
        
        %plot DFA
        x=log10(hrv.dfa.n); y=log10(hrv.dfa.F_n);
        plot(h.axesNL,x,y,'.','MarkerSize',10)                
        
        ibreak=find(hrv.dfa.n==opt.breakpoint);
        %short term fit
        lfit_a1=polyval(hrv.dfa.alpha1,x(1:ibreak));
        %long term fit
        lfit_a2=polyval(hrv.dfa.alpha2,x(ibreak+1:end));
        
        hold(h.axesNL,'on');
        plot(h.axesNL,x(1:ibreak),lfit_a1,'r-', 'linewidth',2)
        plot(h.axesNL,x(ibreak+1:end),lfit_a2,'g-','linewidth',2)
        
        hold(h.axesNL,'off');
        
        xrange=abs(max(x)-min(x)); xadd=xrange*0.06;
        xlim=[min(x)-xadd, max(x)+xadd];
        yrange=abs(max(y)-min(y)); yadd=yrange*0.06;
        ylim=[min(y)-yadd, max(y)+yadd];
        set(h.axesNL,'xlim',xlim,'ylim',ylim,'FontSize',7)
        title(h.axesNL,'DFA','FontSize',10)
        xlabel(h.axesNL,'log_1_0 n','FontSize',8)
        ylabel(h.axesNL,'log_1_0 F(n)','FontSize',8)

        %set event to copy fig on dblclick
        set(h.axesNL,'ButtonDownFcn',@copyAxes);
        
    end

%% Helper: Plot - TF
    function plotTF(h,hrv,opt)
        showStatus('< Plotting TF >');
        
        m=get(get(h.btngrpTFPlot,'SelectedObject'),'string');
        if  strcmp(m,'Burg')
            psd=hrv.tf.ar.psd;
            globalPsd=hrv.tf.ar.global.psd;
            f=hrv.tf.ar.f;
            t=hrv.tf.ar.t;
            lf=hrv.tf.ar.hrv.aLF;
            hf=hrv.tf.ar.hrv.aHF;           
            %interpolate lf/hf time series for a smoother plot
            t2 = linspace(t(1),t(end),100); %time values for interp.
            if size(psd,2)>1
                %interpolation
                lfhf=interp1(t,hrv.tf.ar.hrv.LFHF,t2,'spline')'; 
            end
            %ylbl='PSD (ms^2/Hz)';
            flagVLF=true; %plot vlf in global PSD
        elseif strcmp(m, 'LS')
            psd=hrv.tf.lomb.psd;
            globalPsd=hrv.tf.lomb.global.psd;
            f=hrv.tf.lomb.f;
            t=hrv.tf.lomb.t;
            lf=hrv.tf.lomb.hrv.aLF;
            hf=hrv.tf.lomb.hrv.aHF;
            %interpolate lf/hf time series for a smoother plot
            t2 = linspace(t(1),t(end),100); %time values for interp.
            if size(psd,2)>1
                %interpolation
                lfhf=interp1(t,hrv.tf.lomb.hrv.LFHF,t2,'spline')';
            end
            %ylbl='PSD (ms^2/Hz)';
            flagVLF=true; %plot vlf in global PSD
        else            
            psd=hrv.tf.wav.psd;
            globalPsd=hrv.tf.wav.global.psd;
            f=hrv.tf.wav.f;
            t=hrv.tf.wav.t; t2=t;
            lf=hrv.tf.wav.hrv.aLF;
            hf=hrv.tf.wav.hrv.aHF;
            lfhf=hrv.tf.wav.hrv.LFHF;
            %ylbl='PSD (normalized)';
            flagVLF=false; %do not plot vlf in global PSD            
        end
        
        % temp: only plot from 0-0.6 Hz
        freqLim=1.1*opt.HF(end);
        fi=(f<=freqLim);
        f=f(fi);
        psd=psd(fi,:);
        globalPsd=globalPsd(fi);
        
        %Type of plot (spectrogram, global PSD, etc.)
        pt=get(h.listTFPlot,'string');
        pt=pt{get(h.listTFPlot,'value')};
        cla(h.axesTF)
        switch lower(pt)
            case {'spectrogram', 'spectrogram (log)'}
                if strcmpi(pt,'spectrogram (log)')
                    psd=log(psd); %take log
                end
                plotSpectrogram(h.axesTF,t,f,psd,settings.VLF, ...
                    settings.LF,settings.HF,[],[],strcmp(m,'Wavelet'));
                xlabel(h.axesTF,'Time (s)');
                ylabel(h.axesTF,'Freq (Hz)');                                 
            case 'surface'
                plotWaterfall(h.axesTF,t,f,psd,settings.VLF, ...
                    settings.LF,settings.HF,'surf',strcmp(m,'Wavelet'))
                xlabel(h.axesTF,'Time (s)');
                ylabel(h.axesTF,'Freq (Hz)');
                zlabel(h.axesTF,'PSD (s^2/Hz)')
                %set event to copy fig on dblclick
                set(h.axesFreq,'ButtonDownFcn',@copyParentAxes);
            case 'waterfall'
                plotWaterfall(h.axesTF,t,f,psd,settings.VLF, ...
                    settings.LF,settings.HF,'waterfall',strcmp(m,'Wavelet'))
                xlabel(h.axesTF,'Time (s)');
                ylabel(h.axesTF,'Freq (Hz)');
                zlabel(h.axesTF,'PSD (s^2/Hz)')
                %set event to copy fig on dblclick
                set(h.axesFreq,'ButtonDownFcn',@copyParentAxes);
            case 'global psd'                
                plotPSD(h.axesTF,f,globalPsd,settings.VLF, ...
                    settings.LF,settings.HF,[],[],flagVLF);                    
                xlabel(h.axesTF,'Freq (Hz)');
                ylabel(h.axesTF,'Global PSD (s^2/Hz)');
            case 'lf & hf power'
                plot(h.axesTF,t,lf,'r');
                hold(h.axesTF,'on');
                plot(h.axesTF,t,hf,'b');
                hold(h.axesTF,'off');
                xlabel(h.axesTF,'Time (s)');
                ylabel(h.axesTF,'Power (ms^2)');
                legend({'LF','HF'})
                set(h.axesTF,'ButtonDownFcn',@copyAxes);
                xlim(h.axesTF,[t(1) t(end)])
            case 'lf/hf ratio'
                above=((lfhf>1).*lfhf);
                above(above==0)=1;
                below=((lfhf<1).*lfhf);
                below(below==0)=1;                 
                area(t2,above,'basevalue',1,'facecolor','c')
                hold(h.axesTF,'on')
                area(t2,below,'basevalue',1,'facecolor','m')
                hold(h.axesTF,'off')                                                
                xlabel(h.axesTF,'Time (s)');
                ylabel(h.axesTF,'LF/HF (ratio)');
                set(h.axesTF,'ButtonDownFcn',@copyAxes);
        end
        
        %set axes font sizes. This is a temp fix.
        set(h.axesTF,'fontsize',7);
        a = get(h.axesTF,'XTickLabel');
        set(h.axesTF,'XTickLabel',a,'fontsize',7)
        
        showStatus('');
    end

    function showStatus(string)
        if nargin < 1
            string='';
        end
        
        if isempty(string)
            set(h.lblStatus,'visible','off','String','');
        else
            set(h.lblStatus,'visible','on','String',string);
        end
        drawnow expose;            
    end

end