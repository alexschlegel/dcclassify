function SaveData(x,strDataType,varargin)
% twt.SaveData
% 
% Description:	save data to disk
% 
% Syntax:	x = twt.SaveData(x,strDataType,[k]=1)
% 
% In:
%	x			- the data to save
%	strDataType	- the type of data
%	[k]			- the index of the data
% 
% Updated: 2015-06-30
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
k	= ParseArgs(varargin,1);

strPathData	= twt.GetPathData(strDataType);

MATSave(strPathData,sprintf('data%d',k),x);
