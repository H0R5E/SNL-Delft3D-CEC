function hNew=gentextfld(hOld,Ops,Parent,Val,X,Y,Z)
%GENTEXTFLD Generic plot routine for a text field.

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
%   $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/tools_lgpl/matlab/quickplot/progsrc/private/gentextfld.m $
%   $Id: gentextfld.m 5505 2015-10-19 13:00:47Z jagers $

delete(hOld);
zcoord=nargin>6;
convert=0;
if iscellstr(Val)
    blank=0;
else
    convert=1;
    blank=isnan(Val(:));
end
if zcoord
    blank=isnan(X(:))|isnan(Y(:))|isnan(Z(:));
    Z=Z(~blank); Z=Z(:);
else
    blank=isnan(X(:))|isnan(Y(:));
end
X=X(~blank); X=X(:);
Y=Y(~blank); Y=Y(:);
Val=Val(~blank); Val=Val(:);
if iscell(Val)
    Val=protectstring(Val);
end
%
if isempty(X)
    X=NaN;
    Y=NaN;
    if zcoord
        Z=NaN;
    end
end
%
if zcoord
    hNew = line([min(X) max(X)],[min(Y) max(Y)],[min(Z) max(Z)],'linestyle','none','marker','none','parent',Parent);
    hNew = repmat(hNew,1,length(Val)+1); % pre-allocate hNew of appropriate length
    for i=1:length(Val)
        if convert
            Str=sprintf(Ops.numformat,Val(i));
        else
            Str=Val{i};
        end
        hNew(i+1)=text(X(i),Y(i),Z(i),Str,'parent',Parent); % faster to use text(X,Y,Z,Val,...)?
    end
else
    hNew = line([min(X) max(X)],[min(Y) max(Y)],'linestyle','none','marker','none','parent',Parent);
    hNew = repmat(hNew,1,length(Val)+1); % pre-allocate hNew of appropriate length
    for i=1:length(Val)
        if convert
            Str=sprintf(Ops.numformat,Val(i));
        else
            Str=Val{i};
        end
        hNew(i+1)=text(X(i),Y(i),Str,'parent',Parent); % faster to use text(X,Y,Z,Val,...)?
    end
end
set(hNew(2:end),'clipping','on',Ops.FontParams{:})
