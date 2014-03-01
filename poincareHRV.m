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

function output=poincareHRV(ibi)
%poincareHRV(ibi) - calculates poincare HRV
%
%Inputs:    ibi = 2dim array containing [t (s),ibi (s)]
%           
%Outputs:   output is a structure containg HRV.


    %check inputs
    ibi(:,2)=ibi(:,2).*1000; %convert ibi to ms
    %assumes ibi units are seconds
    
%     if abs(range(ibi(:,2)))<50 %assume ibi units are seconds            
%             ibi(:,2)=ibi(:,2).*1000; %convert ibi to ms
%     end
%     if abs(range(diff(ibi(:,1))))>50 %assume time unites are ms
%         ibi(:,1)=ibi(:,1)./1000; %convert time to s
%     end

    sd=diff(ibi(:,2)); %successive differences
    rr=ibi(:,2);
    SD1=sqrt( 0.5*std(sd)^2 );
    SD2=sqrt( 2*(std(rr)^2) - (0.5*std(sd)^2) );
    
    %format decimal places
    output.SD1=round(SD1*10)/10; %ms
    output.SD2=round(SD2*10)/10; %ms

end