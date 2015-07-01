% Analysis_20150610_DonchinTaskControlDC
% 
% Description:	test whether there are differences in the directed connectivity
%				between the four tasks just using Lizier's and Seth's methods
%				at the timepoints from the task2 DC classification
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

%construct the control DCs
	switch computername
		case 'ebbinghaus'
			kPath	= 1:3;
		case 'ramonycajal'
			kPath	= 4:6;
		case 'wertheimer'
			kPath	= 7:numel(cPathPP);
		otherwise
			warning('unknown computer');
			kPath	= 1:numel(cPathPP);
	end
	
	status(sprintf('%s processing %s',computername,join(kPath,',')));
	
	cPathPPSub	= cPathPP(kPath);
	
	cPathDC	= Donchin.ConstructDCControl(cPathPPSub,...
				'type'	, 'task2'	, ... 
				'param'	, param		, ...
				'cores'	, nCore		, ...
				'force'	, false		  ...
				);

%test the DCs
	res	= Donchin.DCAnova(cPathDC,...
				'type'	, 'task2'	, ... 
				'param'	, param		, ...
				'cores'	, nCore		, ...
				'force'	, false		  ...
				);
