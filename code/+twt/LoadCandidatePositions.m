function [s,cName] = LoadCandidatePositions()
% twt.LoadCandidatePositions
% 
% Description:	load the candidate position information
% 
% Syntax:	[s,cName] = twt.LoadCandidatePositions()
%
% Updated: 2015-07-09
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData

strDirTwitter	= DirAppend(strDirData,'twitter');
strPathData		= PathUnsplit(strDirTwitter,'positions','xls');

[n,str,raw]	= xlsread(strPathData);

cName		= raw(1,2:end)';
nCandidate	= numel(cName);

cField	= lower(raw(2:end,1));
nField	= numel(cField);

c	= mat2cell(n',nCandidate,ones(nField,1));
s	= cell2struct(c',cField);
