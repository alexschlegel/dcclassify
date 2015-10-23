function SaveData(x,strDataType,varargin)
% twt.SaveData
% 
% Description:	save data to disk
% 
% Syntax:	x = twt.SaveData(x,strDataType,[name]=1,<options>)
% 
% In:
%	x			- the data to save
%	strDataType	- the type of data
%	[name]		- the data name
% 
% Updated: 2015-10-12
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
[name,opt]	= ParseArgs(varargin,1,...
				'analysis'	, 'twitter'	  ...
				);

strPathData	= twt.GetPathData(strDataType,name,'analysis',opt.analysis);

MATSave(strPathData,'data',x);
