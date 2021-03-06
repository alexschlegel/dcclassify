% Analysis_20150513_DonchinComputeDCClassify
% 
% Description:	use the DC Classification method to classify between addition
%				and subtraction operations in the Compute condition. we will try
%				both posterior->anterior and anterior->posterior DC patterns at
%				a range of lags.
% 
% Updated: 2015-05-21
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
nCore	= 12;

strExperiment	= 'donchin';

%output dir
	strDirOut	= DirAppend(strDirBase,'analysis',strExperiment);
	CreateDirPath(strDirOut);

%parameters
	param	= Donchin.GetParameters;

%input data
	cPathEEG	= FindFiles(DirAppend(strDirData,'donchin'),'^\d\d\w\w\w\d\d\w\w\.bdf$');
	
	%reject ec from compute classification because it looks like he blinked
	%immediately after every trial
		[t,id]	= cellfun(@(f) ParseSessionCode(PathGetFilePre(f)),cPathEEG,'uni',false);
		
		bReject	= ismember(id,{'ec'});
		
		cPathEEG	= cPathEEG(~bReject);

%preprocess the data
	cPathPP		= Donchin.PreprocessData(cPathEEG,...
					'type'	, 'compute'	, ...
					'param'	, param		, ...
					'cores'	, nCore		, ...
					'force'	, false		  ...
					);

%construct the DC patterns
	cPathDC	= Donchin.ConstructDCPatterns(cPathPP,...
				'type'	, 'compute'	, ...
				'param'	, param		, ...
				'cores'	, nCore		, ...
				'force'	, false		  ...
				);

%perform each classification
	res = Donchin.DCClassify(cPathDC,...
			'type'	, 'compute'	, ...
			'cores'	, nCore		, ...
			'force'	, false		  ...
			);
