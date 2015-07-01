function s = GetUserInfo(tw,user)
% twt.GetUserInfo
% 
% Description:	get info about a set of users
% 
% Syntax:	s = twt.GetUserFollowers(tw,user)
%
% In:
% 	user	- an array of user ids
% 
% Updated: 2015-06-30
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
nUser	= numel(user);

%wait until we can get this resource
	nRemain	= WaitForResource;

s	= cell(nUser,1);

nPer	= 100;
progress('action','init','total',nUser,'step',nPer);
for kU=1:nPer:nUser
	kUCur	= kU:min(kU+nPer-1,nUser);
	
	s(kUCur)	= DoGet(user(kUCur));
	
	progress;
end

s	= restruct(s);

%------------------------------------------------------------------------------%
function cInfo = DoGet(id)
	n	= numel(id);
	
	if nRemain==0
		nRemain	= WaitForResource;
	end
	
	response	= reshape(tw.usersLookup('user_id',num2cell(id)),[],1);
	
	%match with the input ids and add blanks for null results
		idReturn	= cellfun(@(x) x.id,response);
		[b,kReturn]	= ismember(id,idReturn);
	
	cInfo		= cell(n,1);
	cInfo(b)	= cellfun(@(r) struct(...
					'id'			, r.id					, ...
					'user'			, r.screen_name			, ...
					'name'			, r.name				, ...
					'location'		, r.location			, ...
					'num_status'	, r.statuses_count		, ...
					'num_follower'	, r.followers_count		, ...
					'num_friends'	, r.friends_count		, ...
					'language'		, r.lang				  ...
					),response(kReturn(b)),'uni',false);
	cInfo(~b)	= {struct('id',NaN,'user','','name','','location','','num_status',NaN,'num_follower',NaN,'num_friends',NaN,'language','')};
	
	nRemain	= nRemain - 1;
end
%------------------------------------------------------------------------------%
function nRemain = WaitForResource() 
	nRemain	= twt.WaitUntilResource(tw,'users','users_lookup');
end
%------------------------------------------------------------------------------%

end
