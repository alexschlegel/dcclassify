function x = LoadData(strDataType,varargin)
% twt.LoadData
% 
% Description:	load previously stored data
% 
% Syntax:	x = twt.LoadData(strDataType,[name]=1,<options>)
% 
% In:
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

x	= MATLoad(strPathData,'data');
