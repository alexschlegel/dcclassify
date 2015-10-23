function tweet = GetUserTweets(tw,id,varargin)
% twt.GetUserTweets
% 
% Description:	get all available tweets for the specified user
% 
% Syntax:	tweet = twt.GetUserTweets(tw,id,<options>)
%
% In:
% 	tw	- the twitty object
% 	id	- the user id
% 	<options>:
%		earliest:	(0) the timestamp of the earliest tweet to return
%		latest:		(<nowmsUTC>) the timestamp of the latest tweet to return
% 		cache:		(<none>) the name of the data cache to check for existing
%					tweets
%		analysis:	('twitter') the analysis data to use
% 
% Updated: 2015-10-15
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
			'earliest'	, 0			, ...
			'latest'	, nowmsUTC	, ...
			'cache'		, []		, ...
			'analysis'	, 'twitter'	  ...
			);
	
	bUseCache	= ~isempty(opt.cache);

%do we need to get the tweets?
	if bUseCache && twt.DataExist(opt.cache,id,'analysis',opt.analysis)
		tweet	= twt.LoadData(opt.cache,id,'analysis',opt.analysis);
		return;
	end

%wait until we can get this resource
	nRemain	= WaitForResource;

nextTweetID	= '';

tweet	= {};
nStatus	= 0;
nCall	= 0;
while ~strcmp(nextTweetID,'0')
	strStatus	= sprintf('%d tweets retrieved, %d call%s',numel(tweet),nCall,plural(nCall));
	fprintf('%s%s',repmat(sprintf('\b'),[1 nStatus]),strStatus);
	nStatus	= numel(strStatus);
	
	[tweetNew,nextTweetID]	= GetTweetsBeforeID(nextTweetID);
	
	tweet(end+1:end+numel(tweetNew))	= tweetNew;
	
	nCall	= nCall + 1;
end

fprintf('\n');

tweet	= restruct(reshape(tweet,[],1));

if bUseCache
	twt.SaveData(tweet,opt.cache,id,'analysis',opt.analysis);
end

%------------------------------------------------------------------------------%
function [tweet,nextTweetID] = GetTweetsBeforeID(tweet_id)
	if nRemain==0
		nRemain	= WaitForResource;
	end
	
	if ~isempty(tweet_id)
		max_id	= num2str(str2uint64(tweet_id) - uint64(1));
		
		prm	= {'max_id',max_id};
	else
		prm	= {};
	end
	
	try
		response	= tw.userTimeline('user_id',id,prm{:},'count',200,'exclude_replies',0,'include_rts',1);
	catch me
		%maybe the user became protected after we got the user info
		if strfind(me.message,'response code: 401')
			try
				user	= twt.GetUserInfo(tw,id);
			catch me
				%maybe user was deleted
				tweet		= {};
				nextTweetID	= '0';
				return;
			end
			
			if user.protected
				%yep
				tweet		= {};
				nextTweetID	= '0';
				return;
			else
				rethrow(me);
			end
		else
			rethrow(me);
		end
	end
	
	if numel(response)==1 && numel(response{1})>1
	%why is this happening?
		response	= num2cell(response{1});
	end
	
	if ~isempty(response)
		response	= reshape(response,[],1);
		
		tweet	= cellfun(@(r) struct(...
					'id'					, str2uint64(r.id_str)										, ...
					'time'					, FormatTime(r.created_at,'ddd mmm dd HH:MM:SS +0000 yyyy')	, ...
					'text'					, r.text													, ...
					'in_reply_to_status_id'	, str2uint64(unless(r.in_reply_to_status_id_str,'0'))		, ...
					'in_reply_to_user_id'	, str2uint64(unless(r.in_reply_to_user_id_str,'0'))			, ...
					'is_quote_status'		, r.is_quote_status											  ...
					),response,'uni',false);
		
		%keep only tweets within the specified time period
			tTweet		= cellfun(@(t) t.time,tweet);
			bTweetValid	= tTweet>=opt.earliest & tTweet<=opt.latest;
			tweet		= tweet(bTweetValid);
		
		if ~isempty(tweet)
			nextTweetID	= num2str(min(cellfun(@(t) t.id,tweet)));
		else
			nextTweetID	= '0';
		end
	else
		tweet		= {};
		nextTweetID	= '0';
	end
	
	nRemain	= nRemain - 1;
end
%------------------------------------------------------------------------------%
function nRemain = WaitForResource() 
	nRemain	= twt.WaitUntilResource(tw,'statuses','statuses_user_timeline');
end
%------------------------------------------------------------------------------%

end
