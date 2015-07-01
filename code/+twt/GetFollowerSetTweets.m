function tweet = GetFollowerSetTweets(tw,kCandidate,varargin)
% twt.Get
% 
% Description:	get all available tweets by the follower set users
% 
% Syntax:	tweet = twt.GetFollowerSetTweets(tw,kCandidate,<options>)
%
% In:
%	tw			- the twitty object
%	kCandidate	- an array of candidate indices
%	<options>:
%		allbut:	(1) the allbut option for intersectmulti
% 
% Updated: 2015-07-01
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
	if twt.DataExist('followersettweets',strHash)
		tweet	= twt.LoadData('followersettweets',strHash);
		return;
	end

%get the data
	follower	= twt.GetFollowerSet(tw,kCandidate,'allbut',opt.allbut);
	
	strCache	= sprintf('%s_cache',strHash);
	
	tweet	= cellfunprogress(@(id) twt.GetUserTweets(tw,id,'cache',strCache),follower.id,...
				'label'	, 'retrieving follower set tweets'	, ...
				'uni'	, false								  ...
				);

%save it
	twt.SaveData(tweet,'followers',strHash);
