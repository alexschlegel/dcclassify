function [trl,evt] = FTTrialFun(cfg,trigStart,trigEnd)
% Donchin.FTTrialFun
% 
% Description:	custom fieldtrip trialfun for defining trial start times but
%				only in between two triggers
% 
% Syntax:	[trl,evt] = Donchin.FTTrialFun(cfg)
% 
% Updated: 2015-05-15
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%find trials including the endpoint
	evtValue	= cfg.trialdef.eventvalue;
	
	cfg.trialdef.eventvalue(end+1:end+2)	= [trigStart; trigEnd];
	
	[trl,evt]	= ft_trialfun_general(cfg);

%restrict to trials within the endpoints
	kTrialStart	= min(find(trl(:,4)==trigStart));
	kTrialEnd	= max(find(trl(:,4)==trigEnd));
	
	trl	= trl(kTrialStart+1:kTrialEnd-1,:);