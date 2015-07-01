function id = GetUserFollowers(tw,user)
% twt.GetUserFollowers
% 
% Description:	get the ids of all followers of the specified user
% 
% Syntax:	id = twt.GetUserFollowers(tw,user)
% 
% Updated: 2015-06-25
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%wait until we can get this resource
	nRemain	= WaitForResource;

nextCursor	= '';

id	= [];
while ~strcmp(nextCursor,'0')
	[idNew,nextCursor]	= GetFollowersByCursor(nextCursor);
	
	id(end+1:end+numel(idNew))	= idNew;
end

id	= sort(reshape(id,[],1));

%------------------------------------------------------------------------------%
function [id,nextCursor] = GetFollowersByCursor(cursor)
	if nRemain==0
		nRemain	= WaitForResource;
	end
	
	param	= conditional(isempty(cursor),{},{'cursor',cursor});
	
	response	= tw.followersIds('screen_name',user,param{:});
	
	id			= response{1}.ids;
	nextCursor	= response{1}.next_cursor_str;
	
	nRemain	= nRemain - 1;
end
%------------------------------------------------------------------------------%
function nRemain = WaitForResource() 
	nRemain	= twt.WaitUntilResource(tw,'followers','followers_ids');
end
%------------------------------------------------------------------------------%

end
