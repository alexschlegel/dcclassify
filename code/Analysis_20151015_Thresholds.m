% Analysis_20151015_Thresholds
% produce p=0.05 threshold plots for a range of variables. this mainly uses data
% from Bennet's s20150718_plot_thresholds code
strNameAnalysis	= '20151015_thresholds';
strDirOut		= DirAppend(strDirAnalysis,strNameAnalysis);

CreateDirPath(strDirOut);


%add bennet's code to the path
	strDirScratchpad	= DirAppend(strDirCode,'bennet','matlab_lib','scratchpad');
	addpath(strDirScratchpad);

%run the threshold plotting code
	h		= s20150718_plot_thresholds;
	nFigure	= numel(h);

%extract the plot data
	colOI	= [0.75 0 1];
	
	[cVarName,cX,cY,cErr]	= deal(cell(nFigure,1));
	
	for kF=1:nFigure
		hC		= get(h(kF),'Children');
		hA		= hC(2);
		
		sA		= get(hA);
		
		%title
			sTitle			= get(sA.Title);
			res				= regexp(sTitle.String,'^\w+','match');
			cVarName{kF}	= res{1};
		
		%children
			hAC		= sA.Children;
			sC		= arrayfun(@get,hAC,'uni',false);
			
			cType	= cellfun(@(s) s.Type,sC,'uni',false);
			
			sLine	= sC(strcmp(cType,'line'));
			nLine	= numel(sLine);
			nPoint	= cellfun(@(s) numel(s.XData),sLine);
			
			colLine	= cellfun(@(s) s.Color,sLine,'uni',false);
			colLine	= cat(1,colLine{:});
			
			kPlot	= find(nPoint>2 & all(colLine==repmat(colOI,[nLine 1]),2));
			kErr	= find(nPoint==2 & all(colLine==repmat(colOI,[nLine 1]),2));
			
			cX{kF}		= reshape(sLine{kPlot}.XData,[],1);
			cY{kF}		= reshape(sLine{kPlot}.YData,[],1);
			nX			= numel(cX{kF});
			
			sErr	= sLine(kErr);
			xErr	= cellfun(@(s) conditional(isempty(s.XData),NaN,s.XData(1)),sErr);
			yErr	= cellfun(@(s) conditional(isempty(s.YData),[NaN NaN],s.YData),sErr,'uni',false);
			yErr	= cat(1,yErr{:});
			
			cErr{kF}	= NaN(nX,2);
			for kX=1:nX
				kXErr	= find(xErr==cX{kF}(kX));
				if ~isempty(kXErr)
					cErr{kF}(kX,:)	= yErr(kXErr,:);
				end
			end
			
			assert(all(isnan(cY{kF}) | cY{kF}==mean(cErr{kF},2)),'weird error values!');
			cErr{kF}	= cErr{kF}(:,2) - mean(cErr{kF},2);
			
			%interpolate for NaNs
				cY{kF}	= FillMissingData(cY{kF});
	end
	
	%save the plot data
		strPathOut	= PathUnsplit(strDirOut,'result','mat');
		save(strPathOut,'cVarName','cX','cY','cErr');

%plot
	for kF=1:nFigure
		x	= cX{kF};
		y	= cY{kF};
		err	= cErr{kF};
		
		switch cVarName{kF}
			case 'nRun'
				strY	= 'runs';
			case 'nSubject'
				strY	= 'subjects';
			case 'nRepBlock'
				strY	= 'samples per C*';
				
				%translate into number of data points (nData == nTBlock*nRepBlock)
					y	= y * 10; %default of nTBlock=10
			case 'nTBlock'
				strY	= 'samples per C*';
				
				%translate into number of data points (nData == nTBlock*nRepBlock)
					y	= y * 5; %default of nRepBlock=5
			case 'WStrength'
				strY	= 'causal strength';
			otherwise
				error('huh?');
		end
		
		ha	= alexplot(x,y,...
				'error'			, err			, ...
				'xlabel'		, 'SNR'			, ...
				'ylabel'		, strY			, ...
				'errortype'		, 'bar'			, ...
				'errorcolor'	, 0.75*[1 1 1]	, ...
				'color'			, [0 0 0]		  ...
				);
		
		strPathOut	= PathUnsplit(strDirOut,sprintf('%s_v_snr',lower(cVarName{kF})),'png');
		fig2png(ha.hF,strPathOut);
	end


%show that nTBlock doesn't matter
	%get a highly factorizable number
		nData	= 2*2*3*5; %60
	%find the corresponding SNR cutoff
		kF		= find(strcmp(cVarName,'nTBlock'));
		nTBlock	= nData/5;
		yDiff	= abs(cY{kF} - nTBlock);
		kY		= find(yDiff == min(yDiff),1);
		SNRmin	= cX{kF}(kY);
		SNR		= max(SNRmin,0.3);
	
	%test the p-value for a range of nTBlocks
		xFactor	= (1:nData)';
		bUse	= (nData./xFactor) == floor(nData./xFactor);
		xFactor	= xFactor(bUse);
		nTBlock	= xFactor;
		
		nTest		= numel(nTBlock);
		nRep		= 30;
		
		strDirSave	= DirAppend(strDirOut,'ntblock_save');
		CreateDirPath(strDirSave);
		
		[b,nCore,pool]	= MATLABPoolOpen(6);
		
		cSummary	= cell(nTest,1);
		parfor kT=1:nTest
			disp(sprintf('start %02d',kT));
			
			cSummary{kT}	= cell(nRep,1);
			
			nTBlockCur		= nTBlock(kT);
			nRepBlockCur	= nData/nTBlockCur;
			
			rng2(101181);
				
			for kR=1:nRep
				strPathSave	= PathUnsplit(strDirSave,sprintf('%02d_%02d',kT,kR),'mat');
				if FileExists(strPathSave)
					disp(sprintf('   start %02d %02d (loading)',kT,kR));
					
					cSummary{kT}{kR}	= MATLoad(strPathSave,'summary','error',true);
				else
					disp(sprintf('   start %02d %02d (computing)',kT,kR));
					
					%make a Pipeline object
						pipe	= Pipeline(...
									'nofigures'	, true			, ...
									'progress'	, false			, ...
									'seed'		, false			, ...
									'nSubject'	, 15			, ...
									'nSigCause'	, 10			, ...
									'nSig'		, 100			, ...
									'nVoxel'	, 100			, ...
									'SNR'		, 0.3			, ...
									'WStrength'	, 0.5			, ...
									'WFullness'	, 0.25			, ...
									'CRecur'	, 0				, ...
									'nTBlock'	, nTBlockCur	, ...
									'nTRest'	, 5				, ...
									'nRepBlock'	, nRepBlockCur	, ...
									'nRun'		, 10			, ...
									'HRF'		, false			, ...
									'analysis'	, 'alex'		  ...
									);
					%run the simulation
						cSummary{kT}{kR}	= pipe.simulateAllSubjects;
					
					MATSave(strPathSave,'summary',cSummary{kT}{kR});
				end
				
				disp(sprintf('   end %02d %02d',kT,kR));
			end
			
			disp(sprintf('end %02d',kT));
		end
		
		MATLABPoolClose(pool);
		
	%compile the results
		acc	= cellfun(@(c) cellfun(@(s) s.alex.meanAccAllSubj,c),cSummary,'uni',false);
		t	= cellfun(@(c) cellfun(@(s) s.alex.stats.tstat,c),cSummary,'uni',false);
		p	= cellfun(@(c) cellfun(@(s) s.alex.p,c),cSummary,'uni',false);
		
		allAcc	= cat(2,acc{:});
		
		mAcc	= cellfun(@mean,acc);
		seAcc	= cellfun(@stderr,acc);
	
	%save
		strPathOut	= PathUnsplit(strDirOut,'result_ntblock','mat');
		save(strPathOut,'cSummary','acc','t','p','allAcc','mAcc','seAcc');
	
	%test for linear relationship
		nTBlockRep	= repmat(nTBlock',[nRep 1]);
		
		Y	= reshape(allAcc,[],1);
		X	= [reshape(nTBlockRep,[],1) ones(nRep*nTest,1)];
		
		[B,Bint,R,Rint,stats]	= regress(Y,X);
		FRegress				= stats(2);
		pRegress				= stats(3);
		
		%for DOF values
			statLR	= regstats(Y,X(:,1),'linear','fstat');
		
		%just for fun
			[pAnova,anovatab,stats]	= anova1(allAcc,[],'off');
			FAnova					= anovatab{2,5};
			
			[r,stats]	= corrcoef2(Y,reshape(nTBlockRep,1,[]),'twotail',true);
			pCorr		= stats.p;
			TCorr		= stats.t;
			FCorr		= TCorr^2;
			
	%plot
		nBar	= numel(mAcc);
		col		= repmat(0.5,[nBar 3]);
		
		cLabel	= arrayfun(@num2str,nTBlock,'uni',false);
		
		h	= alexplot(100*mAcc',...
				'error'				, 100*seAcc'			, ...
				'sig'				, pRegress				, ...
				'shownsig'			, true					, ...
				'dimnsig'			, false					, ...
				'ymin'				, 70					, ...
				'ymax'				, 80					, ...
				'xlabel'			, 'samples per block'	, ...
				'ylabel'			, 'Accuracy (%)'		, ...
				'barlabel'			, cLabel				, ...
				'barlabellocation'	, 0						, ...
				'color'				, col					, ...
				'errortype'			, 'bar'					, ...
				'w'					, 600					, ...
				'h'					, 300					, ...
				'type'				, 'bar'					  ...
				);
		
		strPathOut	= PathUnsplit(strDirOut,'ntblock','png');
		fig2png(h.hF,strPathOut);
