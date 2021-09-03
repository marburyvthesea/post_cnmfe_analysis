


%Inputs:
	%frameStart
	%frameFinish

frames_to_analyze = frameStart:frameFinish ;
within_frames_to_analyze = frameStart:frameFinish ;

frameSlicesStart = linspace(1, size(paddedSignalPeaks, 2), 100)

disp('computing jaccard scores')
% changed paddedSignalPeaks variable name in p355 shuffle function to correct scope when loopign over different frame regions 

[~, CellJaccardsFrameSubset, ShuffledCellJaccardsFrameSubset, normlBinnedCellJaccardsFrameSubset, ...
    normlShuffledBinnedCellJaccardsFrameSubset, proximalPairIndicesFrameSubset] = ...
p355_jaccard_shuffle(paddedSignalPeaks,frames_to_analyze,within_frames_to_analyze, cellXYcoords, numCells, cellDistances, numBins, binVector, 1);


%here do KS test on normlBinnedCellJaccardsFrameSubset vs normlShuffledBinnedCellJaccardsFrameSubset

[hKSSubset, pKSSubset, ksStatSubset] = kstest2(normlBinnedCellJaccardsFrameSubset, ... 
	normlShuffledBinnedCellJaccardsFrameSubset) ;