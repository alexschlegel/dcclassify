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
%		earliest:	([]) the timestamp of the earliest tweet to retrieve
%		latest:		([]) the timestamp of the latest tweet to retrieve
%		allbut:		(1) the allbut option for intersectmulti
%		analysis:	('twitter') the analysis name
% 
% Updated: 2015-10-12
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
			'earliest'	, []		, ...
			'latest'	, []		, ...
			'allbut'	, 1			, ...
			'analysis'	, 'twitter'	  ...
			);
	
	strKey	= join(append(kCandidate,opt.allbut),',');
	strHash	= str2hash(strKey);

%do we need to get the data?
	if twt.DataExist('followersettweets',strHash,'analysis',opt.analysis)
		tweet	= twt.LoadData('followersettweets',strHash,'analysis',opt.analysis);
		return;
	end

%get the data
	follower	= twt.GetFollowerSet(tw,kCandidate,'allbut',opt.allbut,'analysis',opt.analysis);
	
	strCache	= sprintf('%d_cache',strHash);
	
	tweet	= cellfunprogress(@(id) twt.GetUserTweets(tw,id,'cache',strCache,'earliest',opt.earliest,'latest',opt.latest,'analysis',opt.analysis),num2cell(follower.id),...
				'label'	, 'retrieving follower set tweets'	, ...
				'uni'	, false								  ...
				);

%save it
	twt.SaveData(tweet,'followersettweets',strHash,'analysis',opt.analysis);
