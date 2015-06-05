function sPP = PreprocessData(cPathData,varargin)
% ECoGCategories.PreprocessData
% 
% Description:	preprocess the ECoG categories data for a subject
% 
% Syntax:	sPP = PreprocessData(cPathData,<options>)
% 
% In:
% 	cPathData	- a cell of the raw data for the subject
%	<options>:
%		param:	(<load>) the ECoG Categories parameters
%		force:	(true) true to force preprocessing
% 
% Out:
% 	sPP	- the preprocessed data struct
% 
% Updated: 2015-06-05
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
			'param'		, []	, ...
			'force'		, true	  ...
			);
	
	s	= regexp(PathGetFilePre(cPathData{1}),'^(?<id>[^0-9]+)\d+$','names');
	
	strPathPP	= PathUnsplit(PathGetDir(cPathData{1}),sprintf('%s-pp',s.id),'mat');
	
	%parameters
		if isempty(opt.param)
			param	= Donchin.GetParameters;
		else
			param	= opt.param;
		end
	
	param.dir_data	= PathGetDir(strPathPP);
	param.id		= s.id;

%do we need to preprocess?
	if ~opt.force && FileExists(strPathPP)
		sPP	= MATLoad(strPathPP,'s');
		
		return;
	end

%preprocess each input data file
	sPP	= cellfunprogress(@PreprocessOne,cPathData,...
			'label'	, sprintf('preprocessing data for %s',param.id)	, ... 
			'uni'	, false										  ...
			);

%combine and save the preprocessed data
	time	= sPP{1}.time;
	prm		= sPP{1}.param;
	
	sPP	= restruct(sPP);
	
	sPP.data	= cat(3,sPP.data{:});
	sPP.time	= time;
	sPP.trial	= structfun2(@(x) cat(1,x{:}),sPP.trial);
	sPP.param	= prm;
	
	MATSave(strPathPP,'s',sPP);

%------------------------------------------------------------------------------%
function s = PreprocessOne(strPathData)
	s		= MATLoad(strPathData,'s');
	s.trial	= reshape(s.trial,[],1);
	
	%save the parameters
		s.param				= param;
		
		s.param.data_shape	= s.shape;
		s					= rmfield(s,'shape');
		
		s.param.rate	= s.fs;
		s				= rmfield(s,'fs');
	
	%keep only the specified channels
		[bChannelKeep,kChannelKeep]	= ismember(param.channel.use,s.channel);
		
		s.data					= s.data(kChannelKeep,:,:);
		s.param.channel.data	= s.channel(kChannelKeep);
		s						= rmfield(s,'channel');
		
		nChannel	= numel(s.param.channel.data);
	
	%keep only the specified time points
		kSampleStart	= t2k(param.t.window.start,s.param.rate,s.time(1));
		kSampleEnd		= t2k(param.t.window.end,s.param.rate,s.time(1));
		
		s.data	= s.data(:,kSampleStart:kSampleEnd,:);
		s.time	= s.time(kSampleStart:kSampleEnd);
		
		nT	= numel(s.time);
	
	%reject trials
		nTrial	= size(s.data,3);
		
		%suprathreshold signal
			bRejectThreshold	= reshape(any(abs(reshape(s.data,nChannel*nT,nTrial))>param.threshold.reject,1),[],1);
		
		%error on the trial
			bRejectError	= reshape([s.trial.error],[],1);
		
		bReject	= bRejectThreshold | bRejectError;
		
		s.data(:,:,bReject)	= [];
		s.trial(bReject)	= [];
	
	%reshuffle the trial info
		s.trial	= restruct(reshape(s.trial,[],1));
		
		s.trial	= rmfield(s.trial,'error');
		
		s.trial.correct			= strcmp(s.trial.correct,'correct');
		s.trial.presentation	= cellfun(@(p) switch2(p,'first',1,'second',2,'third',3,'fourth',4,NaN),s.trial.presentation);
		s.trial.session			= cellfun(@(s) switch2(s,'encode',1,'recall',2,NaN),s.trial.session);
end
%------------------------------------------------------------------------------%

end
