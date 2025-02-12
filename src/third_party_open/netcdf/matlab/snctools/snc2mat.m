function snc2mat ( ncfile, matfile ) %#ok<INUSD>
%SNC2MAT  Save netcdf file to *.mat format
%   This function is not recommended and is no longer supported.
%
%   SNC2MAT(NCFILE,MATFILE) will save the netCDF file NCFILE to the 
%   mat-file MATFILE.  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% $Id: snc2mat.m 449 2011-04-11 08:10:53Z jagers $
% $LastChangedDate: 2011-04-11 02:10:53 -0600 (Mon, 11 Apr 2011) $
% $LastChangedRevision: 449 $
% $LastChangedBy: jagers $
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning ( 'SNCTOOLS:snc2mat:deprecated', ...
    'This function is deprecated and may be removed in a future version of SNCTOOLS.' );




%
% create the MATLAB file
ncdata = nc_getall ( ncfile );

fnames = fieldnames ( ncdata );
save_command = '';
global_atts = [];
for j = 1:length(fnames)
	theVar = fnames{j};
	if ( strcmp(theVar,'global_atts' ) )
		global_atts = ncdata.global_atts;
	else
		command = sprintf ( '%s = ncdata.%s;', theVar, theVar );
		eval(command);
		save_command = sprintf ( '%s''%s'',', save_command, theVar );
	end
end
if ~isempty(global_atts)
	save_command = sprintf ( '%s''global_atts''', save_command );
else
	%
	% This chops off a bad comma that's not needed if no global attributes.
	save_command(end) = '';
end
save_command = sprintf ( 'save ( matfile, %s );', save_command );
try
	eval(save_command);
catch %#ok<CTCH>
	error ( 'SNCTOOLS:snc2mat:badCommand', ...
        'Could not execute save command ''%s''', save_command);
end


	

return
