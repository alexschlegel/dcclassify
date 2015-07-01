function res = DCAnova(cPathDC,varargin)
% Donchin.DCAnova
% 
% Description:	test whether directed connectivity differs between the four
%				task conditions
% 
% Syntax:	res = Donchin.DCAnova(cPathDC,<options>)
% 
% In:
%	cPathDC	- a cell of paths to the DC values constructed by
%			  Donchin.ConstructDCControl
%	<options>:
%		type:		(<required>) the comparison type:
%						'compute':	for compute +/- comparison
%						'task':		for comparison between all 4 tasks
%									during preparatory period
%						'task2':	for comparison between all 4 tasks
%									during preparatory period, with expanded
%									window
%		output:		(<auto>) the output result file path
%		cores:		(1) the number of cores to use
%		force:		(true) true to force dc comparison
% 
% Updated: 2015-06-15
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
	
	opt.force_pre	= unless(opt.force_pre,opt.force);
	
	strPathOut	= unless(opt.output,PathUnsplit(DirAppend(strDirAnalysis,'donchin'),sprintf('dcanova_%s',opt.type),'mat'));
	CreateDirPath(PathGetDir(strPathOut));

%do we need to perform the analysis?
	if ~opt.force  && FileExists(strPathOut)
		res	= load(strPathOut);
		return;
	end

%load the results
	data	= cellfun(@load,cPathDC);
	
	%copy over some info
		res.param	= data(1).param;
	
	%restructure the data
		data	= restruct(data);
	
	%perform the analysis for each DC type and direction
		kLabelU	= unique(cat(1,data.label{:}));
		
		nSubject	= numel(data.label);
		kSubject	= (1:nSubject)';
		
		cType	= {'te';'gc'};
		nType	= numel(cType);
		
		cDirection	= {'forward';'backward'};
		nDirection	= numel(cDirection);
		
		for kT=1:nType
			strType	= cType{kT};
			
			for kD=1:nDirection
				strDirection	= cDirection{kD};
					
				d	= data.(strType).(strDirection);
				
				%get the mean DC for each subject and condition
					%get the means
						d	= arrayfun(@(kL) arrayfun(@(kS) mean(d{kS}(data.label{kS}==kL,:),1),kSubject,'uni',false),kLabelU,'uni',false);
					%get one array for each condition
						d	= cellfun(@(x) cat(1,x{:}),d,'uni',false);
					%get one array for everything
						d	= cat(3,d{:});
					%permute to nSubject x nCondition x nWindow
						d	= permute(d,[1 3 2]);
				
				%grand means and standard errors
					s.m		= permute(squeeze(mean(d,1)),[2 1]);
					s.se	= permute(squeeze(stderr(d,[],1)),[2 1]);
				
				%perform an anova for each window
					nWindow	= size(d,3);
					kWindow	= (1:nWindow)';
					
					[p,table,stats]	= arrayfun(@(k) anova1(d(:,:,k),[],'off'),kWindow,'uni',false);
					
					s.F		= cellfun(@(t) t{2,5},table);
					s.df	= cellfun(@(t) [t{3,3} t{2,3}],table,'uni',false);
					s.df	= cat(1,s.df{:});
					s.p		= cellfun(@(t) t{2,6},table);
				
				res.(strType).(strDirection)	= s;
			end
		end

%save the results
	save(strPathOut,'-struct','res');
