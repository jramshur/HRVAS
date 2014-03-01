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

function exportHRV(outFile,subjects,hrv,opt)
%exportHRV.m - exports hrv data to a MS Excel file
%
%INPUTS:
%   outFile: full path and name of output file
%   subjects: cell array of subject names. This will be the header name for
%       subjects
%   hrv: array of hrv structures containing hrv data
%   opt: not used 
%
%   TODO: 1. Include options used in HRV analysis.
%         2. Rework code...currently very hard to follow.
%

    if iscellstr(subjects)%check if subjects is a char array or string array
        lenS=length(subjects) ; %the number of subjects
    else
        lenS=1;
    end

%% Get total number of hrv variables and variable names
    f=1;
    varIBI={'ibi','outliers'};  %vars for # of ibi and # of artifacts
    lenIBI=2;
    
    % time domain vars
    varT=fieldnames(hrv(f).time); %get field names of hrv.time
    lenT=length(varT); %get number of field names
    
    % freq domain vars
    varFreqMethod=fieldnames(hrv(f).freq);
    varF=fieldnames(hrv(f).freq.welch.hrv);
    lenF=length(varF)*3; % times 3 because of 3 freq domain methods
    
    % poincare vars
    varP=fieldnames(hrv(f).poincare);
    lenP=length(varP);
    
    % nonlinear vars
    varNL={'sampen','alpha','alpha1','alpha2'};
    lenNL=4; %sampen, alpha, alpha1, & alpha2 = 4 variables
        
    %time-freq vars
    varTFMethod=fieldnames(hrv(f).tf);
    varTF=fieldnames(hrv(f).tf.ar.global.hrv);
    varTF{end+1}='rLFHF'; %add rLFHF
    
    % multiply by # of time-freq methods        
    lenTF=length(varTF)*length(varTFMethod);
    
    %total number of variables
    lenV=lenIBI+lenT+lenF+lenP+lenNL+lenTF;
    %%%%%%%%%%%%
    
    % Pre allocate cell array. Include 3 extra rows
    % (for method and variable name) and 1 extra 
    % column for file/subject names.
    output=cell(lenS+3,lenV+1); 
    
%% Build row header names
    for c=1:lenV
        if c<=lenIBI                                         %IBI variables
            %insert method name
            if c==1
                output{1,c+1}='IBI Info';
            end
            %insert var name
            output{2,c+1}=varIBI{c};
            %insert units
            output{3,c+1}='(count)'; 
        elseif c<=(lenIBI+lenT) && c>lenIBI                    %Time Domain
            c2=c-lenIBI;
            %insert method name
            if (c2-1)==0
                output{1,c+1}='Time Domain';
            end
            %insert var name
            varName=varT{c2};
            output{2,c+1}=varName;            
            %insert units
            switch varName
                case {'meanHR','sdHR'}
                    output{3,c+1}='(bpm)';
                case 'NNx'
                    output{3,c+1}='(count)';
                case 'pNNx'
                    output{3,c+1}='(%)';
                otherwise
                    output{3,c+1}='(ms)';
            end
        elseif c<=(lenIBI+lenT+lenF) && c>(lenIBI+lenT)        %Freq Domain
            c2=c-lenIBI-lenT;
            %insert method name
            if mod((c2-1),lenF/3)==0
                switch (c2-1)/(lenF/3)
                    case 0
                        output{1,c+1}='Freq Domain: Welch';
                    case 1
                        output{1,c+1}='Freq Domain: AR';
                    case 2
                        output{1,c+1}='Freq Domain: LS';
                end
            end            
            %insert var name            
            varName=varF{mod((c2-1),lenF/3)+1};
            output{2,c+1}=varName;
            %insert units
            switch varName
                case {'aVLF','aLF','aHF','aTotal'}
                    output{3,c+1}='(ms^2)';
                case {'LFHF'}
                    output{3,c+1}='';
                case {'peakVLF','peakLF','peakHF'}
                    output{3,c+1}='(Hz)';
                otherwise
                    output{3,c+1}='(%)';
            end                        
        elseif c<=(lenIBI+lenT+lenF+lenP)...
                    && c>(lenIBI+lenT+lenF)                       %Poincare
            c2=c-lenIBI-lenT-lenF;
            %insert method name
            if (c2-1)==0
                output{1,c+1}='Poincare';
            end            
            %insert var name            
            varName=varP{c2};
            output{2,c+1}=varName;
            %insert units            
            output{3,c+1}='(ms)';
        elseif c<=(lenIBI+lenT+lenF+lenP+lenNL)...
                    && c>(lenIBI+lenT+lenF+lenP)                 %Nonlinear
            c2=c-lenIBI-lenT-lenF-lenP;
            %insert method name
            if (c2-1)==0
                output{1,c+1}='Nonlinear';
            end            
            %insert var name            
            varName=varNL{c2};
            output{2,c+1}=varName;
            %insert units            
            switch varName
                case {'sampen'}
                    output{3,c+1}='';
                otherwise
                    output{3,c+1}='';
            end                                               
        elseif c<=(lenIBI+lenT+lenF+lenP+lenNL+lenTF) ...
                    && c>(lenIBI+lenT+lenF+lenP+lenNL)      %Time-Freq
            c2=c-lenIBI-lenT-lenF-lenP-lenNL;
            %insert method name
            if mod((c2-1),lenTF/3)==0
                switch (c2-1)/(lenTF/3)
                    case 0
                        output{1,c+1}='Time-Freq: AR';
                    case 1
                        output{1,c+1}='Time-Freq: Lomb';
                    case 2
                        output{1,c+1}='Time-Freq: Wavelet';
                end
            end
            %insert var name
            varName=varTF{mod((c2-1),lenTF/3)+1};
            output{2,c+1}=varName;
            %insert units
            switch varName
                case {'aVLF','aLF','aHF','aTotal'}
                    output{3,c+1}='(ms^2)';
                case {'LFHF','rLFHF'}
                    output{3,c+1}='';
                case {'peakVLF','peakLF','peakHF'}
                    output{3,c+1}='(Hz)';
                otherwise
                    output{3,c+1}='(%)';
            end                   
        end
    end
    
%% insert row header names
    output{1,1}='HRV Method';
    output{2,1}='HRV Variable';
    output{3,1}='Subject';    
    
   for r=1:lenS
        [path name ext]=fileparts(subjects{r}); %seperate file path
        output{r+3,1}=[name ext];
   end       
    
%% Add HRV to output array
    for f=1:lenS %rows/subjects
        for c=1:lenV %cols
            if c<=lenIBI                                          %IBI Info
                if c==1
                    output{f+3,c+1}=hrv(f).ibiinfo.count;
                elseif c==2
                    output{f+3,c+1}=hrv(f).ibiinfo.outliers;
                end                
            elseif c<=(lenIBI+lenT) && c>lenIBI                %Time Domain
                c2=c-lenIBI;
                varName=varT{c2};
                output{f+3,c+1}=hrv(f).time.(varName);
            elseif c<=(lenIBI+lenT+lenF) ...
                    && c>(lenIBI+lenT)                         %Freq Domain
                c2=c-lenIBI-lenT;
                %get 1st var name (e.g. - welch, ar, lomb...)
                if mod((c2-1),lenF/3)==0
                    i=(c2-1)/(lenF/3);
                    varName=varFreqMethod{i+1};
                end            
                %get 2nd var name (e.g. - aVLF, pLF...)
                varName2=varF{mod((c2-1),lenF/3)+1};
                output{f+3,c+1}=hrv(f).freq.(varName).hrv.(varName2);
            elseif c<=(lenIBI+lenT+lenF+lenP)...
                        && c>(lenIBI+lenT+lenF)                   %Poincare
                c2=c-lenIBI-lenT-lenF;
                varName=varP{c2};
                output{f+3,c+1}=hrv(f).poincare.(varName);
            elseif c<=(lenIBI+lenT+lenF+lenP+lenNL)...
                        && c>(lenIBI+lenT+lenF+lenP)             %Nonlinear
                c2=c-lenIBI-lenT-lenF-lenP;
                varName=varNL{c2};
                switch varName
                    case 'sampen' 
                        output{f+3,c+1}=hrv(f).nl.(varName)(end);
                    otherwise
                        output{f+3,c+1}=hrv(f).nl.dfa.(varName)(1);
                end
            elseif c<=(lenIBI+lenT+lenF+lenP+lenNL+lenTF) ...
                    && c>(lenIBI+lenT+lenF+lenP+lenNL)      %Time-Freq
                c2=c-lenIBI-lenT-lenF-lenP-lenNL;
                %get 1st var name (e.g. - welch, ar, lomb...)
                if mod((c2-1),lenTF/3)==0
                    i=(c2-1)/(lenTF/3);
                    varName=varTFMethod{i+1};
                end
                %get 2nd var name (e.g. - aVLF, pLF...)
                varName2=varTF{mod((c2-1),lenTF/3)+1};
                if ~strcmpi(varName2,'rlfhf')
                    output{f+3,c+1}= ...
                        hrv(f).tf.(varName).global.hrv.(varName2);
                else
                    output{f+3,c+1}= ...
                        hrv(f).tf.(varName).hrv.(varName2);
                end
            end
        end        
    end
    
    % Write data to file
    [path name ext]=fileparts(outFile); %seperate file path
    if strcmp(ext,'.xlsx')  % if MS Excel file .xlsx  
        xlswrite(outFile, output); %write hrv to xls file
    else %else write to csv file
        cell2csv(outFile,output);
    end
end

function cell2csv(filename,cellArray)
% Writes cell array content into a *.csv file.
%
% CELL2CSV(filename,cellArray)
%
% filename = Name of the file to save. [ i.e. 'text.csv' ]
% cellarray = Name of the Cell Array where the data is in
%
% by John Ramshur
% modified from Rob Kohr, and Sylvain Fiedler - fixed error with
% the fprintf function calls and removed some input options

    delimiter = ',';
    mode = 'w';

    fnum = fopen(filename,mode);
    for z=1:size(cellArray,1)
        for s=1:size(cellArray,2)

            var = eval(['cellArray{z,s}']);

            if size(var,1) == 0
                var = '';
            end

            if isnumeric(var) == 1
                var = num2str(var);
            end

            fprintf(fnum,'%c',var);

            if s ~= size(cellArray,2)
                fprintf(fnum,[delimiter]);
            end
        end
        fprintf(fnum,'\n');
    end
    fclose(fnum); 

end

% function output=insertIBI(in,hrv,v,c1,len)
% %Insert ibi info data into array    
%     
%     output=in;   
%     lenS=length(hrv);
%     c1=c1-1;
%     for f=1:lenS %rows/subjects
%         for c=1:len    
%             c2=c+c1;
%             %insert method name
%             if c==1
%                 output{1,c2}='IBI Info';
%             end
%             %insert var name
%             output{2,c2}=v{c};
%             %insert units
%             output{3,c2}='(count)';
% 
%             %insert HRV
%             output{f+3,c2}=hrv(f).ibiinfo.count;            
%             output{f+3,c2+1}=hrv(f).ibiinfo.outliers;
%         end    
%     end
%     
% end

