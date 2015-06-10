% Analysis_20150610_DonchinTaskControlClassify
% 
% Description:	test whether we can classify between the four tasks just using
%				patterns of electrode values at the timepoints from the task2
%				DC classification
% 
% Updated: 2015-06-10
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
					'type'	, 'task2'	, ...
					'param'	, param		, ...
					'cores'	, nCore		, ...
					'force'	, false		  ...
					);

%construct the electrode patterns
	cPathEP	= Donchin.ConstructElectrodePatterns(cPathPP,...
				'type'	, 'task2'	, ... 
				'param'	, param		, ...
				'cores'	, nCore		, ...
				'force'	, false		  ...
				);

%perform each classification
	res = Donchin.EEGClassify(cPathPP,...
			'type'	, 'task2'	, ...
			'cores'	, nCore		, ...
			'force'	, false		  ...
			);
	