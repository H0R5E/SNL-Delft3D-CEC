function [DomainNr,Props,subf,selected,stats,Ops]=qp_interface_update_options(mfig,UD)
%QP_INTERFACE_UPDATE_OPTIONS Update QuickPlot user interface options.

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
%   $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/tools_lgpl/matlab/quickplot/progsrc/private/qp_interface_update_options.m $
%   $Id: qp_interface_update_options.m 5632 2015-12-09 08:50:03Z jagers $

[DomainNr,Props,subf,selected,stats,vslice,hslice] = get_basics(mfig,UD.MainWin);
[Ops,PlotType,EnablePlot,EnableLoad] = get_options(Props,selected,vslice,hslice,UD);

%
%---- Rename "Quick View" button to "Quick Animate" if appropriate
%
qv=findobj(mfig,'tag','quickview');
set(qv,'string',['Quick ' PlotType],'enable',onoff(EnablePlot))
setappdata(qv,'animate',strcmp(PlotType,'Animate'))
set(findobj(mfig,'tag','loaddata'),'enable',onoff(EnableLoad))


function [DomainNr,Props,subf,selected,stats,vslice,hslice]=get_basics(mfig,MW)
T_=1; ST_=2; M_=3; N_=4; K_=5;

Handle_Domain=findobj(mfig,'tag','selectdomain');
DomainNr=get(Handle_Domain,'value');

datafields=findobj(mfig,'tag','selectfield');
Props=get(datafields,'userdata');
subf = [];
selected = [];
stats =[];
vslice=0;
hslice=0;
if isempty(Props)
    return
end

fld=get(datafields,'value');
Props=Props(fld);

if strcmp(get(MW.SubFld,'enable'),'on')
    subf={get(MW.SubFld,'value')};
else
    subf={};
end

DimFlag=Props.DimFlag;
selected=cell(size(DimFlag));
if DimFlag(T_)
    if get(MW.AllT,'value')
        selected{T_}=0;
    else
        selected{T_}=get(MW.EditT,'userdata');
    end
end
if DimFlag(ST_)
    stats=get(MW.StList,'userdata');
    alls=get(MW.AllS,'value');
    if alls
        selected{ST_}=0;
    else
        selected{ST_}=get(MW.EditS,'userdata');
    end
else
    stats={};
end

if all(~DimFlag([M_ N_ K_]))
else
    switch getvalstr(MW.HSelType)
        case 'M range and N range'
            if DimFlag(M_)
                if get(MW.AllM,'value')
                    selected{M_}=0;
                else
                    selected{M_}=get(MW.EditM,'userdata');
                end
            end
            %maxm=get(MW.MaxM,'userdata');
            if DimFlag(N_)
                if get(MW.AllN,'value')
                    selected{N_}=0;
                else
                    selected{N_}=get(MW.EditN,'userdata');
                end
            end
            %maxn=get(MW.MaxN,'userdata');
        case '(M,N) point/path'
            vslice=1;
            selected{M_}={'MN' get(MW.EditMN,'userdata')};
            if DimFlag(N_)
                selected{N_}=0;
            end
        case '(X,Y) point/path'
            vslice=1;
            selected{M_}={'XY' get(MW.EditXY,'userdata')};
            if DimFlag(N_)
                selected{N_}=0;
            end
    end
end

switch getvalstr(MW.VSelType)
    case {'K range'}
        if DimFlag(K_)
            if get(MW.AllK,'value')
                selected{K_}=0;
            else
                selected{K_}=get(MW.EditK,'userdata');
            end
        end
    case {'Z slice','dZ below surface','dZ above bed'}
        hslice=1;
end

for m = 6:length(DimFlag)
    if DimFlag(m)
        DIM = sprintf('DIM%i',m);
        if get(MW.(['All' DIM]),'value')
            selected{m} = 0;
        else
            selected{m} = get(MW.(['Edit' DIM]),'userdata');
        end
    end
end

function [Ops,PlotType,EnablePlot,EnableLoad] = get_options(Props,selected,vslice,hslice,UD)
T_=1; ST_=2; M_=3; N_=4; K_=5;
Ops = [];
PlotType='View';
EnablePlot = false;
EnableLoad = false;

[nval,nvalstr]=convertnval(Props.NVal);
DimFlag = Props.DimFlag;
if isfield(Props,'Geom') && ~isempty(Props.Geom)
    geometry=Props.Geom;
    coordinates=Props.Coords;
elseif nval<0
    geometry='SELFPLOT';
    coordinates='';
else
    if DimFlag(M_) && DimFlag(N_)
        geometry='sQUAD';
        coordinates='xy';
    elseif DimFlag(M_) || DimFlag(N_)
        geometry='sSEG';
        coordinates='x';
    else
        geometry='PNT';
        coordinates='';
    end
    if isfield(Props,'Tri') && isequal(Props.Tri,1)
        geometry='TRI';
        coordinates='xy';
    end
    if DimFlag(K_)
        geometry=cat(2,geometry,'+');
        coordinates=cat(2,coordinates,'+z');
    end
end

Units='';
if isfield(Props,'Units')
    Units=Props.Units;
end

ask_for_thinningmode = 0;
ask_for_thresholds   = 0;
ask_for_numformat    = 0;
ask_for_textprops    = 0;
ask_for_angleconvention = 0;

for i=5:-1:1
    multiple(i) = (length(selected{i})>1) | isequal(selected{i},0);
end
animate = multiple(T_);

VectorDef=0;
VectorReq=0;
if isfield(Props,'VectorDef')
    VectorDef=Props.VectorDef;
elseif isfield(Props,'MNK')
    VectorDef=Props.MNK;
end
%
%-------- PLOT OPTIONS -------------
%
OH = UD.Options.Handles;
%
vectors=0;
usesmarker=0;
forcemarker=0;
forcemarkercolor=0;
markerflatfill=0;
edgeflatcolour=0;
lineproperties=0;

triangles = 0;
thindams = nval>0 & nval<1;
MultipleColors = (nval>=1 & nval<4) | nval==6;
%--------------------------------------------------------------------------
%
%---- axes type
%
axestype={'noplot'};
switch geometry
    case 'SELFPLOT'
        axestype={''};
    case {'UGRID-NODE','UGRID-EDGE','UGRID-FACE'}
        if vslice
            if multiple(T_)
                axestype={'X-Val','X-Y','X-Time','Time-X'};
            elseif nval~=0
                axestype={'X-Val','X-Y'};
            else
                axestype={'X-Y'};
            end
        elseif multiple(M_) && multiple(K_)
            % noplot
        elseif multiple(M_)
            axestype={'X-Y'};
        elseif multiple(K_)
            axestype={'Val-Z'};
        elseif multiple(T_)
            axestype={'Time-Val','X-Y'};
        else
            axestype={'Time-Val','X-Y','Text'};
        end
    case 'UGRID-VOLUME'
    case 'PNT'
        if multiple(ST_) || multiple(M_)
            if length(coordinates)==1
                axestype={'X-Val'};
                lineproperties=1;
            else
                axestype={'X-Y'};
            end
        elseif multiple(T_)
            if isequal(coordinates,'d')
                axestype={'Time-Val','Distance-Val'};
            elseif nval==0
                axestype={'X-Y'};
            elseif isempty(coordinates)
                axestype={'Time-Val'};
            else
                axestype={'Time-Val','X-Y'};
            end
        else
            if isequal(coordinates,'d')
                axestype={'Time-Val','Distance-Val','Text'};
            elseif nval==0
                axestype={'X-Y'};
            elseif ~isempty(strfind(coordinates,'xy'))
                if nval==4 || nval==6
                    axestype={'X-Y','Text'};
                else
                    axestype={'X-Y','Time-Val','Text'};
                end
            elseif DimFlag(T_)
                axestype={'Time-Val','Text'};
            else
                axestype={'Text'};
            end
        end
    case 'PNT+'
        if multiple(K_)
            if ~multiple(M_) && ~multiple(ST_)
                if multiple(T_)
                    axestype={'Val-Z','Time-Z'};
                else
                    axestype={'Val-Z'};
                end
            end
        else
            if multiple(M_) || multiple(ST_)
                axestype={'X-Y'};
            elseif multiple(T_)
                axestype={'Time-Val','X-Y'};
            else
                axestype={'Time-Val','Text'};
            end
        end
    case {'SEG','SEG-NODE','SEG-EDGE'}
        axestype={'X-Y'};
        lineproperties=1;
    case 'sSEG'
        if multiple(M_) || multiple(N_)
            switch nval
                case {0,2,4,6}
                    axestype={'X-Y'};
                case 1
                    if isequal(coordinates,'d')
                        axestype={'Distance-Val'};
                    else
                        axestype={'X-Val'};
                    end
            end
        else
            switch nval
                case {0,2,4,6}
                    axestype={'X-Y'};
                case 1
                    if isequal(coordinates,'d')
                        axestype={'Time-Val','Distance-Val'};
                    else
                        axestype={'Time-Val','X-Val'};
                    end
            end
        end
    case 'sSEG+'
        if multiple(M_) && multiple(K_)
            axestype={'X-Z'};
        elseif multiple(M_)
            axestype={'X-Val'};
        elseif multiple(K_)
            axestype={'Val-Z'};
        else
            axestype={'X-Z'};
        end
    case {'POLYL','POLYG'}
        axestype={'X-Y'};
        if strcmp(geometry,'POLYG') && ~isfield(Props,'ClosedPoly')
            Props.ClosedPoly = 2;
        end
    case {'sQUAD','sQUAD+'}
        if multiple(K_)
            if multiple(M_) && multiple(N_) && ~vslice
                axestype={'X-Y-Z'};
            elseif multiple(M_) || multiple(N_) || vslice
                axestype={'X-Z'};
            elseif multiple(T_)
                axestype={'Val-Z','Time-Z'};
            else
                axestype={'Val-Z'};
            end
        else
            if nval==0
                axestype={'X-Y'};
            elseif nval==4 || nval==6
                if ~multiple(T_) && ~multiple(M_) && ~multiple(N_)
                    axestype={'X-Y','Text'};
                else
                    axestype={'X-Y'};
                end
            else
                if multiple(M_) && multiple(N_) && ~vslice
                    axestype={'X-Y','X-Y-Val'};
                elseif multiple(M_) || multiple(N_) || vslice
                    if multiple(T_)
                        axestype={'X-Val','X-Y','X-Time','Time-X'};
                    else
                        axestype={'X-Val','X-Y'};
                    end
                elseif multiple(T_)
                    axestype={'Time-Val','X-Y','X-Val'};
                else
                    axestype={'X-Y','X-Val','Text'};
                end
            end
        end
    case {'TRI','TRI+'}
        triangles=1;
        if vslice
            if multiple(M_) && multiple(K_)
                axestype={'X-Z'};
            elseif multiple(M_)
                if nval==0
                    axestype={'X-Y'};
                else
                    axestype={'X-Val','X-Y'};
                end
            elseif multiple(K_)
                axestype={'Val-Z'};
            else
                if multiple(T_)
                    axestype={'Time-Val'};
                else
                    axestype={'X-Y'};
                end
            end
        elseif multiple(M_) && multiple(K_)
            axestype={'X-Y-Z'};
        elseif multiple(M_)
            axestype={'X-Y'};
        elseif multiple(K_)
            axestype={'Val-Z'};
        elseif multiple(T_)
            axestype={'Time-Val'};
        else
            axestype={'X-Y'};
        end
    case 'QUAD'
    case 'GEN2D'
    case 'GEN-2D'
    case 'SEG+'
    case 'QUAD+'
    case 'POLY+'
    case 'GEN2D+'
    case 'sHEX'
    case 'TET'
    case 'WED' % WEDGE aka PRISM
    case 'HEX'
    case 'PYR'
    case 'GEN3D'
end
if isequal(axestype,{'noplot'})
    MultipleColors = 0;
end

Inactive=UD.Inactive;
Active=UD.Active;

set(setdiff(UD.Options.Handles,gcbo),'enable','off','backgroundcolor',Inactive)

h_axtype=findobj(OH,'tag','axestype=?');
if length(axestype)>1
    set(findobj(OH,'tag','axestype'),'enable','on');
    paxestype = get(h_axtype,'string');
    if isequal(paxestype',axestype)
        %
        % if the supported axes types are the same then use the previously
        % selected axes type
        %
        i = get(h_axtype,'value');
    else
        %
        % if the supported axes types are different then use the axes type
        % of the current plot if an axes object is select and if that axes
        % type is supported, otherwise use the default first axes type.
        %
        ax=qpsa;
        if length(ax)~=1 % no axes selected, or multiple axes selected
            i=1;
        else
            paxestype = getappdata(ax,'BasicAxesType');
            if isempty(paxestype)
                paxestype = getappdata(ax,'AxesType');
            end
            i = [];
            if ~isempty(paxestype)
                i = strmatch(paxestype,axestype,'exact');
            end
            if isempty(i)
                i=1;
            end
        end
    end
    set(h_axtype,'string',axestype,'value',i,'enable','on','backgroundcolor',Active)
else
    set(h_axtype,'string',{'no choice'},'value',1)
    i=1;
end
axestype=axestype{i};
%
if (multiple(M_) && ~multiple(N_) && DimFlag(N_)) || (~multiple(M_) && DimFlag(M_) && multiple(N_)) || vslice
    if isempty(strfind(axestype,'Time')) && ~multiple(K_)
        if Props.DataInCell || ~isempty(strfind(geometry,'FACE'))
            geometry = 'SEG-EDGE';
            lineproperties = 1;
        else
            geometry = 'SEG-NODE';
            lineproperties = 1;
        end
    end
end

if strcmp(axestype,'X-Y-Val')
    % skip
elseif strfind(axestype,'Val')
    MultipleColors=0;
    lineproperties=1;
    if  strcmp(axestype,'Time-Val') && ~multiple(T_)
        ask_for_textprops=1;
        ask_for_numformat=1;
    end
elseif strcmp(axestype,'Text') || (strcmp(axestype,'Time-Val') && ~multiple(T_))
    MultipleColors=0;
    ask_for_textprops=1;
    ask_for_numformat=1;
end
if nval==-1 || (nval>=0 && nval<1)
    lineproperties=1;
end
if ~isempty(strfind(axestype,'Time'))
    animate = 0;
elseif ~multiple(M_) && ~multiple (N_) && ~multiple(K_) && strcmp(axestype,'X-Y')
    animate = 0;
elseif strcmp(axestype,'Distance-Val')
    animate = 0;
end

if DimFlag(T_)
    if ~strcmpi(qp_settings('timezone'),'Ignored')
        atz = findobj(OH,'tag','axestimezone=?');
        set(findobj(OH,'tag','axestimezone'),'enable','on');
        set(atz,'enable','on','backgroundcolor',Active)
        TZsel = get(atz,'value');
        TZstr = get(atz,'string');
        TZshift = get(atz,'userdata');
        Ops.axestimezone_str   = strtok(TZstr{TZsel});
        Ops.axestimezone_shift = TZshift(TZsel);
    else
        Ops.axestimezone_shift = NaN;
    end
end

coords={'path distance','reverse path distance','x coordinate','y coordinate'};

if strfind(axestype,'X')
    SpatialH=1;
else
    SpatialH=0;
end
if strfind(axestype,'Y')
    SpatialH=SpatialH+1;
end
%
if strfind(axestype,'Z')
    SpatialV=1;
else
    SpatialV=0;
end
%
if strfind(axestype,'Time')
    TimeDim=1;
else
    TimeDim=0;
end
%
Spatial=SpatialH+SpatialV;
TimeSpatial=Spatial+TimeDim;

if strcmp(axestype,'X-Y-Z') % cannot plot 3D volumes
    %won't plot
    axestype='noplot';
end

if strfind(axestype,'Y')
    %if isfield(Props,'MName') && ~isempty(Props.MName)
    %    axestype = strrep(axestype,'X',Props.MName);
    %end
    %if isfield(Props,'NName') && ~isempty(Props.NName)
    %    axestype = strrep(axestype,'Y',Props.NName);
    %end
else
    if isfield(Props,'MName') && ~isempty(Props.MName) && multiple(M_)
        %    axestype = strrep(axestype,'X',Props.MName);
        coords={'x coordinate'};
    elseif isfield(Props,'NName') && ~isempty(Props.NName)
        %    axestype = strrep(axestype,'X',Props.NName);
        coords={'y coordinate'};
    end
end

if ismember(axestype,{'X-Val','X-Z','X-Time','Time-X'})
    pd=findobj(OH,'tag','plotcoordinate=?');
    prev_coords=get(pd,'string');
    i=get(pd,'value');
    plotcoord=prev_coords{i};
    %
    j=strmatch(plotcoord,coords,'exact');
    if ~isempty(j)
        i=j;
    else
        i=1;
    end
    %
    if length(coords)>1
        set(findobj(OH,'tag','plotcoordinate'),'enable','on');
        set(pd,'string',coords,'value',i,'enable','on','backgroundcolor',Active)
    end
    Ops.plotcoordinate=coords{i};
elseif SpatialH==1
    if isfield(Props,'MName') && ~isempty(Props.MName)
        Ops.plotcoordinate=Props.MName;
    elseif isfield(Props,'NName') && ~isempty(Props.NName)
        Ops.plotcoordinate=Props.NName;
    else
        Ops.plotcoordinate='index';
    end
end

if ~strcmp(axestype,'noplot')
    SingleColor=~MultipleColors;
elseif nval==-1
    MultipleColors=0;
    SingleColor=1;
else
    MultipleColors=0;
    SingleColor=0;
end

%--------------------------------------------------------------------------
%
%---- vector component
%
if nval==2 || nval==3
    vectors=1;
    set(findobj(OH,'tag','component'),'enable','on');
    compon=findobj(OH,'tag','component=?');
    if DimFlag(M_) && (DimFlag(N_) || triangles)
        switch VectorDef
            case 0
                compList={'vector','vector (split x,y)','patch centred vector','magnitude','angle','x component','y component'};
            case 1
                if DimFlag(K_) && DimFlag(M_) && DimFlag(N_)
                    compList={'vector','vector (split x,y)','vector (split m,n)','patch centred vector','magnitude','magnitude in plane','angle','x component','y component','z component','m component','n component'};
                    if SpatialH ~=2
                        ii=strmatch('magnitude in plane',compList,'exact');
                        compList(ii)=[];
                    end
                    if Spatial==2 && SpatialH==1
                        compList{end+1}='normal component';
                    end
                else
                    compList={'vector','vector (split x,y)','vector (split m,n)','patch centred vector','magnitude','angle','x component','y component','m component','n component'};
                end
            case 2
                compList={'vector','patch centred vector','magnitude','m component','n component'};
        end
    elseif DimFlag(M_) && DimFlag(K_)
        compList={'vector','patch centred vector','magnitude','x component','z component'};
    else
        switch nvalstr
            case 'xy'
                compList={'vector','magnitude','angle'};
                if vslice
                    switch VectorDef
                        case 2
                            compList(end+1:end+2)={'m component','n component'};
                            compList(1)=[]; % can't do vector if I only have m and n components
                        otherwise
                            compList(end+1:end+4)={'x component','y component','slice normal component','slice tangential component'};
                    end
                else
                    switch VectorDef
                        case 0
                            compList(end+1:end+2)={'x component','y component'};
                        case 1
                            compList(end+1:end+4)={'x component','y component','m component','n component'};
                        case 2
                            compList(end+1:end+2)={'m component','n component'};
                            compList(1)=[]; % can't do vector if I only have m and n components
                        case 4
                            % magnitude and angle already in compList
                        case 5
                            compList(end+1:end+4)={'x component','y component','edge normal component','edge tangential component'};
                    end
                end
            case 'xyz'
                compList={'vector','magnitude','angle','x component','y component','z component'};
            case 'xz'
                compList={'vector','magnitude','x component','z component'};
        end
    end
    
    if SpatialV
        ii=strmatch('vector (split',compList);
        compList(ii)=[];
    end
    if Spatial==1 && ~strcmp(axestype,'Val-Z')
        ii=strmatch('vector',compList);
        compList(ii)=[];
    end
    if nval==2 && SpatialV && Spatial>=2 && ~strcmp(nvalstr,'xz') % don't plot vectors without vertical component in 2DV and 3D
        ii=strmatch('vector',compList);
        compList(ii)=[];
    end
    ii=strmatch('patch centred vector',compList,'exact');
    compList(ii)=[];
    
    set(compon,'enable','on','backgroundcolor',Active)
    comp=get(compon,'value');
    prevCompList=get(compon,'string');
    if ~isequal(compList,prevCompList)
        % try to find an exact match when switching presentation type strings
        if iscellstr(prevCompList)
            comp=prevCompList{comp};
        else
            comp=prevCompList(comp,:);
        end
        comp=strmatch(comp,compList,'exact');
        if isempty(comp)
            comp=1;
        end
        set(compon,'value',1,'string',compList,'value',comp)
    end
    Ops.vectorcomponent=lower(compList{comp});
    switch Ops.vectorcomponent
        case {'vector','patch centred vector','vector (split x,y)','vector (split m,n)'}
            Ops.presentationtype=Ops.vectorcomponent;
            if VectorDef==2 && (multiple(M_) + multiple(N_) == 1) && (multiple(K_) == 1)
                VectorReq=1;
            end
        case {'magnitude','x component','y component','z component'}
            vectors=0;
        case 'angle'
            vectors=0;
            Units = 'radians';
            ask_for_angleconvention=1;
        case {'magnitude in plane','m component','n component','normal component','slice normal component','slice tangential component','edge normal component','edge tangential component'}
            vectors=0;
            VectorReq=1;
        case 'edge'
            Ops.presentationtype=Ops.vectorcomponent;
            vectors=0;
            nval=0.9;
        otherwise
            ui_message('error','Unexpected plot type encountered: %s\nin main module.',Ops.vectorcomponent)
            Ops = [];
            return
    end
end
if (nval==2 || nval==3) && ~vectors
    nval=1;
end
if isfield(Ops,'vectorcomponent') && strcmp(Ops.vectorcomponent,'vector')
    %if ~isequal(geometry,'TRI')
    %    geometry='sSEG';
    %    Props.Geom='sSEG';
    %end
    Props.ClosedPoly=0;
end
%--------------------------------------------------------------------------
%
%---- presentation type
%
extend2edge = 0;
if ((nval==1 || nval==6) && TimeSpatial==2) || nval==1.9 || strcmp(nvalstr,'strings') || strcmp(nvalstr,'boolean') || (strcmp(geometry,'POLYG') && nval~=2) % || (nval==0 & ~DimFlag(ST_))
    switch nvalstr
        case 1.9
            PrsTps={'vector','edge'};
        case 'strings'
            if multiple(T_)
                PrsTps={'tracks'}; % {'labels';'tracks'};
            else
                PrsTps={'labels';'markers'};
            end
        case 'boolean'
            PrsTps={'patches'};
        case 'none'
            switch geometry
                case {'POLYG'}
                    PrsTps={'polygons'};
                otherwise
                    PrsTps={'grid','grid with numbers'};
            end
        otherwise
            if nval==6
                dic=2;
            elseif isfield(Props,'DataInCell')
                dic=Props.DataInCell;
            else
                dic=0;
            end
            switch dic
                case 0
                    switch axestype
                        case {'X-Time','Time-X','Time-Z'}
                            PrsTps={'continuous shades';'markers';'values';'contour lines';'coloured contour lines';'contour patches';'contour patches with lines'};
                        otherwise
                            switch geometry
                                case {'TRI','TRI+'}
                                    if SpatialV
                                        PrsTps={'continuous shades';'markers';'values'};
                                    else
                                        PrsTps={'patches';'patches with lines';'continuous shades';'markers';'values';'contour lines';'coloured contour lines';'contour patches';'contour patches with lines'};
                                    end
                                case {'PNT','PNT+'}
                                    if strcmp(axestype,'Time-Z')
                                        PrsTps={'continuous shades';'markers';'values';'contour lines';'coloured contour lines';'contour patches';'contour patches with lines'};
                                    else
                                        PrsTps={'markers';'values'};
                                    end
                                case {'SEG','SEG-NODE'}
                                    PrsTps={'continuous shades';'markers';'values'};
                                case {'POLYL'}
                                    PrsTps={'polylines'};
                                case {'UGRID-EDGE'}
                                    PrsTps={'markers';'values';'edge'};
                                otherwise
                                    PrsTps={'continuous shades';'markers';'values';'contour lines';'coloured contour lines';'contour patches';'contour patches with lines'};
                            end
                    end
                case 1
                    switch axestype
                        case {'X-Time','Time-X','Time-Z'}
                            PrsTps={'continuous shades';'markers';'values';'contour lines';'coloured contour lines';'contour patches';'contour patches with lines'};
                        otherwise
                            switch geometry
                                case {'POLYG'}
                                    if DimFlag(M_) && DimFlag(N_)
                                        PrsTps={'polygons';'markers';'values';'continuous shades';'contour lines';'coloured contour lines';'contour patches';'contour patches with lines'};
                                    else
                                        PrsTps={'polygons';'markers';'values'};
                                    end
                                case {'SEG','SEG-EDGE'}
                                    PrsTps={'edge';'markers';'values'};
                                otherwise
                                    PrsTps={'patches';'patches with lines';'continuous shades';'markers';'values';'contour lines';'coloured contour lines';'contour patches';'contour patches with lines'};
                            end
                    end
                case 2
                    switch geometry
                        case {'POLYG'}
                            PrsTps={'polygons'};
                        otherwise
                            PrsTps={'patches';'patches with lines'};
                    end
            end
    end
    if length(PrsTps)==1
        p=1;
    else
        set(findobj(OH,'tag','presenttype'),'enable','on')
        pt=findobj(OH,'tag','presenttype=?');
        pPrsTps=get(pt,'string');
        if isequal(pPrsTps,PrsTps)
            set(pt,'enable','on','backgroundcolor',Active)
            p=get(pt,'value');
        else
            % try to find an exact match when switching presentation type strings
            p=get(pt,'value');
            if iscellstr(pPrsTps),
                p=pPrsTps{p};
            else
                p=pPrsTps(p,:);
            end
            p=strmatch(p,PrsTps,'exact');
            if isempty(p),
                p=1;
            end
            set(pt,'enable','on','value',1,'string',PrsTps,'value',p,'backgroundcolor',Active)
        end
    end
    Ops.presentationtype=lower(PrsTps{p});
    switch Ops.presentationtype
        case 'patches with lines'
            SingleColor=1;
        case 'continuous shades'
            extend2edge = 1;
        case 'values'
            MultipleColors=0;
            SingleColor=1;
            %
            ask_for_textprops=1;
            %
            ask_for_numformat=1;
            ask_for_thinningmode=1;
            if strcmp(geometry,'POLYG')
                geometry='PNT';
            end
        case {'contour lines','coloured contour lines','contour patches','contour patches with lines'}
            ask_for_thresholds = 1;
            switch Ops.presentationtype
                case 'contour lines'
                    MultipleColors=0;
                    SingleColor=1;
                    lineproperties=1;
                case 'coloured contour lines'
                    lineproperties=1;
                case 'contour patches with lines'
                    SingleColor=1;
                    lineproperties=1;
            end
            extend2edge = 1;
        case 'markers'
            usesmarker=1;
            forcemarker=1;
            lineproperties=0;
            switch nvalstr
                case {'strings'}
                    SingleColor=0;
                    forcemarkercolor=1;
                otherwise
                    markerflatfill=1;
                    %
                    ask_for_thinningmode=1;
            end
            if strcmp(geometry,'POLYG')
                geometry='PNT';
            end
        case 'patches'
            if strcmp(nvalstr,'boolean')
                SingleColor=1;
                MultipleColors=0;
            end
        case 'labels'
            ask_for_textprops=1;
            SingleColor=1;
        case 'polygons'
            lineproperties=1;
        case 'polylines'
            markerflatfill=nval>0;
            edgeflatcolour=nval>0;
            lineproperties=1;
        case 'grid with numbers'
            ask_for_textprops=1;
        case 'edge'
            thindams=1;
            lineproperties=1;
            nval=0.9;
        case 'vector'
            vectors=1';
            Ops.vectorcomponent='edge';
    end
end

%--------------------------------------------------------------------------

if vectors %&& ~isempty(strmatch(axestype,{'X-Y','X-Y-Z','X-Y-Val','X-Z'},'exact'))
    colvect=findobj(OH,'tag','colourvectors');
    set(colvect,'enable','on')
    if get(colvect,'value')
        switch Ops.vectorcomponent
            case {'vector (split x,y)','vector (split m,n)','edge'}
                Ops.vectorcolour='component';
            otherwise
                colvecm=findobj(OH,'tag','vectorcolour=?');
                pvecCLR=get(colvecm,'string');
                colveci=get(colvecm,'value');
                switch VectorReq
                    case 0
                        vecCLR={'magnitude','angle','x component','y component','z component','edge'};
                    otherwise
                        vecCLR={'magnitude in plane','m component','n component','normal component','edge'};
                end
                vecCLRi=ismember(vecCLR,compList);
                vecCLR(~vecCLRi)=[];
                if ~isequal(vecCLR,pvecCLR)
                    % try to find an exact match when switching vector colouring strings
                    if isempty(pvecCLR) || length(pvecCLR)<colveci
                        colveci=1;
                    else
                        colveci=strmatch(pvecCLR{colveci},vecCLR,'exact');
                        if isempty(colveci)
                            colveci=1;
                        end
                    end
                    set(colvecm,'value',1,'string',vecCLR,'value',colveci)
                end
                if length(vecCLR)>1
                    set(colvecm,'enable','on','backgroundcolor',Active)
                end
                Ops.vectorcolour=vecCLR{colveci};
        end
        if isfield(Ops,'vectorcolour') && strcmp(Ops.vectorcolour,'angle')
            Units = 'radians';
            ask_for_angleconvention=1;
        end
    else
        MultipleColors=0;
        SingleColor=1;
    end
    %
    if ~strcmp(Ops.vectorcomponent,'edge')
        ask_for_thinningmode=1;
    end
end

%--------------------------------------------------------------------------
%
%---- data units
%
if ~isempty(Units)
    set(findobj(OH,'tag','dataunits'),'enable','on')
    dunit=findobj(OH,'tag','dataunits=?');
    set(dunit,'enable','on', ...
        'backgroundcolor',Active)
    system=get(dunit,'value');
    systems=get(dunit,'string');
    if system==1
        % As in file
        qp_settings('UnitSystem',systems{system})
        user_units=Units;
        dunit=findobj(OH,'tag','dataunits=!');
        set(dunit,'backgroundcolor','r') % needed to get next line working properly R2011b
        set(dunit,'backgroundcolor',Inactive)
        set(dunit,'enable','inactive')
        set(dunit,'string',user_units)
    elseif system==length(systems)
        % Hide
        Units='**Hide**';
        Ops.units='**Hide**';
    elseif system==length(systems)-1
        % Other (user specified)
        dunit=findobj(OH,'tag','dataunits=!');
        set(dunit,'enable','on', ...
            'backgroundcolor',Active)
        user_units=get(dunit,'string');
        conversion=qp_unitconversion(Units,user_units);
        if ischar(conversion)
            user_units=Units;
        else
            Units=user_units;
        end
        set(dunit,'string',user_units)
        Ops.units=user_units;
    else
        % Specified format: SI, CGS, etc.
        qp_settings('UnitSystem',systems{system})
        user_units=systems{system};
        dunit=findobj(OH,'tag','dataunits=!');
        set(dunit,'enable','inactive', ...
            'backgroundcolor',Inactive)
        [conversion,SIunit]=qp_unitconversion(Units,user_units);
        set(dunit,'string',SIunit)
        Ops.units=SIunit;
    end
end

if ask_for_angleconvention
    pd=findobj(OH,'tag','angleconvention=?');
    conventions=get(pd,'string');
    i=get(pd,'value');
    Ops.angleconvention=conventions{i};
    %
    set(findobj(OH,'tag','angleconvention'),'enable','on');
    set(pd,'enable','on','backgroundcolor',Active)
end

if thindams
    if nval==0.9
        cl=1;
    else
        coldams=findobj(OH,'tag','colourdams');
        set(coldams,'enable','on')
        cl=get(coldams,'value');
    end
    if cl
        Ops.colourdams = 1;
        MultipleColors = 1;
        SingleColor    = 0;
        edgeflatcolour = 1;
    end
end

if nval>0 && nval<2
    oper=findobj(OH,'tag','operator');
    set(oper,'enable','on')
    oper=findobj(OH,'tag','operator=?');
    set(oper,'enable','on','backgroundcolor',Active)
    operstr = get(oper,'string');
    operi   = get(oper,'value');
    if operi>1
        Ops.operator = operstr{operi};
    end
end

if vectors && ~isempty(strmatch(axestype,{'X-Y','X-Y-Z','X-Y-Val','X-Z'},'exact'))
    set(findobj(OH,'tag','vectorstyle'),'enable','on')
    vstyle=findobj(OH,'tag','vectorstyle=?');
    set(vstyle,'enable','on','backgroundcolor',Active)
    vstyles=get(vstyle,'string');
    Ops.vectorstyle=vstyles{get(vstyle,'value')};
    %
    set(findobj(OH,'tag','vecscalem'),'enable','on')
    vsmode=findobj(OH,'tag','vecscalem=?');
    set(vsmode,'enable','on','backgroundcolor',Active)
    vsmodes=get(vsmode,'string');
    Ops.vectorscalingmode=vsmodes{get(vsmode,'value')};
    switch Ops.vectorscalingmode
        case {'automatic','automatic normalised'}
            Ops.vectorscale=1;
        case {'manual','manual normalised'}
            oneunitis=findobj(OH,'tag','1vecunit=?');
            set(findobj(OH,'tag','1vecunit'),'enable','on')
            set(oneunitis,'enable','on','backgroundcolor',Active)
            Ops.vectorscale=get(oneunitis,'userdata');
    end
end

if vectors && ~isempty(strmatch(axestype,{'X-Z' 'X-Y-Z'},'exact'))
    set(findobj(OH,'tag','vertscalem'),'enable','on')
    vsm=findobj(OH,'tag','vertscalem=?');
    set(vsm,'enable','on','backgroundcolor',Active)
    VsMeths=get(vsm,'string');
    vsm=get(vsm,'value');
    Ops.verticalscalingmode=lower(VsMeths{vsm});
    switch Ops.verticalscalingmode
        case 'manual'
            set(findobj(OH,'tag','vscale'),'enable','on')
            enl=findobj(OH,'tag','vscale=?');
            set(enl,'enable','on','backgroundcolor',Active)
            Ops.verticalscalefactor=get(enl,'userdata');
    end
end

if extend2edge
    h = findobj(OH,'tag','extend2edge');
    if TimeSpatial==2 && ~strcmp(axestype,'X-Time') && ~strcmp(axestype,'Time-X')
        set(h,'enable','on')
        extend2edge = get(h,'value');
    else
        %set(h,'enable','inactive','value',1)
        switch axestype
            case {'X-Time','Time-X','Time-Z'}
                extend2edge = 0;
            otherwise
                extend2edge = 1;
        end
    end
end
if extend2edge
    Ops.extend2edge = 1;
end

if ask_for_numformat
    set(findobj(OH,'tag','numformat'),'enable','on');
    numform=findobj(OH,'tag','numformat=?');
    Ops.numformat=get(numform,'string');
    set(numform,'enable','on','backgroundcolor',Active);
end

if ask_for_textprops
    set(findobj(OH,'tag','fontsize'),'enable','on');
    hFontsize=findobj(OH,'tag','fontsize=?');
    Ops.fontsize=get(hFontsize,'userdata');
    set(hFontsize,'enable','on','backgroundcolor',Active);
    
    set(findobj(OH,'tag','alignment'),'enable','on');
    set(findobj(OH,'tag','horizontalalignment'),'enable','on');
    set(findobj(OH,'tag','verticalalignment'),'enable','on');
    hHorAlign=findobj(OH,'tag','horizontalalignment=?');
    iHorAlign=get(hHorAlign,'value');
    strHorAlign=get(hHorAlign,'string');
    Ops.horizontalalignment=strHorAlign{iHorAlign};
    set(hHorAlign,'enable','on','backgroundcolor',Active);
    hVerAlign=findobj(OH,'tag','verticalalignment=?');
    iVerAlign=get(hVerAlign,'value');
    strVerAlign=get(hVerAlign,'string');
    Ops.verticalalignment=strVerAlign{iVerAlign};
    set(hVerAlign,'enable','on','backgroundcolor',Active);
end

if ask_for_thinningmode
    set(findobj(OH,'tag','thinfld'),'enable','on');
    thinfld=findobj(OH,'tag','thinfld=?');
    set(thinfld,'enable','on','backgroundcolor',Active)
    thinmodes = {'none','uniform','distance'}'; %,'regrid'
    if triangles
        thinmodes(2)=[];
    end
    prevthinmodes = get(thinfld,'string');
    thinmode = prevthinmodes{get(thinfld,'value')};
    if ~isequal(prevthinmodes,thinmodes)
        thinmode=thinmodes{1};
        set(thinfld,'string',thinmodes,'value',1)
    end
    Ops.thinningmode=thinmode;
    switch lower(Ops.thinningmode)
        case 'none'
        case 'uniform'
            set(findobj(OH,'tag','thinfact'),'enable','on');
            thinfact=findobj(OH,'tag','thinfact=?');
            set(thinfact,'enable','on','backgroundcolor',Active);
            Ops.thinningfactors=get(thinfact,'userdata')*[1 1 1];
        case {'distance','regrid'}
            set(findobj(OH,'tag','thindist'),'enable','on');
            thindist=findobj(OH,'tag','thindist=?');
            set(thindist,'enable','on','backgroundcolor',Active);
            Ops.thinningdistance=get(thindist,'userdata');
    end
end

if SingleColor
    set(findobj(OH,'tag','colour'),'enable','on')
    clrh=findobj(OH,'tag','colour=?');
    clr=get(clrh,'userdata');
    set(clrh,'enable','on','backgroundcolor',clr)
    Ops.colour=clr;
end

if isfield(Props,'ClosedPoly')
    if isequal(Props.ClosedPoly,1) && ~strcmp(geometry,'PNT')
        fpoly=findobj(OH,'tag','fillpolygons');
        set(fpoly,'enable','on')
        fillpoly=get(fpoly,'value');
    elseif isequal(Props.ClosedPoly,2)
        fillpoly=1;
    else
        fillpoly=0;
    end
    if fillpoly
        if MultipleColors
            Ops.facecolour='yes';
        else
            clrh=findobj(OH,'tag','facecolour=?');
            clr=get(clrh,'userdata');
            set(clrh,'enable','on','backgroundcolor',clr)
            Ops.facecolour=clr;
        end
    end
end

if ask_for_textprops
    if matlabversionnumber>=6.05
        hTextbox=findobj(OH,'tag','textbox=?');
        set(hTextbox,'enable','on');
        if get(hTextbox,'value')
            hTextboxcolour=findobj(OH,'tag','textboxfacecolour=?');
            Ops.textboxfacecolour=get(hTextboxcolour,'userdata');
            set(hTextboxcolour,'enable','on','backgroundcolor',Ops.textboxfacecolour);
        end
    end
end

if ismember(geometry,{'PNT'}) && ~multiple(T_) && nval>=0
    Ops.linestyle='none';
    Ops.linewidth=0.5;
    if ~isfield(Ops,'presentationtype') || ~strcmp(Ops.presentationtype,'values')
        usesmarker = 1;
        forcemarker = 1;
    end
elseif lineproperties || nval==0
    set(findobj(OH,'tag','linestyle'),'enable','on')
    lns=findobj(OH,'tag','linestyle=?');
    set(lns,'enable','on','backgroundcolor',Active)
    lnstls=get(lns,'string');
    Ops.linestyle=lnstls{get(lns,'value')};
    
    set(findobj(OH,'tag','linewidth'),'enable','on')
    lnw=findobj(OH,'tag','linewidth=?');
    set(lnw,'enable','on','backgroundcolor',Active)
    Ops.linewidth=get(lnw,'userdata');
    usesmarker=1;
elseif vectors
    set(findobj(OH,'tag','linewidth'),'enable','on')
    lnw=findobj(OH,'tag','linewidth=?');
    set(lnw,'enable','on','backgroundcolor',Active)
    Ops.linewidth=get(lnw,'userdata');
end
if usesmarker
    set(findobj(OH,'tag','marker'),'enable','on')
    mrk=findobj(OH,'tag','marker=?');
    set(mrk,'enable','on','backgroundcolor',Active)
    mrkrs=get(mrk,'string');
    imrk=get(mrk,'value');
    if forcemarker && ismember('none',mrkrs)
        inone=strmatch('none',mrkrs);
        if imrk==inone
            set(mrk,'value',1)
        end
        mrkrs(inone)=[];
        set(mrk,'string',mrkrs)
    elseif ~forcemarker && ~ismember('none',mrkrs)
        mrkrs{end+1}='none';
        imrk=length(mrkrs); % select no by marker by default
        set(mrk,'string',mrkrs,'value',imrk);
    end
    if imrk>length(mrkrs)
        imrk=1;
        set(mrk,'value',imrk);
    end
    Ops.marker=mrkrs{get(mrk,'value')};
    %
    Ops.markersize=6;
    if ~strcmp(Ops.marker,'none') && ~strcmp(Ops.marker,'.')
        set(findobj(OH,'tag','markersize'),'enable','on')
        mrk=findobj(OH,'tag','markersize=?');
        set(mrk,'enable','on','backgroundcolor',Active)
        Ops.markersize=get(mrk,'userdata');
    end
    %
    Ops.markercolour='auto';
    if markerflatfill
        Ops.markerfillcolour='flat';
    else
        Ops.markerfillcolour='none';
    end
    if strcmp(Ops.marker,'none')
        %MultipleColors=0 | edgeflatcolour;
    else
        mc=findobj(OH,'tag','usemarkercolour');
        set(mc,'enable','on')
        if  forcemarkercolor
            set(mc,'style','text')
        else
            set(mc,'style','checkbox')
        end
        if get(mc,'value') || forcemarkercolor
            mc=findobj(OH,'tag','markercolour=?');
            clr=get(mc,'userdata');
            set(mc,'enable','on','backgroundcolor',clr)
            Ops.markercolour=clr;
        end
        if isempty(strmatch(Ops.marker,{'.','*','+','x'},'exact'))
            mc=findobj(OH,'tag','usemarkerfillcolour');
            set(mc,'enable','on')
            if get(mc,'value')
                mc=findobj(OH,'tag','markerfillcolour=?');
                clr=get(mc,'userdata');
                set(mc,'enable','on','backgroundcolor',clr)
                Ops.markerfillcolour=clr;
            end
            if ~strcmp(Ops.markerfillcolour,'flat') && ~strcmp(Ops.markercolour,'auto')
                MultipleColors=0 | edgeflatcolour;
            end
        else
            Ops.markerfillcolour=[0 0 0];
            if ~strcmp(Ops.markercolour,'auto')
                MultipleColors=0 | edgeflatcolour;
            end
        end
    end
end

if isfield(Ops,'presentationtype')
    switch Ops.presentationtype
        case {'vector','patches','patches with lines','markers'}
            if MultipleColors && Props.NVal~=6
                cclass=findobj(OH,'tag','colclassify');
                set(cclass,'enable','on')
                if get(cclass,'value')
                    ask_for_thresholds = 1;
                end
            end
    end
end

if ask_for_thresholds
    set(findobj(OH,'tag','thresholds'),'enable','on')
    set(findobj(OH,'tag','thresholds=?'),'enable','on','backgroundcolor',Active)
    Ops.thresholds=get(findobj(OH,'tag','thresholds=?'),'userdata');
    %
    % if the thresholds have not explicitly been specified
    % (only the number of thresholds is given, or even that is left to default)
    % then ask for distribution of thresholds
    %
    if isempty(Ops.thresholds) || ...
            (isequal(size(Ops.thresholds),[1 1]) && isnumeric(Ops.thresholds) && isequal(Ops.thresholds,round(Ops.thresholds)) && Ops.thresholds>0)
        thrd=findobj(OH,'tag','threshdistr=?');
        set(thrd,'enable','on','backgroundcolor',Active)
        thrdStr=get(thrd,'string'); % linear, logarithmic, anti-logarithmic
        Ops.thresholddistribution=thrdStr{get(thrd,'value')};
    end
end

if MultipleColors
    if Props.NVal~=6
        set(findobj(OH,'tag','climmode'),'enable','on')
        climmode=findobj(OH,'tag','climmode=?');
        set(climmode,'enable','on','backgroundcolor',Active)
        clmodes=get(climmode,'string');
        CLimMode=clmodes{get(climmode,'value')};
        switch CLimMode
            case 'automatic'
                Ops.colourlimits=[];
                Ops.symmetriccolourlimits=0;
                if ~isfield(Ops,'thresholddistribution') || strcmp(Ops.thresholddistribution,'linear')
                    climsymm=findobj(OH,'tag','climsymm');
                    set(climsymm,'enable','on')
                    Ops.symmetriccolourlimits=get(climsymm,'value');
                end
            case 'manual'
                set(findobj(OH,'tag','climmax'),'enable','on')
                set(findobj(OH,'tag','climmax=?'),'enable','on','backgroundcolor',Active)
                set(findobj(OH,'tag','climmin'),'enable','on')
                set(findobj(OH,'tag','climmin=?'),'enable','on','backgroundcolor',Active)
                Min=get(findobj(OH,'tag','climmin=?'),'userdata');
                Max=get(findobj(OH,'tag','climmax=?'),'userdata');
                if Min>Max
                    set(findobj(OH,'tag','climmin=?'),'userdata',Max,'string',sprintf('%g',Max));
                    set(findobj(OH,'tag','climmax=?'),'userdata',Min,'string',sprintf('%g',Min));
                    Ops.colourlimits=[Max Min];
                elseif Min==Max
                    if Min==0
                        Max=1;
                    elseif Min<0
                        Max=Min*(1-1e-6);
                    else
                        Max=Max*(1+1e-6);
                    end
                    set(findobj(OH,'tag','climmax=?'),'userdata',Max,'string',sprintf('%g',Max));
                    Ops.colourlimits=[Min Max];
                else
                    Ops.colourlimits=[Min Max];
                end
        end
    end
    set(findobj(OH,'tag','colourmap'),'enable','on')
    set(findobj(OH,'tag','colourmapbutton'),'enable','on')
    cmap=findobj(OH,'tag','colourmap=?');
    set(cmap,'enable','on','backgroundcolor',Active)
    cmaps=get(cmap,'string');
    Ops.colourmap=cmaps{get(cmap,'value')};
    cbar=findobj(OH,'tag','colourbar');
    set(cbar,'enable','on')
    if get(cbar,'value')
        cbarh=findobj(OH,'tag','colbarhorz');
        set(cbarh,'enable','on')
        if get(cbarh,'value')
            Ops.colourbar='horiz';
        else
            Ops.colourbar='vert';
        end
    else
        Ops.colourbar='none';
    end
end

%
%---- axes type
%

if ~isempty(strfind(axestype,'Val'))
    if ~isempty(strfind(Props.Name,'level'))
        % only convert to elevation if unit is equivalent to m or
        % dimensionless
        if ~ischar(qp_unitconversion(Units,'m')) || ...
                ~ischar(qp_unitconversion(Units,''))
            axestype=strrep(axestype,'Val','Z');
        end
    end
end
Ops.axestype=axestype;

%
%---- clipping values
%

if (nval==1 || isfield(Ops,'vectorcolour') || isfield(Ops,'colourdams')) && (lineproperties || TimeSpatial==2)
    set(findobj(OH,'tag','clippingvals'),'enable','on')
    set(findobj(OH,'tag','clippingvals=?'),'enable','on','backgroundcolor',Active)
    Ops.clippingvalues=get(findobj(OH,'tag','clippingvals=?'),'userdata');
end

if (SpatialH==2)
    set(findobj(OH,'tag','clippingvals'),'enable','on')
    set(findobj(OH,'tag','xclipping'),'enable','on')
    set(findobj(OH,'tag','xclipping=?'),'enable','on','backgroundcolor',Active)
    Ops.xclipping=get(findobj(OH,'tag','xclipping=?'),'userdata');
    set(findobj(OH,'tag','yclipping'),'enable','on')
    set(findobj(OH,'tag','yclipping=?'),'enable','on','backgroundcolor',Active)
    Ops.yclipping=get(findobj(OH,'tag','yclipping=?'),'userdata');
end

%---- Export option

ExpTypes={};
if nval>=0
    if (~multiple(M_) && ~multiple(N_)) && nval>0
        ExpTypes{end+1}='csv file (time series)';
        ExpTypes{end+1}='Tekal file (time series)';
    end
    if (multiple(M_) && multiple(N_)) && ~multiple(K_) && ~multiple(T_)
        ExpTypes{end+1}='grid file';
        ExpTypes{end+1}='grid file (old format)';
    end
    if sum(multiple)==1 && sum(multiple([M_ N_]))==1 && nval==0
        ExpTypes{end+1}='spline';
    end
    if (multiple(M_) && multiple(N_)) && ~multiple(K_) && ~multiple(T_)
        if nval>0
            ExpTypes{end+1}='QuickIn file';
        end
        if nval==1
            ExpTypes{end+1}='-QuickIn file';
        end
        if nval==1
            ExpTypes{end+1}='Delft3D-MOR field file';
            ExpTypes{end+1}='-Delft3D-MOR field file';
        end
        if nval==1
            ExpTypes{end+1}='SIMONA box file';
            ExpTypes{end+1}='-SIMONA box file';
        end
    end
    if (multiple(M_) && (multiple(N_) || triangles || strncmp(geometry,'UGRID',5) || strcmp(geometry,'sSEG'))) && ~multiple(K_) && ~multiple(T_)
        if ~isfield(Ops,'presentationtype') || ~isequal(Ops.presentationtype,'continuous shades')
            ExpTypes{end+1}='ARCview shape';
        end
    elseif strcmp(geometry,'POLYL') || strcmp(geometry,'POLYG')
        ExpTypes{end+1}='ARCview shape';
        ExpTypes{end+1}='landboundary file';
    end
    maxt = 100; % TODO maxt=get(findobj(mfig,'tag','max_t'),'userdata');
    if ((length(selected{T_})<11 && ~isequal(selected{T_},0)) || (maxt<11 && isequal(selected{T_},0))) && nval>0 && (multiple(M_) || multiple(N_) || multiple(K_))
        ExpTypes{end+1}='Tekal file';
        ExpTypes{end+1}='Tecplot file';
    end
    if (multiple(M_) || multiple(N_) || multiple(K_)) && ~multiple(T_) && nval>0
        ExpTypes{end+1}='sample file';
    end
    %
    Mver = matlabversionnumber;
    ExpTypes{end+1}='mat file (v6)';
    if Mver>=7
        ExpTypes{end+1}='mat file (v7)';
        if Mver>=7.03
            ExpTypes{end+1}='mat file (v7.3/hdf5)';
        end
    end
end
if ~isempty(ExpTypes)
    set(findobj(OH,'tag','exporttype'),'enable','on');
    expt=findobj(OH,'tag','exporttype=?');
    pExpTypes=get(expt,'string');
    pet=get(expt,'value');
    petStr=pExpTypes{pet};
    et=strmatch(petStr,ExpTypes,'exact');
    if isempty(et)
        et=1;
    end
    set(expt,'enable','on','value',1,'string',ExpTypes,'value',et,'backgroundcolor',Active);
    %
    switch ExpTypes{et}
        case {'QuickIn file','-QuickIn file'}
            set(findobj(OH,'tag','expformat'),'enable','on');
            expf=findobj(OH,'tag','expformat=?');
            set(expf,'enable','on');
            Ops.expformat=get(expf,'string');
    end
    %
    ed=findobj(OH,'tag','exportdata');
    set(ed,'enable','on');
    setappdata(ed,'exporttype',ExpTypes{et})
end
%
%-------- END OF PLOT OPTIONS -------------
if animate
    PlotType='Animate';
end
EnablePlot = ~strcmp(axestype,'noplot');
EnableLoad = nval~=-1;

%---- Ops Version

Ops.version=1.4;
UD.State=Ops;

%---- Show/hide options

update_option_positions(UD,'main')


function str = onoff(bool)
if bool
    str = 'on';
else
    str = 'off';
end