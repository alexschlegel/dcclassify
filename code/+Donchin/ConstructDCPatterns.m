function cPathOut = ConstructDCPatterns(cPathPP,varargin)
% Donchin.ConstructDCPatterns
% 
% Description:	construct the directed connectivity patterns to use for
%				classification
% 
% Syntax:	cPathOut = Donchin.ConstructDCPatterns(cPathPP,<options>)
% 
% In:
%	cPathPP	- a cell of paths to the preprocessed EEG data .mat files (see
%			  Donchin.PreprocessData)
%	<options>:
%		type:	(<required>) the classification type:
%					'compute':	for compute +/- classification
%					'all':		for classification between all 4 tasks during
%								preparatory period
%		output:	(<auto>) the output dc pattern file paths
%		param:	(<load>) the donchin parameters from Donchin.GetParameters
%		cores:	(1) the number of cores to use
%		force:	(true) true to force pattern construction
% 
% Updated: 2015-05-21
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
	
	cPathOut	= cellfun(@(fi,fo) unless(fo,PathAddSuffix(fi,'-dc','mat')),cPathPP,cPathOut,'uni',false);
	
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
		MultiTask(@DCPatternOne,{cPathPP(bDo) cPathOut(bDo) param},...
			'description'	, 'constructing DC patterns'	, ...
			'uniformoutput'	, true							, ...
			'cores'			, opt.cores						  ...
			);
	end

%------------------------------------------------------------------------------%
function DCPatternOne(strPathPP,strPathOut,param)
	dc	= struct;
	
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
		dc.forward	= NaN(nPosterior,nAnterior,nTrial,nStart,nLag);
		dc.backward	= NaN(nAnterior,nPosterior,nTrial,nStart,nLag);
		
		dc.dim	= {'src';'dst';'trial';'start_time';'lag'};
	
	%construct the pattern for each window and lag
		progress('action','init','name','start_time','total',nStart,'label','start times');
		for kT=1:nStart
			kStartCur	= kStart(kT);
			
			for kL=1:nLag
				kLagCur	= kLag(kL);
				kEndCur	= kEnd(kT,kL);
				
				%extract the windows of interest
					dPWin	= dPosterior(kStartCur:kEndCur,:,:);
					dAWin	= dAnterior(kStartCur:kEndCur,:,:);
					
					nTWin	= kEndCur - kStartCur + 1;
				
				%PCA-transform the data
					dPWin	= reshape(dPWin,nTWin*nTrial,nPosterior);
					dAWin	= reshape(dAWin,nTWin*nTrial,nAnterior);
					
					[~,dPWin]	= pca(dPWin);
					[~,dAWin]	= pca(dAWin);
					
					dPWin	= reshape(dPWin,nTWin,nTrial,nPosterior);
					dAWin	= reshape(dAWin,nTWin,nTrial,nPosterior);
				
				for kR=1:nTrial
					for kP=1:nPosterior
						for kA=1:nAnterior
							dP	= dPWin(:,kR,kP);
							dA	= dAWin(:,kR,kA);
							
							dc.forward(kP,kA,kR,kT,kL)	= GrangerCausalityUni(dP,dA,'lag',kLagCur);
							dc.backward(kA,kP,kR,kT,kL)	= GrangerCausalityUni(dA,dP,'lag',kLagCur);
						end
					end
				end
			end
			
			progress('name','start_time');
		end
	
	%save the data
		save(strPathOut,'-struct','dc');
%------------------------------------------------------------------------------%
