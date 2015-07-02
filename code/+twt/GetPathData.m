function strPathData = GetPathData(strDataType,name)
% twt.GetPathData
% 
% Description:	get the path to a data file
% 
% Syntax:	strPathData = twt.GetPathData(strDataType,name)
%
% Updated: 2015-06-30
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData;

strDirOut	= DirAppend(strDirData,'twitter',strDataType);

if ~isdir(strDirOut)
	mkdir(strDirOut);
end

strPathData		= PathUnsplit(strDirOut,tostring(name),'mat');
