function strPathData = GetPathData(strDataType,name,varargin)
% twt.GetPathData
% 
% Description:	get the path to a data file
% 
% Syntax:	strPathData = twt.GetPathData(strDataType,name,<options>)
%
% Updated: 2015-10-12
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData;

opt	= ParseArgs(varargin,...
		'analysis'	, 'twitter'	  ...
		);


strDirOut	= DirAppend(strDirData,opt.analysis,strDataType);

if ~isdir(strDirOut)
	mkdir(strDirOut);
end

strPathData		= PathUnsplit(strDirOut,tostring(name),'mat');
