% Analysis_20150701_Twitter
% 
% Description:	
% 
% Updated: 2015-07-01
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
tw	= twt.Twitty;

param	= twt.Param('declared',true);

%follower	= twt.GetFollowerSet(tw,param.candidate.index);

tweet	= twt.GetFollowerSetTweets(tw,param.candidate.index);
