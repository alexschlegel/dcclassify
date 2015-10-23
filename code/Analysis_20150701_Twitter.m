% Analysis_20150701_Twitter
% 
% Description:	analyze the 2016 republican candidate twitter data
% 
% Updated: 2015-10-12
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.
strNameAnalysis	= 'twitter';

strDirOut		= DirAppend(strDirAnalysis,strNameAnalysis);
strDirFigure	= DirAppend(strDirOut,'figure');
CreateDirPath(strDirFigure);

tw	= twt.Twitty;

param	= twt.Param('declared',true);

%get the candidate user ids
	cUser	= cat(1,param.candidate.user{:});
	
	candidate	= twt.GetUserInfo(tw,cUser);
	id			= candidate.id;
	
	nCandidate		= numel(param.candidate.user);
	nUserCandidate	= cellfun(@numel,param.candidate.user);
	kCandidate		= arrayfun(@(kc,n) repmat(kc,[n 1]),(1:nCandidate)',nUserCandidate,'uni',false);
	kCandidate		= cat(1,kCandidate{:});

%get the follower set and follower set tweets
	follower	= twt.GetFollowerSet(tw,param.candidate.index);
	tweet		= twt.GetFollowerSetTweets(tw,param.candidate.index);
	
	%1744 followers
	nFollower	= numel(follower.id);

%compile into a struct
	%construct blank structs for the no-tweet followers
		bNonBlank	= cellfun(@(x) ~isequal(x,struct),tweet);
		kNonBlank	= find(bNonBlank,1);
		cField		= fieldnames(tweet{kNonBlank});
		sBlank		= dealstruct(cField{:},[]);
		
		tweet(~bNonBlank)	= {sBlank};
	
	%restruct it
		tweet	= restruct(tweet);

%remove followers with no tweets
	nTweetFollower	= cellfun(@numel,tweet.id);
	bTweeted		= nTweetFollower~=0;
	
	tweet		= structfun2(@(x) x(bTweeted),tweet);
	follower	= structfun2(@(x) x(bTweeted),follower);
	
	%1696 tweeting followers
	nFollower	= numel(follower.id);

%remove tweets that aren't replies to candidates
	tweet	= restruct(tweet);
	
	for kF=1:nFollower
		bReplyCandidate	= ismember(double(tweet(kF).in_reply_to_user_id),candidate.id);
		
		tweet(kF)	= structfun2(@(x) x(bReplyCandidate),tweet(kF));
	end
	
	tweet	= restruct(tweet);

%remove followers who did not reply to any candidate
	nReplyCandidate		= cellfun(@numel,tweet.id);
	bRepliedCandidate	= nReplyCandidate>0;
	
	tweet		= structfun2(@(x) x(bRepliedCandidate),tweet);
	follower	= structfun2(@(x) x(bRepliedCandidate),follower);
	
	%980 replying followers
	nFollower	= numel(follower.id);

%get the candidate index of each tweet
	[~,kTweetUser]	= cellfun(@(id) ismember(double(id),candidate.id),tweet.in_reply_to_user_id,'uni',false);
	
	kTweetCandidate	= cellfun(@(k) kCandidate(k),kTweetUser,'uni',false);

%keep only followers who have replied to at least half of the candidates
	nCandidatesReplied	= cellfun(@(k) numel(unique(k)),kTweetCandidate);
	
	bRepliedWidely	= nCandidatesReplied >= nCandidate/2;
	
	tweet				= structfun2(@(x) x(bRepliedWidely),tweet);
	follower			= structfun2(@(x) x(bRepliedWidely),follower);
	kTweetCandidate		= kTweetCandidate(bRepliedWidely);
	nCandidatesReplied	= nCandidatesReplied(bRepliedWidely);
	
	%214 widely replying followers
	nFollower	= numel(follower.id);

%reduce the space down to the top 50 highest participation followers
	nTweet	= cellfun(@numel,kTweetCandidate);
	
	pIndex	= nTweet;
	
	[pIndexS,kSort]	= sort(pIndex,'descend');
	
	kHighParticipation	= kSort(1:50);
	
	tweet			= structfun2(@(x) x(kHighParticipation),tweet);
	follower		= structfun2(@(x) x(kHighParticipation),follower);
	kTweetCandidate	= kTweetCandidate(kHighParticipation);
	
	%50 high participation followers
	nFollower	= numel(follower.id);

%construct the reply patterns
	%number of replies for each candidate and follower
		kkCandidate	= (1:nCandidate)';
		
		reply	= cellfun(@(k) arrayfun(@(kc) sum(k==kc),kkCandidate),kTweetCandidate,'uni',false);
		reply	= cat(2,reply{:});
	
	%zscore replies (excluding zeros)
		replyZ	= zscore(reply,[],2);
		replyZ	= zscore(replyZ,[],1);
	
	%find the top 10 followers per candidate 
		mn	= min(greatest(reply,10,2),[],2);
		
		replyTop	= double(reply>=repmat(mn,[1 nFollower]));

%political positions
	pos		= structtree2array(param.candidate.position)';
	Dpos	= pdist(pos,'spearman');
%separately
	Dpossep	= structfun2(@(x) pdist(x,'euclidean'),param.candidate.position);
	nPos	= numel(fieldnames(param.candidate.position));
%poll
	poll	= mean(param.candidate.poll,2);
	Dpoll	= pdist(poll,'euclidean');
%prediction market
	pred	= param.candidate.market;
	Dpred	= pdist(pred,'euclidean');
%geographical location
	ll		= [param.candidate.lat param.candidate.lon];
	Dgeo	= pdist(ll,@distLatLong)/1000;
%age
	age		= param.candidate.age;
	Dage	= pdist(age,'euclidean');
%twitter
	D	= pdist(replyZ,'spearman');
%top twitter
	Dtop	= pdist(replyTop,'jaccard');

%combine them
	Dall	= [Dpos; Dpoll; Dpred; Dgeo; Dage; D; Dtop; squeeze(structtree2array(Dpossep))];
	f		= [10; 1; 1/10; 1/250; 1/2.5; 10; 10; ones(nPos,1)];
	
	Dmax							= max(Dall,[],2);
	Dmax([1 5 6 end-nPos+1:end])	= 1;
	
	cName	=	[
					'position'
					'poll'
					'prediction'
					'geography'
					'age'
					'twitter'
					'twittertop'
					fieldnames(param.candidate.position)
				];
	nDist	= numel(cName);

%correlation with twitter DSM
	r	= NaN(nDist,1);
	s	= cell(nDist,1);
	
	for kD=1:nDist
		[r(kD),s{kD}] = corrcoef2(D',Dall(kD,:),'type','spearman');
	end	
	
	s	= restruct(s);

%correlation with twitterTop DSM
	rTop	= NaN(nDist,1);
	sTop	= cell(nDist,1);
	
	for kD=1:nDist
		[rTop(kD),sTop{kD}] = corrcoef2(Dtop',Dall(kD,:),'type','spearman');
	end	
	
	sTop	= restruct(sTop);

%FDR correct
	cFDR	= {'position';'poll';'prediction';'geography';'age'};
	kFDR	= find(ismember(cName,cFDR));
	
	s.pfdr				= NaN(size(s.p));
	[~,s.pfdr(kFDR)]	= fdr(s.p(kFDR),0.05);
	
	sTop.pfdr			= NaN(size(sTop.p));
	[~,sTop.pfdr(kFDR)]	= fdr(sTop.p(kFDR),0.05);

%figures
	for kD=1:nDist
		strName	= cName{kD};
		Dcur	= Dall(kD,:);
		DmaxCur	= Dmax(kD);
		fCur	= f(kD);
		
		%DSM
			DSM	= squareform(Dcur);
			
			%SM	= DmaxCur - DSM;
			%SM(logical(eye(size(SM,1))))	= NaN;
			
			DSM(logical(eye(size(DSM,1))))	= NaN;
			
			%[SMs,kSort]	= spectralreorder(SM);
			%[SMs,kSort]	= SortConfusion(SM);
	
% 			h	= alexplot(SMs,...
% 					'label'		, param.candidate.last_name(kSort)	, ...
% 					'nancol'	, [1 1 1]						, ...
% 					'type'		, 'confusion'					  ...
% 					);
			
			h	= alexplot(DSM,...
					'label'			, param.candidate.last_name	, ...
					'nancol'		, [1 1 1]					, ...
					'tplabel'		, false						, ...
					'scalelabel'	, false						, ...
					'type'			, 'confusion'				  ...
					);
			
			strPathOut	= PathUnsplit(strDirFigure,sprintf('dsm_%s',strName),'png');
			fig2png(gcf,strPathOut);
		%dendrogram
			Z	= linkage(Dcur,'average');
			
			yMin	= floor(min(Z(:,3))*fCur)/fCur;
			yMax	= ceil(max(Z(:,3))*fCur)/fCur;
			
			figure;
			set(gcf,'Position',[0 0 1200 400]);
			[H,T]	= dendrogram(Z,'Labels',param.candidate.last_name);
			
			set(gca,'YLim',[yMin yMax],'YTick',yMin:2/fCur:yMax);
			
			strPathOut	= PathUnsplit(strDirFigure,sprintf('dendrogram_%s',strName),'png');
			fig2png(gcf,strPathOut);
		%MDS
			try
				Y	= mdscale(Dcur,2);
				h	= figure;
				plot(Y(:,1),Y(:,2),'.');
				text(Y(:,1)+.025,Y(:,2),param.candidate.last_name)
				
				strPathOut	= PathUnsplit(strDirFigure,sprintf('mds_%s',strName),'png');
				fig2png(gcf,strPathOut);
			catch me
			end
	end

%save everything
	strPathOut	= PathUnsplit(strDirOut,'result','mat');
	save(strPathOut);
