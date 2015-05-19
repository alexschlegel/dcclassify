% Analysis_20150513_DonchinComputeDCClassify
% 
% Description:	use the DC Classification method to classify between addition
%				and subtraction operations in the Compute condition. we will try
%				both posterior->anterior and anterior->posterior DC patterns at
%				a range of lags.
% 
% Updated: 2015-05-13
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
					'param'	, param	, ...
					'cores'	, nCore	, ...
					'force'	, false	  ...
					);
	nSession	= numel(cPathPP);

%construct the DC patterns
	cPathDC	= Donchin.ConstructDCPatterns(cPathPP,...
				'param'	, param	, ...
				'cores'	, nCore	, ...
				'force'	, false	  ...
				);

%perform each classification
	