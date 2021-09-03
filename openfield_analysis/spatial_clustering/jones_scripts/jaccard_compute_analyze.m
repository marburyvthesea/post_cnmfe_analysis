
addpath(genpath('/Users/johnmarshall/Documents/Analysis/spatial_clustering/'));

addpath(genpath('/Users/johnmarshall/Documents/Analysis/PythonAnalysisScripts/post_cnmfe_analysis/'));

dir_path = '/Users/johnmarshall/Documents/Analysis/spatial_clustering/';

session = 'GRIN039_H12_M26_S54';

save_path = strcat(dir_path, session, '_');

cell_eg = readtable(strcat(dir_path,session,'_C_traces_filtered.csv'),'ReadVariableNames', true);

cellXYcoords = readtable(strcat(dir_path,session,'_com_filtered.csv'), 'ReadVariableNames', true);

size_array = size(cell_eg);

cell_traces = table2array(cell_eg(:,2:size_array(1,2)));

cell_traces = cell_traces';

[signalPeaks, ~, ~] = computeSignalPeaks(cell_traces, 'doMovAvg', 0, 'reportMidpoint', 1, 'numStdsForThresh', 2.5);

%adjusted padded signal peaks to work with different input sampling intervals 
paddedSignalPeaks = getPaddedSignalPeaks_jjm(signalPeaks,5);

%convert cellXYcoords table to array
size_com_table = size(cellXYcoords);
XY_coords_array = table2array(cellXYcoords(:,2:size_com_table(1,2))); 
XY_coords_array = XY_coords_array';

cellDistances = pdist(XY_coords_array, 'euclidean')*1; %distances multiplied by micron/pixel (0.9-1.1 for v3)
%ouput squareform array for comparison in python later 
cellDistances_squareform = squareform(cellDistances); 

maxDist = 500;%compare out to 500 um
binSize = 20;%compare in 20 um bins
numBins = maxDist/binSize-1;%throw out the first bin (overlapping cells)
binVector = 20:binSize:maxDist;%cells must be atleast 20um apart. 
numFrames = length(signalPeaks);
numCells = size(cellXYcoords, 1);

%% break script here to be able to loop over different frame regions 


frames_to_analyze = 1: size(cell_traces, 2);
within_frames_to_analyze = 1: size(cell_traces, 2);

disp('computing jaccard scores')
% changed paddedSignalPeaks variable name in p355 shuffle function to correct scope when loopign over different frame regions 

[~, CellJaccardsFullTrace, ShuffledCellJaccardsFullTrace, normlBinnedCellJaccardsFullTrace, ...
    normlShuffledBinnedCellJaccardsFullTrace, proximalPairIndicesFullTrace] = ...
p355_jaccard_shuffle(paddedSignalPeaks,frames_to_analyze,within_frames_to_analyze, cellXYcoords, numCells, cellDistances, numBins, binVector, 1);

%% save these outputs to csv files
disp('saving output')

csvwrite(strcat(save_path,'CellJaccards','.csv'), CellJaccardsFullTrace);
csvwrite(strcat(save_path,'ShuffledCellJaccards','.csv'), ShuffledCellJaccardsFullTrace);
csvwrite(strcat(save_path,'normlBinnedCellJaccards','.csv'), normlBinnedCellJaccardsFullTrace);
csvwrite(strcat(save_path,'normlShuffledBinnedCellJaccards','.csv'), normlShuffledBinnedCellJaccardsFullTrace);
csvwrite(strcat(save_path,'proximalPairIndices','.csv'), proximalPairIndicesFullTrace);

%% for computing the spatial coordination index

% calcuate the CellJaccards at each time point, set frames_to_analyze to 1? 

% perform a KS test on the normlBinnedCellJaccards and the normlShuffledBinnedCellJaccards 

% log(P) is the spatial coordination index 
