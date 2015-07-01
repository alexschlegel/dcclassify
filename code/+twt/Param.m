function param = Param(varargin)
% twt.Param
% 
% Description:	return a struct of parameters
% 
% Syntax:	param = twt.Param(<options>)
%
% In:
% 	declared:				(<see twt.LoadCandidates)
%	exclude_by_last_name:	(<see twt.LoadCandidates)
% 
% Updated: 2015-06-30
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
param			= struct;
param.candidate	= twt.LoadCandidates(varargin{:});
