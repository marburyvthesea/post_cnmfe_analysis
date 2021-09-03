
function[sessionOutput] = jaccard_compute_fn_jjm(dataDir, session, regExp, sdThreshold, pixelScale, maxDist, binSize, padding, samplesToPad)
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
cell_eg = readtable(strcat(dataDir, session, regExp),'ReadVariableNames', true);

%cell centroids 
cellXYcoords = readtable(strcat(dataDir,session,'_com_filtered.csv'), 'ReadVariableNames', true);

%remove nonnumeric variables
%cell_eg_numeric = removevars(cell_eg,{'Var1','msCamFrame','velocity_bins'});

%convert to array
%remove 1st column, which is just index 
size_array = size(cell_eg);

cell_traces = table2array(cell_eg(:,2:size_array(1,2)));
%convert to nCells x nFrames matrix
cell_traces = cell_traces';

disp('finding signal peaks')

% get "peaks" in signal, F/F0 above a, here 2.5, SD threshold
[signalPeaks, ~, ~] = computeSignalPeaks(cell_traces, 'doMovAvg', 0, 'reportMidpoint', 1, 'numStdsForThresh', sdThreshold);

%in the PD paper, we pad each 'event' to make is 1-s duration. Note that we
%no longer do this with our GCaMP7f data, but I would do it with GCaMP6
%data. 

disp('padding signal peaks')

%should adjust padded signal peaks to work with different input sampling intervals 
if padding == true:
	paddedSignalPeaks = getPaddedSignalPeaks_jjm(signalPeaks, samplesToPad);
else:
	paddedSignalPeaks = signalPeaks; 
end

%compute the distances between all the pairs of cells
%note that in our movies, the pixel size is 2.5um. We can take your
%microscope and image a grid slide to determine the pixel size of your
%microscope after all the processing steps.
%distances multiplied by pixels/microns
% f=12, 0.9
% f=15, 0.96
% f=20, 1.02

%convert cellXYcoords table to array
size_com_table = size(cellXYcoords);
XY_coords_array = table2array(cellXYcoords(:,2:size_com_table(1,2))); 
XY_coords_array = XY_coords_array';

cellDistances = pdist(XY_coords_array, 'euclidean')*1;%distances multiplied by 2.5 = microns
%ouput squareform array for comparison in python later 
cellDistances_squareform = squareform(cellDistances); 

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
binVector = binSize:binSize:maxDist;%cells must be atleast 20um apart. 
numFrames = length(signalPeaks);
numCells = size(cellXYcoords, 1);

disp('computing jaccard scores')

[~, CellJaccards, ShuffledCellJaccards, normlBinnedCellJaccards, ...
    normlShuffledBinnedCellJaccards, proximalPairIndices] = ...
p355_jaccard_shuffle(paddedSignalPeaks,frames_to_analyze,within_frames_to_analyze, cellXYcoords, numCells, cellDistances, numBins, binVector, 1);

%% save these outputs to csv files
disp('saving output')

csvwrite(strcat(save_path,'CellJaccards__', num2str(sdThreshold), '.csv'), CellJaccards);
csvwrite(strcat(save_path,'ShuffledCellJaccardsi__', num2str(sdThreshold), '.csv'), ShuffledCellJaccards);
csvwrite(strcat(save_path,'normlBinnedCellJaccards__', num2str(sdThreshold),'.csv'), normlBinnedCellJaccards);
csvwrite(strcat(save_path,'normlShuffledBinnedCellJaccards__', num2str(sdThreshold),'.csv'), normlShuffledBinnedCellJaccards);
csvwrite(strcat(save_path,'proximalPairIndices__', num2str(sdThreshold), '.csv'), proximalPairIndices);
csvwrite(strcat(save_path,'cellDistances_squareform_matrix__', num2str(sdThreshold),'.csv'), cellDistances_squareform);

%% save parameters to structure
analysisParams = struct('session', session, 'sdThreshold', sdThreshold, 'pixelScaleFactor', pixelScale, 'maxDistanceForBinning', ... 
						maxDist, 'binSize', binSize);

%% output to structure
sessionOutput = struct('CellJaccards', CellJaccards, 'ShuffledCellJaccards', ShuffledCellJaccards, ...
						'normlBinnedCellJaccards', normlBinnedCellJaccards, 'normlShuffledBinnedCellJaccards', ...
						normlShuffledBinnedCellJaccards, 'proximalPairIndices', proximalPairIndices, 'binVector', binVector, ...
						'analysisParameters', analysisParams);

end



