function nRemain = WaitUntilResource(tw,strFamily,strResource,varargin)
% twt.WaitUntilResource
% 
% Description:	wait until a resource rate limit is not exceeded
% 
% Syntax:	nRemain = twt.WaitUntilResource(tw,strFamily,strResource)
%
% In:
%	tw			- the twitty object
%	strFamily	- the resource family
%	strResource	- the resource within the family
%	<options>:
%		silent:	(false) true to suppress status messages
%
% Out:
% 	nRemain	- the number of remaining requests of the specified resource
% 
% Updated: 2015-06-25
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
			'silent'	, false	  ...
			);

%get the resource's current rate limit status
	s	= twt.GetRateLimitStatus(tw,strFamily,strResource);
	
	nRemain	= s.remaining;

%wait
	if nRemain==0
		tWaitUntil	= max(s.reset,nowms+5000);
		
		status(sprintf('waiting until %s for resource limit reset',FormatTime(tWaitUntil)),'silent',opt.silent);
		pauseUntil(tWaitUntil);
		
		%make sure it is free
			nRemain	= twt.WaitUntilResource(tw,strFamily,strResource,'silent',true);
		
		status('resuming...','silent',opt.silent);
	end
