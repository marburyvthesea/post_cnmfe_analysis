
function[sessionOutput] = jaccard_compute_fn_jjm(dataDir, session, sdThreshold, pixelScale, maxDist, binSize)
%%add path to data 
%addpath(genpath('/projects/p30771/miniscope/analysis/OpenFieldAnalysis/spatial_clusters/jones_script_analysis/')); 
addpath(genpath(dataDir));
%add path to scripts
%addpath(genpath('/home/jma819/post_cmfe_analysis'));

%session to load
save_path = strcat(dataDir, session, '_');

%load filtered fluorescence traces from python output
disp('loading data')
disp(session)
cell_eg = readtable(strcat(dataDir,session,'_filtered_f_traces.csv'),'ReadVariableNames', true);

%cell centroids 
cellXYcoords = csvread(strcat(dataDir,session,'_com.csv'),1, 1);

%remove nonnumeric variables
cell_eg_numeric = removevars(cell_eg,{'Var1','msCamFrame','velocity_bins'});

%convert to array
cell_traces = table2array(cell_eg_numeric);
%convert to nCells x nFrames matrix
cell_traces = cell_traces';

disp('finding signal peaks')

%%get "peaks" in signal, F/F0 above a, here 2.5, SD threshold
[signalPeaks, ~, ~] = computeSignalPeaks(cell_traces, 'doMovAvg', 0, 'reportMidpoint', 1, 'numStdsForThresh', sdThreshold);

%in the PD paper, we pad each 'event' to make is 1-s duration. Note that we
%no longer do this with our GCaMP7f data, but I would do it with GCaMP6
%data. 

disp('padding signal peaks')

paddedSignalPeaks = getPaddedSignalPeaks(signalPeaks);


%compute the distances between all the pairs of cells
%note that in our movies, the pixel size is 2.5um. We can take your
%microscope and image a grid slide to determine the pixel size of your
%microscope after all the processing steps.

cellDistances = pdist(cellXYcoords, 'euclidean')*pixelScale;%distances multiplied by 2.5 = microns

%we often want to compare treatments and behavioral states (e.g., periods
%of movement during amphetamine treatment). I am just going to analyse all
%of your frames here, but you can select subsets of frames corresponding to
%speed (which I would recommend, because the measurement appears to be
%higher at rest and lower at higher running speeds). We can look closer at
%this later. 

frames_to_analyze = 1: size(cell_traces, 2);
within_frames_to_analyze = 1: size(cell_traces, 2);

%now define the cell-cell distance bins you want to average the
%correlations within. We usually do 20 um bins out to 500um separation. We
%also ignore the first bin (<20um) because sometimes very nearby cells have
%high correlations because they are spatially overlapped (although I don't
%think this is a huge program with CNMFe, because it merges these cells)

numBins = maxDist/binSize-1;%throw out the first bin (overlapping cells)
binVector = 20:binSize:maxDist;%cells must be atleast 20um apart. 
numFrames = length(signalPeaks);
numCells = size(cellXYcoords, 1);

disp('computing jaccard scores')

[~, CellJaccards, ShuffledCellJaccards, normlBinnedCellJaccards, ...
    normlShuffledBinnedCellJaccards, proximalPairIndices] = ...
p355_jaccard_shuffle(paddedSignalPeaks,frames_to_analyze,within_frames_to_analyze, cellXYcoords, numCells, cellDistances, numBins, binVector, 1);

%% save these outputs to csv files
disp('saving output')

csvwrite(strcat(save_path,'CellJaccards','.csv'), CellJaccards);
csvwrite(strcat(save_path,'ShuffledCellJaccards','.csv'), ShuffledCellJaccards);
csvwrite(strcat(save_path,'normlBinnedCellJaccards','.csv'), normlBinnedCellJaccards);
csvwrite(strcat(save_path,'normlShuffledBinnedCellJaccards','.csv'), normlShuffledBinnedCellJaccards);
csvwrite(strcat(save_path,'proximalPairIndices','.csv'), proximalPairIndices);

%% save parameters to structure
analysisParams = struct('session', session, 'sdThreshold', sdThreshold, 'pixelScaleFactor', pixelScale, 'maxDistanceForBinning', ... 
						maxDist, 'binSize', binSize);

%% output to structure
sessionOutput = struct('CellJaccards', CellJaccards, 'ShuffledCellJaccards', ShuffledCellJaccards, ...
						'normlBinnedCellJaccards', normlBinnedCellJaccards, 'normlShuffledBinnedCellJaccards', ...
						normlShuffledBinnedCellJaccards, 'proximalPairIndices', proximalPairIndices, 'binVector', binVector, ...
						'analysisParameters', analysisParams);

end



