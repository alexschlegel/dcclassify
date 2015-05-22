function res = DCClassify(cPathDC,varargin)
% Donchin.DCClassify
% 
% Description:	perform classification on the DC patterns constructed by
%				Donchin.ConstructDCPatterns
% 
% Syntax:	res = Donchin.DCClassify(cPathDC,<options>)
% 
% In:
%	cPathDC	- a cell of paths to the DC patterns construct by
%			  Donchin.ConstructDCPatterns
%	<options>:
%		type:	(<required>) the classification type:
%					'compute':	for compute +/- classification
%					'all':		for classification between all 4 tasks during
%								preparatory period
%		output:	(<auto>) the output result file path. overrides <suffix>
%		cores:	(1) the number of cores to use
%		force:	(true) true to force dc classification
% 
% Updated: 2015-05-21
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirAnalysis

%parse the inputs
	opt	= ParseArgs(varargin,...
			'type'		, ''	, ...
			'output'	, []	, ...
			'cores'		, 1		, ...
			'force'		, true	  ...
			);
	
	strPathOut	= unless(opt.output,PathUnsplit(DirAppend(strDirAnalysis,'donchin'),sprintf('dcclassify_%s',opt.type),'mat'));
	CreateDirPath(PathGetDir(strPathOut));

%do we need to perform the analysis?
	bDo	= opt.force || ~FileExists(strPathOut);

%do it!
	if bDo
		%do each subject's classification
			res	= MultiTask(@DCClassifyOne,{cPathDC},...
					'description'	, 'performing DC classification'	, ...
					'uniformoutput'	, true								, ...
					'cores'			, opt.cores							  ...
					);
			
		res	= restruct(res);
		
		%do some stats
			res	= structfun2(@GroupStats,res);
		
		%save the results
			save(strPathOut,'-struct','res');
	else
		res	= load(strPathOut);
	end

%------------------------------------------------------------------------------%
function res= DCClassifyOne(strPathDC)
	res	= struct;
	
	data	= load(strPathDC);
	
	cDirection	= {'forward';'backward'};
	nDirection	= numel(cDirection);
	
	[nSrc,nDst,nTrial,nStart,nLag]	= size(data.(cDirection{1}));
	
	kTarget	= data.label;
	kChunk	= reshape(1:nTrial,size(kTarget));
	
	for kD=1:nDirection
		strDirection	= cDirection{kD};
		dDir			= data.(strDirection);
		
		res.(strDirection)	= cell(nStart,nLag);
		
		for kS=1:nStart
			for kL=1:nLag
				dCur	= reshape(dDir(:,:,:,kS,kL),nSrc*nDst,nTrial);
				
				%make nSample x nFeature
					dCur	= permute(dCur,[2 1]);
				
				strName	= sprintf('%s/kS=%d/kL=%d',PathGetFilePre(strPathDC),kS,kL);
				
				res.(strDirection){kS,kL}	= MVPA.CrossValidation(dCur,kTarget,kChunk,...
												'name'				, strName	, ...
												'partitioner'		, 1			, ...
												'classifier'		, 'SVM'		, ...
												'zscore'			, false		, ...
												'target_balancer'	, 10		, ...
												'error'				, false		, ...
												'silent'			, true		  ...
												);
			end
		end
		
		res.(strDirection)	= restruct(cell2mat(res.(strDirection)));
	end
%------------------------------------------------------------------------------%
function res = GroupStats(res)
	acc	= cat(3,res.mean{:});
	
	res.gmean	= nanmean(acc,3);
	res.gse		= nanstderr(acc,[],3);
	
	[h,p,ci,stats]	= ttest(acc,0.5,...
						'dim'	, 3			, ...
						'tail'	, 'right'	  ...
						);
	
	res.t	= stats.tstat;
	res.df	= stats.df;
	res.p	= p;
%------------------------------------------------------------------------------%
