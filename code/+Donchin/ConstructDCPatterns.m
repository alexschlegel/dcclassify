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
%		output:	(<auto>) the output dc pattern file paths
%		param:	(<load>) the donchin parameters from Donchin.GetParameters
%		cores:	(1) the number of cores to use
%		force:	(true) true to force pattern construction
% 
% Updated: 2015-05-19
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
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
		
	%number of trials
		nTrial	= numel(dc.label);
	
	%window start and lag info
		tStart	= reshape(param.t.gcsignal.start.min:param.t.gcsignal.start.step:param.t.gcsignal.start.max,[],1);
		tEnd	= tStart + param.t.gcsignal.duration;
		nStart	= numel(tStart);
	
		tLag	= reshape(param.t.lag.min:param.t.lag.step:param.t.lag.max,[],1);
		nLag	= numel(tLag);
		
		%convert times to sample indices
			kStart	= t2k(tStart,rate);
			kEnd	= t2k(tEnd,rate) - 1;
			kLag	= t2k(tLag,rate) - 1;
		
		dc.param.t.start	= tStart;
		dc.param.t.end		= tEnd;
		dc.param.t.lag		= tLag;
	
	%classification directions
		cDirection	= {'forward';'backward'};
		nDirection	= numel(cDirection);
	
	%initialize the pattern arrays
		dc.forward	= NaN(nPosterior,nAnterior,nTrial,nStart,nLag);
		dc.backward	= NaN(nAnterior,nPosterior,nTrial,nStart,nLag);
		
		dc.dim	= {'src';'dst';'trial';'start_time';'lag'};
	
	%construct the pattern for each window and lag
		progress('action','init','name','start_time','total',nStart,'label','start times');
		for kT=1:nStart
			kStartCur	= kStart(kT);
			kEndCur		= kEnd(kT);
			
			dP	= dPosterior(kStartCur:kEndCur,:,:);
			dA	= dAnterior(kStartCur:kEndCur,:,:);
			
			for kD=1:nDirection
				strDirection	= cDirection{kD};
				
				switch strDirection
					case 'forward'
						dSrc	= dP;
						dDst	= dA;
					case 'backward'
						dSrc	= dA;
						dDst	= dP;
				end
				
				nSrc	= size(dSrc,3);
				nDst	= size(dDst,3);
				
				for kL=1:nLag
					kLagCur	= kLag(kL);
					
					for kSrc=1:nSrc
						for kDst=1:nDst
							for kR=1:nTrial
								dSrcCur	= dSrc(:,kR,kSrc);
								dDstCur	= dDst(:,kR,kDst);
								
								dc.(strDirection)(kSrc,kDst,kR,kT,kL)	= GrangerCausalityUni(dSrcCur,dDstCur,'lag',kLagCur);
							end
						end
					end
				end
			end
			
			progress('name','start_time');
		end
	
	%save the data
		save(strPathOut,'-struct','dc');
%------------------------------------------------------------------------------%
