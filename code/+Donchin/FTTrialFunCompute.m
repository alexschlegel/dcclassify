function [trl,evt] = FTTrialFunCompute(cfg,param)
% Donchin.FTTrialFunCompute
% 
% Description:	custom fieldtrip trialfun for defining trial start times but
%				only in during the compute task
% 
% Syntax:	[trl,evt] = Donchin.FTTrialFunCompute(cfg,param)
% 
% Updated: 2015-05-21
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%find trials including the endpoint
	cfg.trialdef.eventvalue	=	[
									param.trigger.imp_letter
									param.trigger.err_keyearly
									param.trigger.compute_start
									param.trigger.compute_end
								];
	
	[trl,evt]	= ft_trialfun_general(cfg);

%restrict to trials within the endpoints
	kTrialStart	= find(trl(:,4)==param.trigger.compute_start,1,'last');
	kTrialEnd	= find(trl(:,4)==param.trigger.compute_end,1,'last');
	
	trl	= trl(kTrialStart+1:kTrialEnd-1,:);

%keep track of the trial type
	trl	= [trl param.condition];
	
%keep only the good trials
	bGood	= trl(:,4)==param.trigger.imp_letter;
	trl		= trl(bGood,:);
