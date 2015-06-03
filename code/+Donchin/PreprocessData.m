function cPathOut = PreprocessData(cPathEEG,varargin)
% Donchin.PreprocessData
% 
% Description:	preprocess the EEG data using fieldtrip
% 
% Syntax:	cPathOut = Donchin.PreprocessData(cPathEEG,<options>)
% 
% In:
%	cPathEEG	- a cell of paths to the input EEG data
%	<options>:
%		type:	(<required>) the classification type:
%					'compute':	for compute +/- classification
%					'task':		for classification between all 4 tasks during
%								preparatory period
%					'task2':	for classification between all 4 tasks during
%								preparatory period, with expanded window
%		output:	(<auto>) the output preprocessed data file paths
%		param:	(<load>) the donchin parameters from Donchin.GetParameters
%		cores:	(1) the number of cores to use
%		force:	(true) true to force preprocessing
% 
% Updated: 2015-06-03
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
			'type'		, ''	, ...
			'output'	, []		, ...
			'param'		, []		, ...
			'cores'		, 1			, ...
			'force'		, true		  ...
			);
	
	opt.type	= CheckInput(opt.type,'type',{'compute','task','task2'});
	
	[cPathEEG,cPathOut]	= ForceCell(cPathEEG,opt.output);
	[cPathEEG,cPathOut]	= FillSingletonArrays(cPathEEG,cPathOut);
	
	cPathOut	= cellfun(@(fi,fo) unless(fo,PathAddSuffix(fi,sprintf('-pp_%s',opt.type),'mat')),cPathEEG,cPathOut,'uni',false);
	
	%parameters
		if isempty(opt.param)
			param	= Donchin.GetParameters;
		else
			param	= opt.param;
		end
		
		param.type	= opt.type;

%determine which data need to be preprocessed
	sz	= size(cPathEEG);
	
	if opt.force
		bDo	= true(sz);
	else
		bDo	= ~FileExists(cPathOut);
	end

%preprocess
	if any(bDo(:))
		MultiTask(@PreprocessOne,{cPathEEG(bDo) cPathOut(bDo) param},...
			'description'	, 'preprocessing EEG data'	, ...
			'uniformoutput'	, true						, ...
			'cores'			, opt.cores					  ...
			);
	end

%------------------------------------------------------------------------------%
function PreprocessOne(strPathEEG,strPathOut,param)
	%get the condition info
		strPathMAT	= PathAddSuffix(strPathEEG,'','mat');
		sSession	= load(strPathMAT);
		
		switch param.type
			case 'compute'
				kCondition	= sSession.trial.compute.isGreen + 1; %1==red, 2==green
			case {'task','task2'}
				cTask	= {'both';'select';'predict';'compute'};
				nTask	= numel(cTask);
				nTrial	= cellfun(@(t) numel(sSession.trial.(t).tPrompt),cTask);
				
				kCondition	= arrayfun(@(t,n) repmat(t,[n 1]),(1:nTask)',nTrial,'uni',false);
		end
		
	%define the trials
		cfg	= struct;
		
		cfg.trialdef.prestim	= -param.(param.type).t.window.start;
		cfg.trialdef.poststim	= param.(param.type).t.window.end;
		
		cfg.trialdef.eventtype	= 'STATUS';
		
		cfg.dataset	= strPathEEG;
		
		param.condition	= kCondition;
		
		switch param.type
			case 'compute'
				cfg.trialfun = @(cfg) Donchin.FTTrialFunCompute(cfg,param);
			case {'task','task2'}
				cfg.trialfun = @(cfg) Donchin.FTTrialFunTask(cfg,param);
		end
		
		cfg	= 	ft_definetrial(cfg);
		
		%get rid of the prompt_cue_end and char_flip triggers!
			bBlank						= cellfun(@isempty,{cfg.event.value});
			[cfg.event(bBlank).value]	= deal(0);
			
			eventValue	= [cfg.event.value];
			bKeep		= eventValue~=param.trigger.prompt_cue_end & eventValue~=param.trigger.char_flip;
			cfg.event	= cfg.event(bKeep);
	
	%preprocess the data
		%padding for filtering operations (to mitigate edge effects)
		%fieldtrip oddly defines 'padding' here as the total padded duration of a trial
			cfg.padding	= param.(param.type).t.window.pad;
			cfg.padtype	= 'data';
		
		%filtering
			cfg.bpfilter	= 'yes';
			cfg.bpfreq		= [param.filter.hp param.filter.lp];
			cfg.bpfiltord	= param.filter.order;
			
			cfg.dftfilter	= 'yes';
			cfg.dftfilter	= 60*(1:3);
			
		%baseline correction (whole trial, i.e. demean)
			cfg.demean	= 'yes';
			
		%rereferencing
			cfg.reref		= 'yes';
			cfg.refchannel	= param.channel.ref;
		
		%channels of interest
			cfg.channel	= param.channel.use;
		
		data	= ft_preprocessing(cfg);
	
	%downsample
		%not yet
	
	%to manually check data:
		%cfg	= ft_databrowser(cfg,data);
	
	%reject trials with supra-threshold amplitude
		kChannelCheck	= find(ismember(data.label,param.channel.reject));
		bTrialReject	= cellfun(@(d) any(reshape(abs(d(kChannelCheck,:)),[],1)>param.threshold.reject),data.trial);
		
		cfg.artfctdef.visual.artifact	= data.sampleinfo(bTrialReject,:);
		cfg.artfctdef.reject 			= 'complete';
		
		data	= ft_rejectartifact(cfg,data);
	
	%save the data
		save(strPathOut,'data','cfg');
%------------------------------------------------------------------------------%
