function [trl,evt] = FTTrialFunTask(cfg,param)
% Donchin.FTTrialFunTask
% 
% Description:	custom fieldtrip trialfun for defining trial start times for all
%				tasks. something weird is happening with the imperative
%				stimulus, so we'll define the imperative point as the first
%				prompt_cue_end after the the trial_start trigger (with no
%				intervening error trigger)
% 
% Syntax:	[trl,evt] = Donchin.FTTrialFunCompute(cfg,param)
% 
% Updated: 2015-05-21
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%relevant triggers
	trigTaskStart	=	[
							param.trigger.both_start
							param.trigger.select_start
							param.trigger.predict_start
							param.trigger.compute_start
						];
	trigTaskEnd		=	[
							param.trigger.both_end
							param.trigger.select_end
							param.trigger.predict_end
							param.trigger.compute_end
						];
	
	nTask	= numel(trigTaskStart);

%find all relevant trials
	cfg.trialdef.eventvalue	=	[
									trigTaskStart
									param.trigger.trial_start
									param.trigger.err_keyearly
									param.trigger.prompt_cue_end
									trigTaskEnd
								];
	
	[trl,evt]	= ft_trialfun_general(cfg);

%process each task
	[kKeep,kCondition]	= deal([]);
	
	nBad	= 0;
	
	for kT=1:nTask
		%find all the points where the task started
			kTaskStart	= find(trl(:,4)==trigTaskStart(kT));
			nTaskStart	= numel(kTaskStart);
		
		%find the good task block (it looks like e.g. sometimes a task was
		%aborted and started over
			bTaskFound	= false;
			for kS=1:nTaskStart
				kTaskEnd	= kTaskStart(kS) + find(trl(kTaskStart(kS)+1:end,4)==trigTaskEnd(kT),1,'first');
				
				kTrialStart	= kTaskStart(kS) + find(trl(kTaskStart(kS)+1:kTaskEnd-1,4)==param.trigger.trial_start);
				
				if numel(kTrialStart)>=80
					bTaskFound	= true;
					kTaskStart	= kTaskStart(kS);
					break;
				end
			end
		
			if ~bTaskFound
				error('no proper task period found for task %d',kT); 
			end
		
		%imperative stimulus should be close enough to the first prompt_cue_end
		%trigger
			kImp	= arrayfun(@(k) k + find(trl(k+1:kTaskEnd-1,4)==param.trigger.prompt_cue_end,1,'first'),kTrialStart);
		
		%make sure we don't have any errors between the trial start and the
		%prompt cue end
			bGood	= arrayfun(@(ks,ki) ~any(trl(ks:ki,4)==param.trigger.err_keyearly),kTrialStart,kImp);
			nBad	= nBad + sum(~bGood);
		
		kKeep		= [kKeep; kImp(bGood)];
		kCondition	= [kCondition; param.condition{kT}(bGood)];
	end
	
	trl	= trl(kKeep,:);
	trl	= [trl kCondition];
