function [x,cName] = LoadPolls(varargin)
% twt.LoadPolls
% 
% Description:	load the poll information
% 
% Syntax:	[x,cName] = twt.LoadPolls(<options>)
%
% Updated: 2015-10-12
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData

opt	= ParseArgs(varargin,...
		'analysis'	, 'twitter'	  ...
		);

strDirTwitter	= DirAppend(strDirData,opt.analysis);
strPathData		= PathUnsplit(strDirTwitter,'polls','xls');

[x,str,raw]	= xlsread(strPathData);

cName		= raw(1,2:end)';
nCandidate	= numel(cName);

x	= x';