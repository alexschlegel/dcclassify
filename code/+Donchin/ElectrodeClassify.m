function res = ElectrodeClassify(cPathEP,varargin)
% Donchin.DCClassify
% 
% Description:	perform classification on the electrode patterns constructed by
%				Donchin.ConstructElectrodePatterns
% 
% Syntax:	res = Donchin.ElectrodeClassify(cPathEP,<options>)
% 
% In:
%	cPathEP	- a cell of paths to the electrode patterns construct by
%			  Donchin.ConstructElectrodePatterns
%	<options>:
%		type:		(<required>) the classification type:
%						'compute':	for compute +/- classification
%						'task':		for classification between all 4 tasks
%									during preparatory period
%						'task2':	for classification between all 4 tasks
%									during preparatory period, with expanded
%									window
%		output:		(<auto>) the output result file path. overrides <suffix>
%		cores:		(1) the number of cores to use
%		force:		(true) true to force classification
%		force_pre:	(<force>) true to force the individual subject
%					cross-validations
% 
% Updated: 2015-06-10
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirAnalysis

%parse the inputs
	opt	= ParseArgs(varargin,...
			'type'		, ''	, ...
			'output'	, []	, ...
			'cores'		, 1		, ...
			'force'		, true	, ...
			'force_pre'	, []	  ...
			);
	
	opt.force_pre	= unless(opt.force_pre,opt.force);
	
	strPathOut	= unless(opt.output,PathUnsplit(DirAppend(strDirAnalysis,'donchin'),sprintf('electrodeclassify_%s',opt.type),'mat'));
	CreateDirPath(PathGetDir(strPathOut));

%do we need to perform the analysis?
	bDo	= opt.force || ~FileExists(strPathOut);

%do it!
	if bDo
		param	= rmfield(opt,{'output','force','isoptstruct','opt_extra'});
		
		%do each subject's classification
			res	= cellfunprogress(@(f) ElectrodeClassifyOne(f,param),cPathDC,...
					'label'	, 'performing Electrode classification'	 ...
					);
			
		res	= restruct(res);
		
		%do some stats
			cFieldStat	= setdiff(fieldnames(res),'param');
			nFieldStat	= numel(cFieldStat);
			
			for kF=1:nFieldStat
				res.(cFieldStat{kF})	= GroupStats(res.(cFieldStat{kF}));
			end
		
		%save the results
			save(strPathOut,'-struct','res');
	else
		res	= load(strPathOut);
	end

%------------------------------------------------------------------------------%
function res= ElectrodeClassifyOne(strPathEP,param)
	global strDirAnalysis;
	
	strSession	= PathGetSession(strPathEP);
	strPathOut	= PathUnsplit(DirAppend(strDirAnalysis,'donchin'),sprintf('electrodeclassify-%s-%s',strSession,param.type),'mat');
	
	if ~param.force_pre && FileExists(strPathOut)
		res	= MATLoad(strPathOut,'res');
		return;
	end
	
	res	= struct;
	
	data	= load(strPathEP);
	
	%copy over some info
		res.param	= data.param;
	
	cType	= {'instantaneous';'window'};
	nType	= numel(cType);
	
	[nFeature,nTrial,nStart]	= size(data.(cType{1}));
	
	kTarget	= data.label;
	kChunk	= zeros(size(kTarget));
	
	kTargetU	= unique(kTarget);
	nTarget		= numel(kTargetU);
	
	for kT=1:nTarget
		kSampleTarget			= find(kTarget==kTargetU(kT));
		kChunk(kSampleTarget)	= 1:numel(kSampleTarget);
	end
	
	%start the pool
		[b,~,pool]	= MATLABPoolOpen(param.cores);
		
		assert(b,'could not open pool');
	
	%initialize some variables
		cRes	= cell(nStart,nType);
		nTask	= numel(cRes);
	
	tStart	= nowms;
	h		= filecounter;
	parfor kT=1:nTask
		kkT	= filecounter(h);
		
		[kS,kP]	= ind2sub([nStart nType],kT);
		
		strType	= cType{kP};
		
		dCur	= data.(strType)(:,:,kS);
		
		%make nSample x nFeature
			dCur	= permute(dCur,[2 1]);
		
		strName	= sprintf('%s/kS=%d',PathGetFilePre(strPathEP),kS);
		
		cRes{kT}	= MVPA.CrossValidation(dCur,kTarget,kChunk,...
						'name'				, strName	, ...
						'partitioner'		, 1			, ...
						'classifier'		, 'SVM'		, ...
						'zscore'			, 'chunk'	, ...
						'target_balancer'	, 10		, ...
						'error'				, false		, ...
						'silent'			, true		  ...
						);
		
		status(sprintf('%s | task %03d/%d | start %02d/%d | %s | %s remaining',strSession,kkT,nTask,kS,nStart,strType,etd(kkT/nTask,tStart)),0);
	end
	filecounter(h,'action','stop');
	
	%transfer to the struct and eliminate some redundancy
		for kP=1:nType
			strType	= cType{kP};
			
			res.(strType)	= cRes(:,kP);
			
			resFirst	= res.(strType){1};
			
			res.(strType)	= restruct(cell2mat(res.(strType)));
			
			cSame	= {'target','uniquetargets','chunk','uniquechunks','num_sample','num_feature'};
			nSame	= numel(cSame);
			
			for kS=1:nSame
				strField	= cSame{kS};
				
				res.(strType).(strField)	= resFirst.(strField);
			end
		end
	
	%save the result
		MATSave(strPathOut,'res',res);
	
	%close the pool
		MATLABPoolClose(pool);
%------------------------------------------------------------------------------%
function res = GroupStats(res)
	acc	= cat(3,res.mean{:});
	
	res.gmean	= nanmean(acc,3);
	res.gse		= nanstderr(acc,[],3);
	
	nTarget	= numel(res.uniquetargets{1});
	
	[h,p,ci,stats]	= ttest(acc,1/nTarget,...
						'dim'	, 3			, ...
						'tail'	, 'right'	  ...
						);
	
	res.t	= stats.tstat;
	res.df	= stats.df;
	res.p	= p;
%------------------------------------------------------------------------------%
