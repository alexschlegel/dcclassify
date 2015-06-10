function res = RSA(sDC,varargin)
% ECoGCategories.RSA
% 
% Description:	construct DSMs between each picture category for each direction,
%				start time, and lag
% 
% Syntax:	res = ECoGCategories.RSA(sDC,<options>)
% 
% In:
%	sDC	- the DC patterns returned by ECoGCategories.ConstructDCPatterns
%	<options>:
%		dir_out:	(<required>) the output directory
%		force:		(true) true to force pattern construction
% 
% Updated: 2015-06-05
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

%parse the inputs
	opt	= ParseArgs(varargin,...
			'dir_out'	, []	, ...
			'force'		, true	  ...
			);
	
	assert(~isempty(opt.dir_out),'output directory is required');
	
	strPathRSA	= PathUnsplit(opt.dir_out,sprintf('%s-rsa',sDC.param.id),'mat');

%do we need to calculate the DSMs?
	if ~opt.force && FileExists(strPathRSA)
		res	= MATLoad(strPathRSA,'res');
		
		return;
	end

%calculate the DSMs
	res					= struct;
	res.param			= sDC.param;
	res.param.category	= unique(sDC.label);
	
	res.dim	= ['category';'category';sDC.dim(4:5)];
	
	cDirection	= {'forward';'backward'};
	nDirection	= numel(cDirection);
	
	nCategory					= numel(res.param.category);
	[~,~,nTrial,nStart,nLag]	= size(sDC.forward);
	
	progress('action','init','name','direction','total',nDirection,'label','directions');
	for kD=1:nDirection
		res.(cDirection{kD})	= NaN(nCategory,nCategory,nStart,nLag);
		
		dc					= sDC.(cDirection{kD});
		[nSrc,nDst,~,~,~]	= size(dc);
		dc					= reshape(dc,nSrc*nDst,nTrial,nStart,nLag);
		
		progress('action','init','name','start','total',nStart,'label','start times');
		for kS=1:nStart
			for kL=1:nLag
				dcCur	= zscore(dc(:,:,kS,kL),[],2);
				
				dcMean	= cellfun(@(c) reshape(mean(dcCur(:,strcmp(sDC.label,c)),2),1,[]),res.param.category,'uni',false);
				dcMean	= cat(1,dcMean{:});
				
				res.(cDirection{kD})(:,:,kS,kL)	= squareform(pdist(dcMean,'correlation'));
			end
			
			progress('name','start');
		end
		
		progress('name','direction');
	end

%save the data
	MATSave(strPathRSA,'res',res);
