function s = LoadCandidates(varargin)
% twt.LoadCandidates
% 
% Description:	load the candidate information
% 
% Syntax:	s = twt.LoadCandidates(<options>)
%
% In:
% 	<options>:
%		declared:				([]) true to include only declared candidates,
%								false to included only undeclared candidates,
%								empty to include both
%		exclude_by_last_name:	([]) a last name/cell of last names to exclude
% 
% Updated: 2015-06-30
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
global strDirData

%parse the inputs
	opt	= ParseArgs(varargin,...
			'declared'				, []	, ...
			'exclude_by_last_name'	, []	  ...
			);

strDirTwitter	= DirAppend(strDirData,'twitter');
strPathData		= PathUnsplit(strDirTwitter,'candidates','csv');

s	= table2struct(fget(strPathData),'delim','csv');

s.name	= cellfun(@(fn,ln) [fn ' ' ln],s.first_name,s.last_name,'uni',false);
s.user	= cellfun(@(user) split(user,' '),s.user,'uni',false);

nCandidate	= numel(s.name);

s.index	= (1:nCandidate)';

%exclude by declaration status
	bKeep	= true(nCandidate,1);
	
	if ~isempty(opt.declared)
		bKeep	= bKeep & s.declared==opt.declared;
	end
	
	if ~isempty(opt.exclude_by_last_name)
		cExclude	= ForceCell(opt.exclude_by_last_name);
		
		bKeep	= bKeep & ~ismember(lower(s.last_name),lower(cExclude));
	end
	
	s	= restruct(s);
	s	= s(bKeep);
	s	= restruct(s);
