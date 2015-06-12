function cPathOut = ConstructDCControl(cPathPP,varargin)
% Donchin.ConstructDCControl
% 
% Description:	construct the control directed connectivities to use for
%				the control comparison
% 
% Syntax:	cPathOut = Donchin.ConstructDCControl(cPathPP,<options>)
% 
% In:
%	cPathPP	- a cell of paths to the preprocessed EEG data .mat files (see
%			  Donchin.PreprocessData)
%	<options>:
%		type:	(<required>) the comparison type:
%					'compute':	for compute +/- comparison
%					'task':		for comparison between all 4 tasks during
%								preparatory period
%					'task2':	for comparison between all 4 tasks during
%								preparatory period, with expanded window
%		output:	(<auto>) the output dc file paths
%		param:	(<load>) the donchin parameters from Donchin.GetParameters
%		cores:	(1) the number of cores to use
%		force:	(true) true to force processing if output exists
% 
% Updated: 2015-06-12
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
	
	cPathOut	= cellfun(@(fi,fo) unless(fo,PathAddSuffix(fi,'-dcc','mat')),cPathPP,cPathOut,'uni',false);
	
	%parameters
		if isempty(opt.param)
			param	= Donchin.GetParameters;
		else
			param	= opt.param;
		end
		
		param.type	= opt.type;
		param.cores	= opt.cores;

%determine which data need to be processed
	sz	= size(cPathPP);
	
	if opt.force
		bDo	= true(sz);
	else
		bDo	= ~FileExists(cPathOut);
	end

%preprocess
	if any(bDo(:))
		cellfunprogress(@(fi,fo) DCControlOne(fi,fo,param),cPathPP(bDo),cPathOut(bDo),...
			'label'	, 'constructing control DCs'	  ...
			);
	end

%------------------------------------------------------------------------------%
function DCControlOne(strPathPP,strPathOut,param)
	dc	= struct;
	
	strSession	= PathGetSession(strPathPP);
	
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
		bPosterior	= ismember(cElectrode,param.channel.posterior);
		dPosterior	= data(:,:,bPosterior);
		nPosterior	= size(dPosterior,3);
		
		bAnterior	= ismember(cElectrode,param.channel.anterior);
		dAnterior	= data(:,:,bAnterior);
		nAnterior	= size(dAnterior,3);
		
		clear data;
	
	%number of samples and trials
		nTrial	= numel(dc.label);
	
	%window start and lag info
		t	= param.(param.type).t;
		
		tStart	= reshape(t.gcsignal.start.min:t.gcsignal.start.step:t.gcsignal.start.max,[],1);
		nStart	= numel(tStart);
		
		tLag	= reshape(t.lag.min:t.lag.step:t.lag.max,[],1);
		
		%for now just do lag=5, which is about the peak lag for classification,
		%since doing all lags would take literally forever***
			tLag	= tLag(5);
		
		nLag	= numel(tLag);
		
		tStartRep	= repmat(tStart,[1 nLag]);
		tLagRep		= repmat(reshape(tLag,1,[]),[nStart 1]);
		
		tEnd	= tStartRep + t.gcsignal.duration + tLagRep;
		
		%convert times to sample indices
			kStart	= t2k(tStart,rate);
			kLag	= t2k(tLag,rate) - 1;
			kEnd	= t2k(tEnd,rate) - 1;
		
		dc.param.t.start	= tStart;
		dc.param.t.lag		= tLag;
		dc.param.t.end		= tEnd;
	
	%initialize the pattern arrays
		[teF,teB,gcF,gcB]	= deal(NaN(nTrial,nStart,nLag));
		
		dc.dim	= {'trial';'start_time';'lag'};
	
	%start the pool
		[b,~,pool]	= MATLABPoolOpen(param.cores);
		
		assert(b,'could not open pool');
	
	%construct the pattern for each window and lag
		nTask	= nTrial*nStart*nLag;
		
		tStart	= nowms;
		h		= filecounter;
		parfor kT=1:nTask
			kkT			= filecounter(h);
		
			[kR,kS,kL]	= ind2sub([nTrial nStart nLag],kT);
			
			kStartCur	= kStart(kS);
			kLagCur		= kLag(kL);
			kEndCur		= kEnd(kS,kL);
			
			%extract the windows of interest
				dPWin	= squeeze(dPosterior(kStartCur:kEndCur,kR,:));
				dAWin	= squeeze(dAnterior(kStartCur:kEndCur,kR,:));
				
				nTWin	= kEndCur - kStartCur + 1;
			
			%calculate the DCs
				teF(kT)	= TransferEntropy(dPWin,dAWin,'lag',kLagCur);
				teB(kT)	= TransferEntropy(dAWin,dPWin,'lag',kLagCur);
				
				gcF(kT)	= GrangerCausality(dPWin,dAWin,'lag',kLagCur);
				gcB(kT)	= GrangerCausality(dAWin,dPWin,'lag',kLagCur);
			
			status(sprintf('%s | task %05d/%d | trial %03d/%d | start %02d/%d | lag %02d/%d | %s remaining',strSession,kkT,nTask,kR,nTrial,kS,nStart,kL,nLag,etd(kkT/nTask,tStart)),0);
		end
		
		filecounter(h,'action','stop');
	
	%move the DC arrays into the output struct
		dc.te.forward	= teF;
		dc.te.backward	= teB;
		dc.gc.forward	= gcF;
		dc.gc.backward	= gcB;
	
	%save the data
		save(strPathOut,'-struct','dc');
		
	%close the pool
		MATLABPoolClose(pool);
%------------------------------------------------------------------------------%
