function strPathData = GetPathData(strDataType)
% twt.GetPathData
% 
% Description:	get the path to a data file
% 
% Syntax:	strPathData = twt.GetPathData(strDataType)
%
% Updated: 2015-06-30
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData;

strDirTwitter	= DirAppend(strDirData,'twitter');
strPathData		= PathUnsplit(strDirTwitter,sprintf('data-%s',strDataType),'mat');
