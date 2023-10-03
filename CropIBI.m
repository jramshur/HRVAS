clear;
disp('starting');
%%
% KEEP FROM TIME SECONDS
from=32;
% TO TIME
to=90;
%%
[FileName,PathName] = uigetfile('*.ibi','Select the files to import','MultiSelect','on');
FileName = cellstr(FileName);  % Care for the correct type 
for file=1:length(FileName)
curfile=fullfile(PathName,FileName{file});
%processfile(curfile,FileName{file});
processfile(curfile,from,to);
close('all');
end

function processfile(filein,from,to)

IN=csvread(filein);
summer=0;
fromi=0;
toi=0;
if to<from
    toi = length(IN);
end
for i =1:length(IN)
    summer=summer+IN(i);
    if summer>=from
        if fromi==0
            fromi=i;
        end
        if summer>=to
            if toi==0
                toi=i;
            end
        end
    end
end
fileout=replace(filein,'.ibi','_crp.ibi');
csvwrite(fileout,IN(fromi:toi));

end

