function setaxesprops(hAx,FullAxesType,dimension,unit)
%SETAXESPROPS Set appropriate axes properties.

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
%   $HeadURL: https://svn.oss.deltares.nl/repos/delft3d/branches/research/Deltares/20160119_tidal_turbines/src/tools_lgpl/matlab/quickplot/progsrc/private/setaxesprops.m $
%   $Id: setaxesprops.m 5590 2015-11-16 10:05:03Z jagers $

if nargin==1
    update_axesprops(hAx)
    return
end

if ~ishandle(hAx) || isempty(FullAxesType)
    return
end
%
AxesType=full2basic_axestype(FullAxesType);
%
currentFullAxesType = getappdata(hAx,'AxesType');
%currentAxesType     = getappdata(hAx,'BasicAxesType');
if  ischar(currentFullAxesType) && ~isequal(currentFullAxesType,FullAxesType)
    warning('AxesType mismatch: %s (set) vs. %s (new).',currentFullAxesType,FullAxesType)
    FullAxesType = currentFullAxesType;
    AxesType     = full2basic_axestype(FullAxesType);
end
%
Axes  = splitcellstr(AxesType,'-');
nAxes = length(Axes);
%
if nargin<3
    dimension = {};
end
if nargin<4
    unit = {};
end
%
if strcmp(AxesType,'legend')
    legendbox('init',hAx)
elseif strcmp(AxesType,'Text')
    set(hAx,'visible','off', ...
        'xlim',[0 1], ...
        'ylim',[0 1])
else
    X = 'xyz';
    if nAxes==2
        setappdata(hAx,'axes2d',true)
        set_2d_axes_behavior(hAx)
    end
    if nAxes>=2
        if isequal(Axes(1:2),{'Lon','Lat'})
            setappdata(hAx,'LonLat',1)
            sethscale_lonlat(hAx)
        elseif isequal(Axes(1:2),{'X','Y'})
            sethscale(hAx,1)
        end
    end
    if length(dimension)<nAxes
        dimension{nAxes}=[];
    end
    if length(unit)<nAxes
        unit{nAxes} = [];
    end
    for i = 1:nAxes
        if isempty(getappdata(hAx,[X(i) 'limmode']))
            setappdata(hAx,[X(i) 'limmode'],'auto')
        end
        switch Axes{i}
            case 'Time'
                % Time axis
                if isempty(getappdata(hAx,[X(i) 'tickmode']))
                    setappdata(hAx,[X(i) 'tickmode'],'autodate')
                end
                setlabel(hAx,X(i),'time',unit{i})
            case 'Lon'
                % Longitude axis
                if isempty(getappdata(hAx,[X(i) 'tickmode']))
                    setappdata(hAx,[X(i) 'tickmode'],'longitude')
                end
                setlabel(hAx,X(i),'longitude','deg')
            case 'Lat'
                % Latitude axis
                if isempty(getappdata(hAx,[X(i) 'tickmode']))
                    setappdata(hAx,[X(i) 'tickmode'],'latitude')
                end
                setlabel(hAx,X(i),'latitude','deg')
            case 'Z'
                % Elevation axis
                if isempty(getappdata(hAx,[X(i) 'tickmode']))
                    setappdata(hAx,[X(i) 'tickmode'],'auto')
                end
                setlabel(hAx,X(i),dimension{i},unit{i})
            case {'X','Y'}
                % Horizontal coordinate axis
                if isempty(getappdata(hAx,[X(i) 'tickmode']))
                    setappdata(hAx,[X(i) 'tickmode'],'auto')
                end
                if isempty(dimension{i})
                    dimension{i} = sprintf('%s coordinate',lower(Axes{i}));
                end
                setlabel(hAx,X(i),dimension{i},unit{i})
            case {'Distance'}
                % Distance axis
                if isempty(getappdata(hAx,[X(i) 'tickmode']))
                    setappdata(hAx,[X(i) 'tickmode'],'auto')
                end
                if isempty(dimension{i})
                    dimension{i} = 'distance';
                end
                setlabel(hAx,X(i),dimension{i},unit{i})
            otherwise
                % Variable axis
                if isempty(getappdata(hAx,[X(i) 'tickmode']))
                    setappdata(hAx,[X(i) 'tickmode'],'auto')
                end
                setlabel(hAx,X(i),dimension{i},unit{i})
        end
    end
end
%
if ~isequal(FullAxesType,AxesType)
    setappdata(hAx,'AxesType',FullAxesType)
end
setappdata(hAx,'BasicAxesType',AxesType)
update_axesprops(hAx)


function sethscale_lonlat(hAx)
ylimv=get(hAx,'ylim');
if ylimv(1)<-90
    ylimv(1)=-90;
    if ylimv(2)<=ylimv(1)
        ylimv(2)=-89;
    end
end
if ylimv(2)>90
    ylimv(2)=90;
    if ylimv(1)>=ylimv(2)
        ylimv(1)=89;
    end
end
lat=mean(ylimv);
lat=min(max(lat,-89),89);
sethscale(hAx,cos(lat*pi/180))
xlim=get(hAx,'xlim'); % force both xlimmode and ylimmode to manual
set(hAx,'ylim',ylimv,'xlim',xlim)


function sethscale(hAx,ratio)
if strcmp(get(hAx,'dataaspectratiomode'),'auto')
    set(hAx,'dataaspectratio',[1 ratio 1/30])
else
    da = get(hAx,'dataaspectratio');
    da(2) = da(1)*ratio;
    set(hAx,'dataaspectratio',da)
end


function axestype = full2basic_axestype(axestype)
unitsloc=strfind(axestype,' [');
for i=length(unitsloc):-1:1
    unitsclose=strfind(axestype(unitsloc(i):end),']');
    if ~isempty(unitsclose)
        axestype(:,unitsloc(i)+(0:max(unitsclose)-1))=[];
    end
end


function update_axesprops(hAx)
for d = 'xyz'
    update_axticks(hAx,d)
end
if isequal(getappdata(hAx,'LonLat'),1)
    sethscale_lonlat(hAx)
end
% axes2d = isequal(getappdata(hAx,'axes2d'),true);
% if axes2d
%     alldims = 'xy';
% else
%     alldims = 'xyz';
% end
% for d = alldims
%     dlimmode = getappdata(hAx,[d 'limmode']);
%     if isempty(dlimmode) || strcmp(dlimmode,'auto')
%         set(hAx,[d 'limmode'],'auto')
%     end
% end
% for d = alldims
%     update_axticks(hAx,d)
% end
% if isequal(getappdata(hAx,'LonLat'),1)
%     sethscale_lonlat(hAx)
% end
% if axes2d
%     set_2d_axes_behavior(hAx)
% end


function setlabel(ax,dir,quantity,unit)
if ~ischar(quantity)
    quantity = '';
end
if ~ischar(unit)
    unit = '';
end
setappdata(ax,[dir 'quantity'],quantity)
setappdata(ax,[dir 'unit'],unit)
update_label(ax,dir)
%
update_axticks(ax,dir)


function update_label(ax,dir)
quantity = getappdata(ax,[dir 'quantity']);
unit     = getappdata(ax,[dir 'unit']);
arrow    = '\rightarrow';
if ~isempty(unit)
    dimstr = sprintf('%s (%s) %s',quantity,unit,arrow);
else
    dimstr = sprintf('%s %s',quantity,arrow);
end
%
setappdata(ax,[dir 'labelauto'],dimstr)
if isappdata(ax,[dir 'label'])
    dimstr = getappdata(ax,[dir 'label']);
    dimstr = qp_strrep(dimstr,'%quantity%',quantity);
    dimstr = qp_strrep(dimstr,'%unit%',unit);
end
if ~isempty(strfind(dimstr,'\n{}'))
    dimstr = strsplit(dimstr,'\\n{}');
end
%
axlabel = get(ax,[dir 'label']);
set(axlabel,'string',dimstr)


function update_axticks(hAx,dir)
quantity = getappdata(hAx,[dir 'quantity']);
unit = getappdata(hAx,[dir 'unit']);
units = {'mm' 'm' 'km'};
if ~isempty(quantity)
    switch quantity
        case {'longitude','latitude'}
            tick(hAx,dir,'autoticks',quantity);
        case {'time'}
            tick(hAx,dir,'autoticks','autodate');
        case {'distance','x coordinate','y coordinate'}
            if ismember(unit,units)
                distanceticks(hAx,dir)
            end
        otherwise
            if strncmp(quantity,'distance along',14) && ...
                    ismember(unit,units)
                distanceticks(hAx,dir)
            end
    end
end

function distanceticks(ax,dir)
unitQ=[0.001  1  1000];
unitT=[0      1  10000];
unitS={'mm'  'm' 'km'};
%
dx=max(abs(get(ax,[dir 'lim'])));
scale=sum(dx>unitT);
unit =unitS{scale};
%
set(ax,[dir 'ticklabelmode'],'auto',[dir 'tickmode'],'auto');
tick(ax,dir,'%g',1/unitQ(scale))
%
if ~isequal(unit,getappdata(ax,[dir 'unit']))
    setappdata(ax,[dir 'unit'],unit)
    update_label(ax,dir)
end

function set_2d_axes_behavior(ax)
try
    set(ax, 'View',[0 90])
    for i = 1:length(ax)
        bh = hggetbehavior(ax(i),'rotate3d');
        set(bh,'Enable',false)
    end
catch
end
