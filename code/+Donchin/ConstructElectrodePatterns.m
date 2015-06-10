function cPathOut = ConstructElectrodePatterns(cPathPP,varargin)
% Donchin.ConstructElectrodePatterns
% 
% Description:	construct the electrode activity patterns to use for
%				classification
% 
% Syntax:	cPathOut = Donchin.ConstructElectrodePatterns(cPathPP,<options>)
% 
% In:
%	cPathPP	- a cell of paths to the preprocessed EEG data .mat files (see
%			  Donchin.PreprocessData)
%	<options>:
%		type:	(<required>) the classification type:
%					'compute':	for compute +/- classification
%					'task':		for classification between all 4 tasks during
%								preparatory period
%					'task2':	for classification between all 4 tasks during
%								preparatory period, with expanded window
%		output:	(<auto>) the output electrode pattern file paths
%		param:	(<load>) the donchin parameters from Donchin.GetParameters
%		cores:	(1) the number of cores to use
%		force:	(true) true to force pattern construction
% 
% Updated: 2015-06-10
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
			'type'		, ''	, ...
			'output'	, []	, ...
			'param'		, []	, ...
			'cores'		, 1		, ...
			'force'		, true	  ...
			);
	
	[cPathPP,cPathOut]	= ForceCell(cPathPP,opt.output);
	[cPathPP,cPathOut]	= FillSingletonArrays(cPathPP,cPathOut);
	
	cPathOut	= cellfun(@(fi,fo) unless(fo,PathAddSuffix(fi,'-ep','mat')),cPathPP,cPathOut,'uni',false);
	
	%parameters
		if isempty(opt.param)
			param	= Donchin.GetParameters;
		else
			param	= opt.param;
		end
		
		param.type	= opt.type;

%determine which data need to be processed
	sz	= size(cPathPP);
	
	if opt.force
		bDo	= true(sz);
	else
		bDo	= ~FileExists(cPathOut);
	end

%preprocess
	if any(bDo(:))
		MultiTask(@EPatternOne,{cPathPP(bDo) cPathOut(bDo) param},...
			'description'	, 'constructing electrode patterns'	, ...
			'uniformoutput'	, true								, ...
			'cores'			, opt.cores							  ...
			);
	end

%------------------------------------------------------------------------------%
function EPatternOne(strPathPP,strPathOut,param)
	ep	= struct;
	
	%load the preprocessed data
		status('loading preprocessed data');
		data	= MATLoad(strPathPP,'data');
		status('preprocessed data loaded!');
	
	%extract just the data we need
		t			= data.time{1};
		rate		= data.fsample;
		cElectrode	= data.label;
		
		dc.label	= data.trialinfo(:,2);
		
		%permute the data to nSample x nTrial x nElectrode
			data	= permute(cat(3,data.trial{:}),[2 3 1]);
	
	%keep data from the electrodes of interest
		cElectrodeUse	= [param.channel.posterior; param.channel.anterior];
		
		bUse		= ismember(cElectrode,cElectrodeUse);
		data		= data(:,:,bUse);
		nFeature	= size(data,3);
	
	%number of samples and trials
		nTrial	= numel(dc.label);
	
	%window start info
		t	= param.(param.type).t;
		
		tStart	= reshape(t.gcsignal.start.min:t.gcsignal.start.step:t.gcsignal.start.max,[],1);
		tEnd	= tStart + t.gcsignal.duration;
		nStart	= numel(tStart);
		
		%convert times to sample indices
			kStart	= t2k(tStart,rate);
			kEnd	= t2k(tEnd,rate) - 1;
		
		ep.param.t.start	= tStart;
		ep.param.t.end		= tEnd;
	
	%initialize the pattern arrays
		[ep.instantaneous,ep.window]	= deal(NaN(nFeature,nTrial,nStart));
		
		ep.dim	= {'electrode';'trial';'start_time'};
	
	%construct the pattern for each window and lag
		for kT=1:nStart
			kStartCur	= kStart(kT);
			kEndCur		= kEnd(kT);
			
			dWin	= permute(data(kStartCur:kEndCur,:,:),[3 2 1]);
			
			ep.instantaneous(:,:,kT)	= dWin(:,:,1);
			ep.window(:,:,kT)			= mean(dWin,3);
		end
	
	%save the data
		save(strPathOut,'-struct','ep');
%------------------------------------------------------------------------------%
