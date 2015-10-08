function [x,cName] = LoadPolls()
% twt.LoadPolls
% 
% Description:	load the poll information
% 
% Syntax:	[x,cName] = twt.LoadPolls()
%
% Updated: 2015-07-17
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData

strDirTwitter	= DirAppend(strDirData,'twitter');
strPathData		= PathUnsplit(strDirTwitter,'polls','xls');

[x,str,raw]	= xlsread(strPathData);

cName		= raw(1,2:end)';
nCandidate	= numel(cName);

x	= x';