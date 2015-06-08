% Analysis_20150605_ECoGCategoriesDCRSA
% 
% Description:	construct dissimilarity matrices from DC patterns based on the
%				LTG (left temporal cortex) grid in S1's ECoG picture categories
%				data. do this for DC patterns between the anterior/inferior 12
%				electrodes and the posterior/superior 12 electrodes (see pgs.
%				4 and 16 of implant_info.pdf).
% 
% Updated: 2015-06-05
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
nCore	= 12;

strExperiment	= 'ecog_categories';

%output dir
	strDirOut	= DirAppend(strDirBase,'analysis',strExperiment);
	CreateDirPath(strDirOut);

%parameters
	param	= ECoGCategories.GetParameters;

%input data
	cPathData	= FindFiles(DirAppend(strDirData,'ecog_categories','s1'),'^ess\d+\.mat$');
	nData		= numel(cPathData);

%preprocess the data
	s	= ECoGCategories.PreprocessData(cPathData,...
			'param'	, param		, ...
			'force'	, false		  ...
			);

%construct the DC patterns
	s	= ECoGCategories.ConstructDCPatterns(s,...
			'cores'	, nCore	, ...
			'force'	, false	  ...
			);

%perform each classification
	res = ECoGCategories.RSA(s,...
			'dir_out'	, strDirOut	, ...
			'force'		, false		  ...
			);
	