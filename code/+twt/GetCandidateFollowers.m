function id = GetCandidateFollowers(tw,kCandidate,varargin)
% twt.GetCandidateFollowers
% 
% Description:	get the ids of all followers of the specified candidate
% 
% Syntax:	id = twt.GetCandidateFollowers(tw,kCandidate,<options>)
%
% In:
%	tw			- the twitty object
%	kCandidate	- the candidate index
%	<options>:
%		force:	(false) true to force data retrieval if stored data already
%				exist
% 
% Updated: 2015-06-25
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
			'force'	, false	  ...
			);

%do we need to get the data?
	if ~opt.force && twt.DataExist('followers',kCandidate)
		id	= twt.LoadData('followers',kCandidate);
		return;
	end

%get the data
	param	= twt.Param;
	users	= param.candidate.user{kCandidate};
	
	id	= cellfun(@(u) twt.GetUserFollowers(tw,u),users,'uni',false);
	id	= unique(cat(1,id{:}));

%save it
	twt.SaveData(id,'followers',kCandidate);
