function param = Param(varargin)
% twt.Param
% 
% Description:	return a struct of parameters
% 
% Syntax:	param = twt.Param(<options>)
%
% In:
%	<options>:
%		declared:				(<see twt.LoadCandidates>)
%		exclude_by_last_name:	(<see twt.LoadCandidates>)
%		analysis:				(<see twt.LoadCandidates>)
% 
% Updated: 2015-10-12
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
opt	= ParseArgs(varargin,...
		'analysis'	, 'twitter'	  ...
		);


param			= struct;
param.candidate	= twt.LoadCandidates(varargin{:});

%cutoff times
	switch opt.analysis
		case 'twitter'
			%these weren't actually used in the first analysis, but the tweets
			%were retrieved on 7/3
			param.tweet.earliest	= 0;
			param.tweet.latest		= FormatTime('2015-07-04');
		case 'twitter2'
			param.tweet.earliest	= FormatTime('2015-07-04');	%first analysis ended on 7/3
			param.tweet.latest		= FormatTime('2015-10-12'); %today
		otherwise
			error('invalid analysis');
	end
