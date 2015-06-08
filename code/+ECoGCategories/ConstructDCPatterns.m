function sDC = ConstructDCPatterns(sPP,varargin)
% ECoGCategories.ConstructDCPatterns
% 
% Description:	construct the directed connectivity patterns for the ECoG
%				categories data
% 
% Syntax:	sDC = ECoGCategories.ConstructDCPatterns(sPP,<options>)
% 
% In:
%	sPP	- the preprocessed data returned from ECoGCategories.PreprocessData
%	<options>:
%		cores:	(1) the number of cores to use
%		force:	(true) true to force pattern construction
% 
% Updated: 2015-06-05
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
			'cores'		, 1		, ...
			'force'		, true	  ...
			);
	
	strPathDC	= PathUnsplit(sPP.param.dir_data,sprintf('%s-dc',sPP.param.id),'mat');

%do we need to construct the DC patterns?
	if ~opt.force && FileExists(strPathDC)
		sDC	= MATLoad(strPathPP,'s');
		
		return;
	end

%construct the patterns
	sDC	= struct;
	
	sDC.param	= sPP.param;
	sDC.extra	= rmfield(sPP.trial,'category');
	
	%extract just the data we need
		t			= sPP.time;
		rate		= sPP.param.rate;
		cElectrode	= sPP.param.channel.data;
		
		sDC.label	= sPP.trial.category;
		
		%permute the data to nSample x nTrial x nElectrode
			data	= permute(sPP.data,[2 3 1]);
		
		clear sPP;
	
	%keep data from the electrodes of interest
		bPosterior	= ismember(cElectrode,sDC.param.channel.posterior);
		dPosterior	= data(:,:,bPosterior);
		nPosterior	= size(dPosterior,3);
		
		bAnterior	= ismember(cElectrode,sDC.param.channel.anterior);
		dAnterior	= data(:,:,bAnterior);
		nAnterior	= size(dAnterior,3);
		
		clear data;
	
	%number of samples and trials
		nTrial	= numel(sDC.label);
	
	%window start and lag info
		sT	= sDC.param.t;
		
		tStart	= reshape(sT.gcsignal.start.min:sT.gcsignal.start.step:sT.gcsignal.start.max,[],1);
		nStart	= numel(tStart);
	
		tLag	= reshape(sT.lag.min:sT.lag.step:sT.lag.max,[],1);
		nLag	= numel(tLag);
		
		tStartRep	= repmat(tStart,[1 nLag]);
		tLagRep		= repmat(reshape(tLag,1,[]),[nStart 1]);
		
		tEnd	= tStartRep + sT.gcsignal.duration + tLagRep;
		
		%convert times to sample indices
			kStart	= t2k(tStart,rate,t(1));
			kLag	= t2k(tLag,rate) - 1;
			kEnd	= t2k(tEnd,rate,t(1)) - 1;
		
		sDC.param.t.start	= tStart;
		sDC.param.t.lag		= tLag;
		sDC.param.t.end		= tEnd;
	
	%initialize the pattern arrays
		dcForward	= NaN(nPosterior,nAnterior,nTrial,nStart,nLag);
		dcBackward	= NaN(nAnterior,nPosterior,nTrial,nStart,nLag);
		
		sDC.dim	= {'src';'dst';'trial';'start_time';'lag'};
	
	%construct the pattern for each window and lag
		[b,~,pool]	= MATLABPoolOpen(opt.cores,'ntask',nStart);
		if ~b
			error('could not open matlab pool');
		end
		
		tStart	= nowms;
		
		strPathCounter	= GetTempFile;
		fput('0',strPathCounter);
		
		parfor kT=1:nStart
			if kT<=opt.cores
				pause(kT/4);
			end
			
			kkT	= str2double(fget(strPathCounter)) + 1;
			fput(num2str(kkT),strPathCounter);
			
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
							
							dcForward(kP,kA,kR,kT,kL)	= GrangerCausalityUni(dP,dA,'lag',kLagCur);
							dcBackward(kA,kP,kR,kT,kL)	= GrangerCausalityUni(dA,dP,'lag',kLagCur);
						end
					end
					
					status(sprintf('start %02d/%d | lag %02d/%d | trial %03d/%d | %s remaining',kkT,nStart,kL,nLag,kR,nTrial,etd((kkT-1)/nStart,tStart)),0);
				end
			end
		end
		
		delete(strPathCounter);
		
		MATLABPoolClose(pool);
	
	%transfer the DC patterns to the output struct
		sDC.forward		= dcForward;
		sDC.backward	= dcBackward;
	
	%save the data
		MATSave(strPathDC,'s',sDC);
%------------------------------------------------------------------------------%
