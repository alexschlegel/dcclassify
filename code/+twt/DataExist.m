function b = DataExist(strDataType,varargin)
% twt.DataExist
% 
% Description:	determine whether a piece of data has already been
%				retrieved
% 
% Syntax:	b = twt.DataExist(strDataType,[k]=1)
%
% In:
%	strDataType	- the type of data
%	[k]			- the index of the data
% 
% Updated: 2015-06-30
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
k	= ParseArgs(varargin,1);

strPathData	= twt.GetPathData(strDataType);

b	= MATVarExists(strPathData,sprintf('data%d',k));
