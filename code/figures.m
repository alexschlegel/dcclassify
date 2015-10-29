% Description:	figure code
% 
% Updated: 2015-07-13
% Copyright 2015 Alex Schlegel (schlegel@gmail.com).  This work is licensed
% under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported
% License.

strDirOut	= DirAppend(strDirBase,'figures');


%pattern examples
	strDirFig	= DirAppend(strDirOut,'schematic','patterns');
	CreateDirPath(strDirFig);
	
	nFeature	= 13;
	nPattern	= 9;
	
	patA	= randn(nFeature,1);
	patB	= randn(nFeature,1);
	
	noise	= 0.75;
	
	pat					= normalize([repmat([patA patB],[1 floor(nPattern/2)]) conditional(isodd(nPattern),patA,[])] + noise*randn(nFeature,nPattern));
	pat(end-2:end-1,:)	= 1;
	
	for kP=1:nPattern
		strPathOut	= PathUnsplit(strDirFig,sprintf('pat_%02d',kP),'bmp');
		imwrite(pat(:,kP),strPathOut);
	end

%values for fmri connectivity results
	strDirFig	= DirAppend(strDirOut,'gridop');
	
	confM	= [4 2 1 1; 2 4 1 1; 1 1 4 2; 1 1 2 4];
	
	ptMin	= 1;
	ptMax	= 8;
	
	%all 80 data sets are included, first 40 are the first session
		strPathResult	= '/home/alex/studies/mwlearn/analysis/20150320_roidcmvpa/result.mat';
		res				= MATLoad(strPathResult,'res');
		
		cKData		=	{
							1:40
							41:80
						};
		nSession	= numel(cKData);
		
	%analyze each session
		for kS=1:nSession
			kData	= cKData{kS};
			
			confS	= res.shape.result.allway.confusion(:,:,:,kData);
			confO	= res.operation.result.allway.confusion(:,:,:,kData);
			sz		= num2cell(size(confS));
			
			cMaskS	= res.shape.mask;
			cMaskO	= res.operation.mask;
			
			%correlations
				[rS,statS]	= corrcoef2(reshape(confM,[],1),permute(reshape(confS,[],sz{3:4}),[2 3 1]));
				[rO,statO]	= corrcoef2(reshape(confM,[],1),permute(reshape(confO,[],sz{3:4}),[2 3 1]));
			%t-test comparing correlations to 0
				zS	= statS.z;
				zO	= statO.z;
				
				%~ %keep only the tests that were significant in the first session
					%~ if kS>1
						%~ zS	= zS(stat(1).shape.hfdr,:);
						%~ zO	= zO(stat(1).operation.hfdr,:);
						%~ 
						%~ cMaskS	= cMaskS(stat(1).shape.hfdr,:);
						%~ cMaskO	= cMaskO(stat(1).operation.hfdr,:);
					%~ end
				
				[hS,pS,ciS,tstatS]	= ttest(zS,0,0.05,'right',2);
				hS					= logical(hS);
				
				[hO,pO,ciO,tstatO]	= ttest(zO,0,0.05,'right',2);
				hO					= logical(hO);
			
			%t-extrema
				if kS==1
					tMin	= min([tstatS.tstat(hS); tstatO.tstat(hO)]);
					tMax	= max([tstatS.tstat(hS); tstatO.tstat(hO)]);
				end
			
			%fdr correct
				[~,pfdrS]	= fdr(pS,0.05);
				hfdrS		= pfdrS<=0.05;
				
				[~,pfdrO]	= fdr(pO,0.05);
				hfdrO		= pfdrO<=0.05;
			
			%compile the results
				stat(kS).shape.mask		= cMaskS;
				stat(kS).shape.h		= hS;
				stat(kS).shape.hfdr		= hfdrS;
				stat(kS).shape.t		= tstatS.tstat;
				stat(kS).shape.z		= mean(zS,2);
				stat(kS).shape.thick	= MapValue(tstatS.tstat,tMin,tMax,ptMin,ptMax,'constrain',false);
				
				stat(kS).operation.mask		= cMaskO;
				stat(kS).operation.h		= hO;
				stat(kS).operation.hfdr		= hfdrO;
				stat(kS).operation.t		= tstatO.tstat;
				stat(kS).operation.z		= mean(zO,2);
				stat(kS).operation.thick	= MapValue(tstatO.tstat,tMin,tMax,ptMin,ptMax,'constrain',false);
			
			%print the results
				fDisp	= @(s) disp([s.mask(s.h,:) num2cell([s.hfdr(s.h) s.t(s.h) s.thick(s.h)])]);
				
				disp(sprintf('session %d',kS));
				disp('   shape');
				fDisp(stat(kS).shape);
				disp('   operation');
				fDisp(stat(kS).operation);
		end
	
	%test-retest reliability
		z1	= [stat(1).shape.z; stat(1).operation.z];
		z2	= [stat(2).shape.z; stat(2).operation.z];
		
		nShape		= numel(stat(1).shape.z);
		nOperation	= numel(stat(1).operation.z);
		nTotal		= nShape + nOperation;
		
		[rTest,sTest]	= corrcoef2(z1,z2');
		
		xLine	= [min(z1) max(z1)];
		yLine	= polyval([sTest.m sTest.b],xLine);
		
		col	= [repmat([1 0 0],[nShape 1]); repmat([0 0.5 1],[nOperation 1]); 0 0 0];
		
		cMarker	= [repmat({'.'},[nTotal 1]); 'none'];
		cLine	= [repmat({'none'},[nTotal 1]); '-'];
		
		step	= 0.05;
		xmin	= floor(min(z1)/step)*step;
		xmax	= ceil(max(z1)/step)*step;
		ymin	= floor(min(z2)/step)*step;
		ymax	= ceil(max(z2)/step)*step;
		
		h	= alexplot([num2cell(z1); xLine],[num2cell(z2); yLine],...
				'xlabel'			, 'Z(r) (1st test)'	, ...
				'ylabel'			, 'Z(r) (2nd test)'	, ...
				'xmin'				, xmin				, ...
				'xmax'				, xmax				, ...
				'ymin'				, ymin				, ...
				'ymax'				, ymax				, ...
				'color'				, col				, ...
				'marker'			, cMarker			, ...
				'markersize'		, 25				, ...
				'linestyle'			, cLine				  ...
				);
		
		strPathOut	= PathUnsplit(strDirFig,'testretest','png');
		fig2png(h.hF,strPathOut);
		

%donchin figures
	strDirFig	= DirAppend(strDirOut,'donchin');
	
	cDirection	= {'forward';'backward'};
	nDirection	= numel(cDirection);
	
	%window by lag DC classification
		strDirRes	= DirAppend(strDirAnalysis,'donchin');
		strPathRes	= PathUnsplit(strDirRes,'dcclassify_task2','mat');
		
		res		= load(strPathRes);
		param	= Donchin.GetParameters;
		
		t	= (res.param.t.start{1} + param.task2.t.window.start);
		kT	= (1:numel(t))';
		nT	= numel(kT);
		
		lag		= 1000*res.param.t.lag{1};
		kLag	= (2:numel(lag))';
		nLag	= numel(kLag);
		
		col	= [
				1	1	1
				0.5	0.5	0.5
				0	0	0.5
				1	0.5	0
				1	1	0
				];
		lut	= MakeLUT(col,100);
		
		for kD=1:nDirection
			strDirection	= cDirection{kD};
			
			d	= 100*res.(strDirection).gmean(kT,kLag);
			
			hF	= figure;
			hA	= axes;
			hI	= imagesc(t(kT),lag(kLag),d');
			
			set(hF,'position',[0 0 600 300]);
			set(hA,'ydir','normal','box','off');
			caxis([35 45])
			colormap(lut)
			
			xlabel('window start (s)')
			ylabel('lag (ms)');
			
			strPathOut	= PathUnsplit(strDirFig,sprintf('dcclassify_%s',strDirection),'png');
			fig2png(hF,strPathOut);
		end
		
		%lut
			[hF,im]	= ShowPalette(lut);
			
			strPathOut	= PathUnsplit(strDirFig,'dcclassify_lut','png');
			imwrite(im,strPathOut);
			
			close(hF);
	
	%timecourses
		kLagUse	= 5;	%see line 114 of Donchin.ConstructDCControl
		
% 		strPathResMVPA	= PathUnsplit(strDirRes,'electrodeclassify_task2','mat');
% 		resMVPA	= load(strPathResMVPA);
		
		strPathResANOVA	= PathUnsplit(strDirRes,'dcanova_task2','mat');
		resANOVA	= load(strPathResANOVA);
		
		cDCType	= {'gc';'te'};
		nDCType	= numel(cDCType);
		
		cTask	=	{
						'go'
						'go/no-go'
						'predict'
						'compute'
					};
		nTask	= numel(cTask);
		
		for kD=1:nDirection
			strDirection	= cDirection{kD};
			
			%dc classification
				yMin	= 30;
				yMax	= 45;
				
				x	= 	{
							100*res.(strDirection).gmean(:,kLagUse)
						};
				err	=	{
							100*res.(strDirection).gse(:,kLagUse)
						};
				
				col	= [0 0 0.5];
			
				h	= alexplot(t,x,...
						'error'		, err					, ...
						'xlabel'	, 'window start (s)'	, ...
						'ylabel'	, 'accuracy (%)'		, ...
						'ymin'		, yMin					, ...
						'ymax'		, yMax					, ...
						'color'		, col					, ...
						'errortype'	, 'bar'					, ...
						'linewidth'	, 3						, ...
						'pgridy'	, 4						  ...
						);
				
				cellfun(@(he) set(he,'LineWidth',1),ForceCell(h.hE));
				
				set(h.hF,'position',[0 0 400 300]);
				
				strPathOut	= PathUnsplit(strDirFig,sprintf('plot_dcclassify_%s',strDirection),'png');
				fig2png(h.hF,strPathOut);
			
			%univariate DC
				for kT=1:nDCType
					strDCType	= cDCType{kT};
					
					s	= resANOVA.(strDCType).(strDirection);
					
					f		= 10;
					yMin	= floor(min(s.m(:)-s.se(:))*f)/f;
					yMax	= ceil(max(s.m(:)+s.se(:))*f)/f;
					
					col	=	[
								0	0.25	0
								0	2/3		0
								0	1		0
								0.8	1		0
							];
					
					x	= mat2cell(s.m,size(s.m,1),ones(nTask,1));
					err	= mat2cell(s.se,size(s.se,1),ones(nTask,1));
					
					h	= alexplot(t,x,...
							'error'		, err					, ...
							'xlabel'	, 'window start (s)'	, ...
							'ylabel'	, upper(strDCType)		, ...
							'legend'	, cTask					, ...
							'ymin'		, yMin					, ...
							'ymax'		, yMax					, ...
							'errortype'	, 'bar'					, ...
							'linewidth'	, 3						, ...
							'pgridy'	, 1						, ...
							'color'		, col					  ...
							);
					
					cellfun(@(he) set(he,'LineWidth',1),h.hE);
					
					set(h.hF,'position',[0 0 400 150]);
					
					strPathOut	= PathUnsplit(strDirFig,sprintf('plot_dc_%s_%s',strDCType,strDirection),'png');
					fig2png(h.hF,strPathOut);
				end
			
			%p-values
				x	=	cellfun(@log10,{
							res.(strDirection).p(:,kLagUse)
							resANOVA.te.(strDirection).p
							resANOVA.gc.(strDirection).p
						},'uni',false);
				
				col	=	[
							0 0 0.5
							0.375 0.75 0.375
							0.5 1 0.5
						];
				
				cLegend	= {'GC SVM','GC ANOVA','TE ANOVA'};
				
				%anything less negative than this and the bottom tick disappears 
					%yTickMin	= -0.0024678086;
					%yTick		= yTickMin*10.^(4:-1:0)';
					
					%yTickRef	= log10(0.05);
					%yTick		= yTickRef*10.^(1:-1:-2)';
					
					yTick	= log10([10e-8; 0.05; 0.75; 0.98]);
				
				h	= alexplot(t,x,...
						'xlabel'	, 'window start (s)'	, ...
						'ylabel'	, 'p'					, ...
						'legend'	, cLegend				, ...
						'ymin'		, yTick(1)				, ...
						'ymax'		, 0						, ...
						'hline'		, log10(0.05)			, ...
						'color'		, col					, ...
						'yreverse'	, true					  ...
						);
				
				pTick		= 10.^yTick;
				yTickLabel	= num2str(sigfig(pTick,2));
				set(h.hA,'yscale','log','YTick',yTick,'YTickLabel',yTickLabel);
				
				set(h.hF,'position',[0 0 400 300]);
				
				%plot2svg breaks with log scaled plots
				%strPathOut	= PathUnsplit(strDirFig,sprintf('plot_p_%s',strDirection),'png');
				%fig2png(h.hF);
				
				strPathOut	= PathUnsplit(strDirFig,sprintf('plot_p_%s',strDirection),'eps');
				saveas(h.hF,strPathOut);
				close(h.hF);
		end
	
	%plot all p-values together so we get the same scale
		x	=	cellfun(@log10,{
					res.forward.p(:,kLagUse)
					resANOVA.te.forward.p
					resANOVA.gc.forward.p
					res.backward.p(:,kLagUse)
					resANOVA.te.backward.p
					resANOVA.gc.backward.p
				},'uni',false);
		
		col	=	[
					0 0 0.5
					0.375 0.75 0.375
					0.5 1 0.5
				];
		col	= [col; col/2];
		
		yTick	= log10([10e-8; 0.05; 0.75; 0.98]);
		
		h	= alexplot(t,x,...
				'ymin'		, yTick(1)				, ...
				'ymax'		, log10(0.999)			, ...
				'hline'		, log10(0.05)			, ...
				'color'		, col					, ...
				'yreverse'	, true					  ...
				);
		
		pTick		= 10.^yTick;
		yTickLabel	= num2str(sigfig(pTick,2));
		set(h.hA,'yscale','log','YTick',yTick,'YTickLabel',yTickLabel);
		
		set(h.hF,'position',[0 0 400 300]);
		
		strPathOut	= PathUnsplit(strDirFig,'plot_p_both','eps');
		saveas(h.hF,strPathOut);
		close(h.hF);

%twitter
	strDirFig	= DirAppend(strDirOut,'twitter');
	
	%run the analysis code up through line 108
	
	strExample	= 'CarlyFiorina';
	kExample	= find(strcmp(candidate.user,strExample));
	idExample	= candidate.id(kExample);
	
	kReply		= cellfun(@(id,idStatus) find(id==idExample & idStatus~=0),tweet.in_reply_to_user_id,tweet.in_reply_to_status_id,'uni',false);
	kReplied	= find(~cellfun(@isempty,kReply));
	nReplied	= numel(kReplied);
	
	%lut
		[hF,im]	= ShowPalette(str2rgb('default'));
		close(hF);
		
		strPathOut	= PathUnsplit(strDirFig,'lut','png');
		imwrite(im,strPathOut);
	
	%find a good example
		for kR=1:nReplied
			kRCur	= kReplied(kR);
			
			nReply	= numel(kReply(kRCur));
			
			for kRR=1:nReply
				kRRCur	= kReply{kRCur}(kRR);
				
				disp(sprintf('%02d-%02d: %s',kRCur,kRRCur,tweet.text{kRCur}{kRRCur}));
			end
		end
		
		%kFollower	= 81;
		%kResponse	= 2;
		
		kFollower	= 58;
		kResponse	= 3;
		
		%kFollower	= 77;
		%kResponse	= 24;
		
		idOrig			= tweet.in_reply_to_status_id{kFollower}(kResponse);
		response		= tw.showStatus(num2str(tweet.id{kFollower}(kResponse)));
		strFollowerUser	= response{1}.user.screen_name;
		strFollowerName	= response{1}.user.name;
		tResponse		= response{1}.created_at;
		urlFollower		= response{1}.user.profile_image_url;
		strResponse		= tweet.text{kFollower}{kResponse};
		
		status				= tw.showStatus(num2str(idOrig));
		strCandidateUser	= status{1}.user.screen_name;
		strCandidateName	= status{1}.user.name;
		tStatus				= status{1}.created_at;
		urlCandidate		= status{1}.user.profile_image_url;
		strStatus			= status{1}.text;
		
		disp(' ');
		disp(sprintf('%s/%s/%s: %s',tStatus,strCandidateUser,strCandidateName,strStatus));
		disp(sprintf('%s/%s/%s: %s',tResponse,strFollowerUser,strFollowerName,strResponse));

	%dendrogram
		