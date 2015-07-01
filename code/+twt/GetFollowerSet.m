function follower = GetFollowerSet(tw,kCandidate,varargin)
% twt.GetFollowerSet
% 
% Description:	get the follower set for the specified candidate set
% 
% Syntax:	follower = twt.GetFollowerSet(tw,kCandidate,<options>)
%
% In:
%	tw			- the twitty object
%	kCandidate	- an array of candidate indices
%	<options>:
%		allbut:	(1) the allbut option for intersectmulti
% 
% Updated: 2015-06-30
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
			'allbut'	, 1	  ...
			);
	
	strKey	= join(append(kCandidate,opt.allbut),',');
	strHash	= str2hash(strKey);

%do we need to get the data?
	if twt.DataExist('followerset',strHash)
		follower	= twt.LoadData('followerset',strHash);
		return;
	end

%get the follower ids
	id = arrayfun(@(k) twt.GetCandidateFollowers(tw,k),kCandidate,'uni',false);
%get the intersection set
	id	= intersectmulti(id,'allbut',opt.allbut);
%get info for each user
	follower	= twt.GetUserInfo(tw,id);

%save it
	twt.SaveData(follower,'followerset',strHash);
