% Analysis_20151013_Simulation
% run the simulation described in the simulation figure (Fig. 3)
strNameAnalysis	= '20151013_simulation';
strDirOut		= DirAppend(strDirAnalysis,strNameAnalysis);

CreateDirPath(strDirOut);


%add bennet's code to the path
	strDirScratchpad	= DirAppend(strDirCode,'bennet','matlab_lib','scratchpad');
	addpath(strDirScratchpad);

%make a Pipeline object
	rng2(101181);
	
	nSubject	= 15;
	nRun		= 10;
	nVoxel		= 100;
	
	pipe	= Pipeline(...
				'seed'		, false		, ...
				'nSubject'	, nSubject	, ...
				'nSigCause'	, 10		, ...
				'nSig'		, 100		, ...
				'nVoxel'	, nVoxel	, ...
				'SNR'		, 0.2		, ...
				'WStrength'	, 0.5		, ...
				'WFullness'	, 0.25		, ...
				'CRecur'	, 0			, ...
				'nTBlock'	, 10		, ...
				'nTRest'	, 5			, ...
				'nRepBlock'	, 5			, ...
				'nRun'		, nRun		, ...
				'HRF'		, false		, ...
				'analysis'	, 'total'	  ...
				);

%generate data for the plots (from simulateSubject)
	doDebug	= false;
	
	%block design
		[block,target]		= pipe.generateBlockDesign(doDebug);
	
	%causality matrices
		sW					= pipe.generateStructOfWs(doDebug);
	
	%signals
		%functional
			rng2(101181);
			[S,D]	= pipe.generateFunctionalSignals(block,target,sW,doDebug);
		%mixed
			rng2(101181);
			[Sv,Dv]	= pipe.generateSignalsWithOptions(block,target,sW,doDebug);
		%unmixed
			nTRun	= size(Sv,1);
			nT		= nTRun*nRun;

			[SCoeff,Su]	= pca(reshape(Sv,nT,nVoxel));
			Su			= reshape(Su,nTRun,nRun,nVoxel);
			
			[DCoeff,Du]	= pca(reshape(Dv,nT,nVoxel));
			Du			= reshape(Du,nTRun,nRun,nVoxel);
	
	%Wstars
		WStarA	= pipe.calculateW_stars(target,Su,Du,'A');
		WStarB	= pipe.calculateW_stars(target,Su,Du,'B');

%perform the group-wise analyses
	rng2(11685);
	
	pipe	= Pipeline(...
				'seed'		, false		, ...
				'nSubject'	, nSubject	, ...
				'nSigCause'	, 10		, ...
				'nSig'		, 100		, ...
				'nVoxel'	, nVoxel	, ...
				'SNR'		, 0.3		, ...
				'WStrength'	, 0.5		, ...
				'WFullness'	, 0.25		, ...
				'CRecur'	, 0			, ...
				'nTBlock'	, 10		, ...
				'nTRest'	, 5			, ...
				'nRepBlock'	, 5			, ...
				'nRun'		, nRun		, ...
				'HRF'		, false		, ...
				'analysis'	, 'total'	  ...
				);
	
	d	= struct;
	
	progress('action','init','total',nSubject,'label','simulating subjects');
	for kS=1:nSubject
		%from simulateSubject
			d(kS).W						= pipe.generateStructOfWs(doDebug);
			[d(kS).block,d(kS).target]	= pipe.generateBlockDesign(doDebug);
			[d(kS).S,d(kS).D]			= pipe.generateSignalsWithOptions(d(kS).block,d(kS).target,d(kS).W,doDebug);
			d(kS).stat					= pipe.analyzeTestSignals(d(kS).block,d(kS).target,d(kS).S,d(kS).D,doDebug);
		%additional stats
			%univariate
				SCat	= reshape(d(kS).S,[],nVoxel);
				DCat	= reshape(d(kS).D,[],nVoxel);
				
				targetCat	= cat(1,d(kS).target{:});
				
				kA		= find(strcmp(targetCat,'A'));
				kB		= find(strcmp(targetCat,'B'));
				kBlank	= find(strcmp(targetCat,'Blank'));
				
				mSBlank	= mean(reshape(SCat(kBlank,:),[],1));
				mDBlank	= mean(reshape(DCat(kBlank,:),[],1));
				
				d(kS).stat.mean.S.A	= mean(reshape(SCat(kA,:),[],1)) - mSBlank;
				d(kS).stat.mean.S.B	= mean(reshape(SCat(kB,:),[],1)) - mSBlank;
				d(kS).stat.mean.D.A	= mean(reshape(DCat(kA,:),[],1)) - mDBlank;
				d(kS).stat.mean.D.B	= mean(reshape(DCat(kB,:),[],1)) - mDBlank;
			%multivariate classification
				%construct the patterns
					[patS,patD,lbl]	= deal(cell(nRun,1));
					for kR=1:nRun
						kA	= find(strcmp(d(kS).target{kR},'A'));
						kB	= find(strcmp(d(kS).target{kR},'B'));
						
						%source
							patA	= squeeze(mean(d(kS).S(kA,kR,:),1));
							patB	= squeeze(mean(d(kS).S(kB,kR,:),1));
						
							patS{kR}	= [patA'; patB'];
						%destination
							patA	= squeeze(mean(d(kS).D(kA,kR,:),1));
							patB	= squeeze(mean(d(kS).D(kB,kR,:),1));
						
							patD{kR}	= [patA'; patB'];
						
						lbl{kR}	= {'A'; 'B'};
					end
					
					patS	= cat(1,patS{:});
					patD	= cat(1,patD{:});
					lbl		= cat(1,lbl{:});
				%classify
					P	= cvpartition(nRun,'LeaveOut');
					
					[HS,HD,N]	= deal(0);
					for kP=1:P.NumTestSets
						bTrain	= reshape(repmat(P.training(kP),[1 2])',[],1);
						bTest	= ~bTrain;
						
						%source
							sSVM	= svmtrain(patS(bTrain,:),lbl(bTrain));
							pred	= svmclassify(sSVM,patS(bTest,:));
							HS		= HS + sum(strcmp(pred,lbl(bTest)));
							
							sSVM	= svmtrain(patD(bTrain,:),lbl(bTrain));
							pred	= svmclassify(sSVM,patD(bTest,:));
							HD		= HD + sum(strcmp(pred,lbl(bTest)));
							
							N		= N + sum(bTest);
					end
					
					d(kS).stat.roiclassify.accS	= HS/N;
					d(kS).stat.roiclassify.accD	= HD/N;
		
		progress;
	end
	
	%group stats
		kSubject	= (1:nSubject)';
		
		%DC Classify
			acc	= arrayfun(@(k) d(k).stat.alexResult.accSubj,kSubject);
			
			[h,p,ci,st]	= ttest(acc,0.5,'tail','right');
				
			stat.dcclassify	= struct(...
								'mean'		, mean(acc)	, ...
								'stderr'	, stderr(acc)	, ...
								'df'		, st.df			, ...
								't'			, st.tstat		, ...
								'p'			, p				  ...
								);
		
		%TE
			teA	= arrayfun(@(k) d(k).stat.lizierTEs(1),kSubject);
			teB	= arrayfun(@(k) d(k).stat.lizierTEs(2),kSubject);
			
			[h,p,ci,st]	= ttest(teA,teB);
			
			stat.te	= struct(...
						'mean'		, struct('A',mean(teA),'B',mean(teB))		, ...
						'stderr'	, struct('A',stderr(teA),'B',stderr(teB))	, ...
						'df'		, st.df										, ...
						't'			, st.tstat									, ...
						'p'			, p											  ...
						);
		
		%GC
			gcA	= arrayfun(@(k) d(k).stat.sethGCs(1),kSubject);
			gcB	= arrayfun(@(k) d(k).stat.sethGCs(2),kSubject);
			
			[h,p,ci,st]	= ttest(gcA,gcB);
			
			stat.gc	= struct(...
						'mean'		, struct('A',mean(gcA),'B',mean(gcB))		, ...
						'stderr'	, struct('A',stderr(gcA),'B',stderr(gcB))	, ...
						'df'		, st.df										, ...
						't'			, st.tstat									, ...
						'p'			, p											  ...
						);
		
		%univariate
			mSA	= arrayfun(@(k) d(k).stat.mean.S.A,kSubject);
			mSB	= arrayfun(@(k) d(k).stat.mean.S.B,kSubject);
			mDA	= arrayfun(@(k) d(k).stat.mean.D.A,kSubject);
			mDB	= arrayfun(@(k) d(k).stat.mean.D.B,kSubject);
			
			%S
				[h,p,ci,st]	= ttest(mSA,mSB);
				
				stat.univariate.S	= struct(...
										'mean'		, struct('A',mean(mSA),'B',mean(mSB))		, ...
										'stderr'	, struct('A',stderr(mSA),'B',stderr(mSB))	, ...
										'df'		, st.df										, ...
										't'			, st.tstat									, ...
										'p'			, p											  ...
										);
			
			%D
				[h,p,ci,st]	= ttest(mDA,mDB);
				
				stat.univariate.D	= struct(...
										'mean'		, struct('A',mean(mDA),'B',mean(mDB))		, ...
										'stderr'	, struct('A',stderr(mDA),'B',stderr(mDB))	, ...
										'df'		, st.df										, ...
										't'			, st.tstat									, ...
										'p'			, p											  ...
										);
		
		%multivariate
			accS	= arrayfun(@(k) d(k).stat.roiclassify.accS,kSubject);
			accD	= arrayfun(@(k) d(k).stat.roiclassify.accD,kSubject);
			
			%S
				[h,p,ci,st]	= ttest(accS,0.5,'tail','right');
				
				stat.multivariate.S	= struct(...
										'mean'		, mean(accS)	, ...
										'stderr'	, stderr(accS)	, ...
										'df'		, st.df			, ...
										't'			, st.tstat		, ...
										'p'			, p				  ...
										);
			
			%D
				[h,p,ci,st]	= ttest(accD,0.5,'tail','right');
				
				stat.multivariate.D	= struct(...
										'mean'		, mean(accD)	, ...
										'stderr'	, stderr(accD)	, ...
										'df'		, st.df			, ...
										't'			, st.tstat		, ...
										'p'			, p				  ...
										);

%save the results
	save(PathUnsplit(strDirOut,'result','mat'));

%figures
	nTPlot	= 100;
	nSignal	= 5;
	
	colS	= [1 185 1]/255;
	colD	= [0 208 208]/255;
	
	colA	= [190 30 45]/255;
	colB	= [246 146 30]/255;
	
	colSingle	= [1 0 0];
	
	fGetSignal	= @(x) cellfun(@(y,k) normalize(y)/nSignal+(switch2(k,1,0,k)/nSignal),squeeze(mat2cell(x(1:nTPlot,1,1:nSignal),nTPlot,1,ones(nSignal,1))),num2cell((1:nSignal)'),'uni',false);
	fPlotSignal	= @(x,col) alexplot(fGetSignal(x),'color',repmat(col,[nSignal 1]),'axistype','off','h',300,'w',400);
	fPlotMatrix	= @(x,col) get(get(imagesc(1-normalize(x),'Parent',axes('Parent',figure('Position',[0 0 400 400]),'UserData',colormap(MakeLUT([col; 1 1 1],GetInterval(0,1,255).^(2))),'Position',[0 0 1 1])),'Parent'),'Parent');
	fPlotBar	= @(x,err,col,varargin) alexplot(x,'error',err,'color',col,'type','bar','lax',conditional(numel(x)>2,[],0.25),'wax',conditional(numel(x)>2,[],0.7),'h',300,'w',200*conditional(numel(x)>2,2,1),'groupspace',switch2(numel(x),2,0.15,[]),'barspace',switch2(numel(x),2,0.1,[]),'shownsig',true,'dimnsig',false,varargin{:});
	
	fSavePlot	= @(h,name) fig2png(unless(GetFieldPath(h,'hF'),h),PathUnsplit(strDirOut,name,'png'));
	
	%source functional space
		fSavePlot(fPlotSignal(S,colS),'functional_source');
	%destination functional space
		fSavePlot(fPlotSignal(D,colD),'functional_destination');
	%source voxel space
		fSavePlot(fPlotSignal(Sv,colS),'voxel_source');
	%destination voxel space
		fSavePlot(fPlotSignal(Dv,colD),'voxel_destination');
	%source unmixed space
		fSavePlot(fPlotSignal(Su,colS),'unmixed_source');
	%destination unmixed space
		fSavePlot(fPlotSignal(Du,colD),'unmixed_destination');
	
	%causality matrices
		fSavePlot(fPlotMatrix(sW.WA,colA),'CA');
		fSavePlot(fPlotMatrix(sW.WB,colB),'CB');
	
	%Wstars
		for kR=1:nRun
			fSavePlot(fPlotMatrix(WStarA{kR},[0 0 0]),sprintf('Cstar_A_%d',kR));
			fSavePlot(fPlotMatrix(WStarB{kR},[0 0 0]),sprintf('Cstar_B_%d',kR));
		end
	
	%Wstar construction example
		WStarEg			= WStarA{1}(1:6,1:6);
		WStarEg(5,:)	= 0;
		WStarEg(:,5)	= 0;
		
		fSavePlot(fPlotMatrix(WStarEg,[0 0 0]),'Cstar_example');
	
	%analysis results
		fSavePlot(fPlotBar(100*stat.dcclassify.mean,100*stat.dcclassify.stderr,colSingle,'ylabel','accuracy (%)','ymin',40,'ymax',80,'hline',50,'sig',stat.dcclassify.p),'analysis_dcclassify');
		fSavePlot(fPlotBar([stat.te.mean.A stat.te.mean.B],[stat.te.stderr.A stat.te.stderr.B],[colA; colB],'ylabel','TE','sig',stat.te.p),'analysis_te');
		fSavePlot(fPlotBar([stat.gc.mean.A stat.gc.mean.B],[stat.gc.stderr.A stat.gc.stderr.B],[colA; colB],'ymin',28,'ymax',30,'ylabel','GC','sig',stat.gc.p),'analysis_gc');
		fSavePlot(fPlotBar([stat.univariate.S.mean.A stat.univariate.S.mean.B; stat.univariate.D.mean.A stat.univariate.D.mean.B],[stat.univariate.S.stderr.A stat.univariate.S.stderr.B; stat.univariate.D.stderr.A stat.univariate.D.stderr.B],[colA; colB],'ylabel','mean signal','sig',[stat.univariate.S.p; stat.univariate.D.p]),'analysis_univariate');
		fSavePlot(fPlotBar(100*[stat.multivariate.S.mean; stat.multivariate.D.mean],100*[stat.multivariate.S.stderr; stat.multivariate.D.stderr],[colS; colD],'ylabel','accuracy (%)','ymin',40,'ymax',80,'hline',50,'sig',[stat.multivariate.S.p; stat.multivariate.D.p]),'analysis_multivariate');