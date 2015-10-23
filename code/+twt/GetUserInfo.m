function s = GetUserInfo(tw,user)
% twt.GetUserInfo
% 
% Description:	get info about a set of users
% 
% Syntax:	s = twt.GetUserInfo(tw,user)
%
% In:
% 	user	- an array of user ids or a cell array of screen names
% 
% Updated: 2015-10-12
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

if ischar(user)
	user	= {user};
end

nUser	= numel(user);

%wait until we can get this resource
	nRemain	= WaitForResource;

s	= cell(nUser,1);

nPer	= 100;
progress('action','init','total',nUser,'step',nPer,'label','retrieving user info');
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
	
	if iscell(id)
		cID			= id;
		userType	= 'screen_name';
	else
		cID			= num2cell(id);
		userType	= 'user_id';
	end
	
	response	= reshape(tw.usersLookup(userType,cID),[],1);
	
	%match with the input ids and add blanks for null results
		switch userType
			case 'screen_name'
				userReturn	= cellfun(@(x) x.screen_name,response,'uni',false);
				[b,kReturn]	= ismember(cID,userReturn);
			case 'user_id'
				idReturn	= cellfun(@(x) x.id,response);
				[b,kReturn]	= ismember(id,idReturn);
		end
	
	cInfo		= cell(n,1);
	cInfo(b)	= cellfun(@(r) struct(...
					'id'			, r.id					, ...
					'user'			, r.screen_name			, ...
					'name'			, r.name				, ...
					'location'		, r.location			, ...
					'num_status'	, r.statuses_count		, ...
					'num_follower'	, r.followers_count		, ...
					'num_friends'	, r.friends_count		, ...
					'language'		, r.lang				, ...
					'protected'		, r.protected			  ...
					),response(kReturn(b)),'uni',false);
	cInfo(~b)	= {struct('id',NaN,'user','','name','','location','','num_status',NaN,'num_follower',NaN,'num_friends',NaN,'language','','protected',NaN)};
	
	nRemain	= nRemain - 1;
end
%------------------------------------------------------------------------------%
function nRemain = WaitForResource() 
	nRemain	= twt.WaitUntilResource(tw,'users','users_lookup');
end
%------------------------------------------------------------------------------%

end
