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
%		output:	(<auto>) the output result file path
%		cores:	(1) the number of cores to use
%		force:	(true) true to force dc classification
% 
% Updated: 2015-05-20
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirAnalysis

%parse the inputs
	opt	= ParseArgs(varargin,...
			'output'	, []	, ...
			'cores'		, 1		, ...
			'force'		, true	  ...
			);
	
	strPathOut	= unless(opt.output,PathUnsplit(DirAppend(strDirAnalysis,'donchin'),'dcclassify','mat'));
	CreateDirPath(PathGetDir(strPathOut));

%do we need to perform the analysis?
	bDo	= opt.force || ~FileExists(strPathOut);

%do it!
	if bDo
		%do each subject's classification
			resSubject	= MultiTask(@DCClassifyOne,{cPathDC},...
							'description'	, 'performing DC classification'	, ...
							'uniformoutput'	, true								, ...
							'cores'			, opt.cores							  ...
							);
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
				
				res.(strDirection){kS,kL}	= MVPA.CrossValidation(dCur,kTarget,kChunk,...
												'partitioner'		, 1		, ...
												'classifier'		, 'svm'	, ...
												'zscore'			, false	, ...
												'target_balancer'	, 10	, ...
												'silent'			, true	  ...
												);
			end
		end
		
		res.(strDirection)	= cell2mat(res.(strDirection));
	end
%------------------------------------------------------------------------------%