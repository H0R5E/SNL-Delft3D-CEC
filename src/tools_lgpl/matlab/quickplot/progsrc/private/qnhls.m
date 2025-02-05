function varargout=qnhls(cmd,varargin)
%QNHLS Read/write Quickin HLS files.
%   Read/write Quickin HLS file and convert it
%   into/from RGB colormap.
%
%   [CMAP,LABEL]=QNHLS('read',FILENAME)
%   OK=QNHLS('write',FILENAME,CMAP,LABEL)
%
%   See also RGB2HLS, HLS2RGB.

%   [CMAP,LABEL]=QNHLS(FILENAME) % read assumed

%----- LGPL --------------------------------------------------------------------
%                                                                               
%   Copyright (C) 2011-2015 Stichting Deltares.                                     
%                                                                               
%   This library is free software; you can redistribute it and/or                
%   modify it under the terms of the GNU Lesser General Public                   
%   License as published by the Free Software Foundation version 2.1.                         
%                                                                               
%   This library is distributed in the hope that it will be useful,              
%   but WITHOUT ANY WARRANTY; without even the implied warranty of               
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU            
%   Lesser General Public License for more details.                              
%                                                                               
%   You should have received a copy of the GNU Lesser General Public             
%   License along with this library; if not, see <http://www.gnu.org/licenses/>. 
%                                                                               
%   contact: delft3d.support@deltares.nl                                         
%   Stichting Deltares                                                           
%   P.O. Box 177                                                                 
%   2600 MH Delft, The Netherlands                                               
%                                                                               
%   All indications and logos of, and references to, "Delft3D" and "Deltares"    
%   are registered trademarks of Stichting Deltares, and remain the property of  
%   Stichting Deltares. All rights reserved.                                     
%                                                                               
%-------------------------------------------------------------------------------
%   http://www.deltaressystems.com
%   $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/tools_lgpl/matlab/quickplot/progsrc/private/qnhls.m $
%   $Id: qnhls.m 4612 2015-01-21 08:48:09Z mourits $

switch lower(cmd)
    case 'read'
        varargout=cell(1,max(1,nargout));
        [varargout{:}]=Local_read_hls(varargin{:});
    case 'write'
        OK=Local_write_hls(varargin{:});
        if nargout>0
            varargout={OK};
        end
    otherwise % unknown command, possibly filename
        varargout=cell(1,max(1,nargout));
        [varargout{:}]=Local_read_hls(cmd,varargin{:});
end


function [CMap,Label]=Local_read_hls(filename)
fid=fopen(filename,'r');
if fid<0
    CMap=[];
    Label='';
    return
end
Label=fgetl(fid);
i=0;
Line=fgetl(fid);
X=sscanf(Line,'%i%i%i',[1 3]);
while isequal(size(X),[1 3])
    i=i+1;
    CMap(i,:)=X;
    Line=fgetl(fid);
    if ~ischar(Line) %feof(fid)
        break
    end
    X=sscanf(Line,'%f%f%f',[1 3]);
end
CMap(:,1)=CMap(:,1)/360;
CMap(:,2:3)=CMap(:,2:3)/100;
CMap=hls2rgb(CMap);
fclose(fid);


function OK=Local_write_hls(filename,CMap,Label)
OK=0;
if nargin<2
    return
elseif nargin<3
    Label='';
end
fid=fopen(filename,'w');
if fid<0
    return
end
fprintf(fid,'%s\n',Label);
CMap=rgb2hls(CMap);
CMap(:,1)=round(360*CMap(:,1));
CMap(:,2:3)=round(100*CMap(:,2:3));
fprintf(fid,'%3i %3i %3i\n',transpose(CMap));
fclose(fid);
OK=1;
