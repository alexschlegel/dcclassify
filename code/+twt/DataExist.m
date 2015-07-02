function b = DataExist(strDataType,varargin)
% twt.DataExist
% 
% Description:	determine whether a piece of data has already been
%				retrieved
% 
% Syntax:	b = twt.DataExist(strDataType,[name]=1)
%
% In:
%	strDataType	- the type of data
%	[name]		- the data name
% 
% Updated: 2015-07-02
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
name	= ParseArgs(varargin,1);

strPathData	= twt.GetPathData(strDataType,name);

b	= FileExists(strPathData);
