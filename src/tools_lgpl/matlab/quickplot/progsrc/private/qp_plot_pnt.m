function [hNew,Thresholds,Param,Parent]=qp_plot_pnt(hNew,Parent,Param,data,Ops,Props)
%QP_PLOT_PNT Plot function of QuickPlot for point data sets.

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
%   $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/tools_lgpl/matlab/quickplot/progsrc/private/qp_plot_pnt.m $
%   $Id: qp_plot_pnt.m 5505 2015-10-19 13:00:47Z jagers $

T_=1; ST_=2; M_=3; N_=4; K_=5;

FirstFrame=Param.FirstFrame;
Quant=Param.Quant;
Units=Param.Units;
if ~isempty(Units)
    PName=sprintf('%s (%s)',Quant,Units);
else
    PName=Quant;
end
TStr=Param.TStr;
Selected=Param.Selected;
multiple=Param.multiple;
NVal=Param.NVal;
stn=Param.stn;

DimFlag=Props.DimFlag;
Thresholds=[];

switch NVal
    case 0
        if strcmp(Ops.facecolour,'none')
            if ishandle(hNew)
                set(hNew,'xdata',data.X, ...
                    'ydata',data.Y);
            else
                hNew=line(data.X,data.Y, ...
                    'parent',Parent, ...
                    Ops.LineParams{:});
                set(Parent,'layer','top')
            end
        else
            if ~FirstFrame
                delete(hNew)
            end
            vNaN=isnan(data.X);
            if any(vNaN)
                bs=findseries(~vNaN);
            else
                bs=[1 length(vNaN)];
            end
            for i=1:size(bs,1)
                if data.X(bs(i,1))==data.X(bs(i,2)) && ...
                        data.Y(bs(i,1))==data.Y(bs(i,2))
                    % this patch should not influence color scaling.
                    % however, the default "1" cdata will do so
                    % we cannot set the cdata to [] immediately
                    % so, we change it after having set all color options
                    hNew(i)=patch(data.X(bs(i,1):bs(i,2)), ...
                        data.Y(bs(i,1):bs(i,2)), ...
                        1, ...
                        'edgecolor',Ops.colour, ...
                        'facecolor',Ops.facecolour, ...
                        'linestyle',Ops.linestyle, ...
                        'linewidth',Ops.linewidth, ...
                        'marker',Ops.marker, ...
                        'markersize',Ops.markersize, ...
                        'markeredgecolor',Ops.markercolour, ...
                        'markerfacecolor',Ops.markerfillcolour, ...
                        'cdata',[], ...
                        'parent',Parent);
                else
                    hNew(i)=line(data.X(bs(i,1):bs(i,2)), ...
                        data.Y(bs(i,1):bs(i,2)), ...
                        'parent',Parent, ...
                        Ops.LineParams{:});
                end
            end
            set(Parent,'layer','top')
        end
        if ~isempty(stn)
            PName = [PName ': ' stn];
        end
        qp_title(Parent,{PName,TStr},'quantity',Quant,'unit',Units,'time',TStr)
    case 1
        axestype = strtok(Ops.axestype);
        if strcmp(axestype,'Distance-Val') || strcmp(axestype,'X-Val') || strcmp(axestype,'Time-Val') || strcmp(axestype,'Time-Z')
        %if multiple(T_)
            switch axestype
                case {'Distance-Val','X-Val'}
                    x = data.X;
                    xdate = 0;
                otherwise
                    x = data.Time;
                    xdate = Props.DimFlag(T_)~=5;
            end
            if FirstFrame
                hNew=line(x,data.Val, ...
                    'parent',Parent, ...
                    Ops.LineParams{:});
                if xdate
                    tick(Parent,'x','autodate')
                end
            else
                set(hNew,'xdata',x,'ydata',data.Val);
            end
            if ~isempty(stn)
                Str=stn;
            else
                Str='';
            end
            qp_title(Parent,Str,'quantity',Quant,'unit',Units,'time',TStr)
        else
            switch Ops.presentationtype
                case 'values'
                    hNew=gentextfld(hNew,Ops,Parent,data.Val,data.X,data.Y);
                    
                case 'markers'
                    hNew=genmarkers(hNew,Ops,Parent,data.Val,data.X,data.Y);
                    
                otherwise
                    if ~FirstFrame
                        delete(hNew)
                    end
                    vNaN=isnan(data.Val);
                    if any(vNaN)
                        bs=findseries(~vNaN);
                    else
                        bs=[1 length(vNaN)];
                    end
                    fill = ~strcmp(Ops.facecolour,'none');
                    for i=1:size(bs,1)
                        from=bs(i,1);
                        to=bs(i,2);
                        ecol='flat';
                        fcol='none';
                        if fill && data.X(from)==data.X(to) && ...
                                data.Y(from)==data.Y(to)
                            ecol='none';
                            fcol='flat';
                            vl=from;
                        elseif from>1
                            from=from-1;
                            data.X(from)=NaN;
                            data.Y(from)=NaN;
                            data.Val(from)=NaN;
                            vl=from:to;
                        else
                            to=to+1;
                            data.X(to)=NaN;
                            data.Y(to)=NaN;
                            data.Val(to)=NaN;
                            vl=from:to;
                        end
                        hNew(i)=patch(data.X(from:to), ...
                            data.Y(from:to), ...
                            data.Val(vl), ...
                            'edgecolor',ecol, ...
                            'facecolor',fcol, ...
                            'linestyle',Ops.linestyle, ...
                            'linewidth',Ops.linewidth, ...
                            'marker',Ops.marker, ...
                            'markersize',Ops.markersize, ...
                            'markeredgecolor',Ops.markercolour, ...
                            'markerfacecolor',Ops.markerfillcolour, ...
                            'parent',Parent);
                    end
            end
            set(Parent,'layer','top')
            if strcmp(Ops.colourbar,'none')
                qp_title(Parent,{PName,TStr},'quantity',Quant,'unit',Units,'time',TStr)
            else
                qp_title(Parent,{TStr},'quantity',Quant,'unit',Units,'time',TStr)
            end
        end
    case {2,3}
        [hNew,Thresholds,Param,Parent]=qp_plot_default(hNew,Parent,Param,data,Ops,Props);
    case 4
        if isfield(data,'XY')
            hNew=gentextfld(hNew,Ops,Parent,data.Val,data.XY(:,1),data.XY(:,2));
        else
            hNew=gentextfld(hNew,Ops,Parent,data.Val,data.X,data.Y);
        end
end
