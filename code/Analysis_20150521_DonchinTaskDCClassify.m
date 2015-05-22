% Analysis_20150521_DonchinTaskDCClassify
% 
% Description:	use the DC Classification method to classify between the four
%				Donchin conditions during the pre-imperative period. we will try
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

%preprocess the data
	cPathPP		= Donchin.PreprocessData(cPathEEG,...
					'type'	, 'task'	, ...
					'param'	, param		, ...
					'cores'	, nCore		, ...
					'force'	, false		  ...
					);

%construct the DC patterns
	cPathDC	= Donchin.ConstructDCPatterns(cPathPP,...
				'type'	, 'task'	, ... 
				'param'	, param		, ...
				'cores'	, nCore		, ...
				'force'	, false		  ...
				);

%perform each classification
	res = Donchin.DCClassify(cPathDC,...
			'type'	, 'task'	, ...
			'cores'	, nCore		, ...
			'force'	, false		  ...
			);
	