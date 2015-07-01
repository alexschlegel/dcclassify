function s = GetRateLimitStatus(tw,cFamily,varargin)
% twt.GetRateLimitStatus
% 
% Description:	get the rate limit status of the specified resource families
% 
% Syntax:	s = twt.GetRateLimitStatus(tw,cFamily,[strResource]=<all>)
%
% In:
%	tw				- the twitty object
%	cFamily			- a resource family or cell of resource families. if a
%					  single resource family is specified, then the return
%					  struct has one element for every requested resource for
%					  that family. if a cell is specified, then the return
%					  struct has an element for each family.
%	[strResource]	- if specified, only return information for this resource
%					  in the specified family (cFamily must be a string)
%
% Out:
% 	s	- a struct of rate limit status info
% 
% Updated: 2015-06-25
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	strResource	= ParseArgs(varargin,[]);
	
	[cFamily,bNoCell]	= ForceCell(cFamily);
	
	assert(isempty(strResource) || bNoCell,'cFamily must be a string if a resource is specified');

%call the twitter API
	strFamily	= join(cFamily,',');
	
	param	= struct('resources',strFamily);
	
	S	= tw.callTwitterAPI('GET','https://api.twitter.com/1.1/application/rate_limit_status.json',param,1);

%parse the results
	s	= S{1}.resources;
	
	if bNoCell
		s	= s.(cFamily{1});
	end
	
	if ~isempty(strResource)
		s	= s.(strResource);
	end

%add some derived info
	s	= structtreefun(@ProcessRateLimitInfo,s,'offset',1);
	

%------------------------------------------------------------------------------%
function s = ProcessRateLimitInfo(s)
	s.now	= nowms;
	
	s.reset	= utc2local(unix2ms(s.reset));
	s.wait	= s.reset - s.now;
%------------------------------------------------------------------------------%