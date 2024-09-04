%Define these variable in environment: session, frameFileInput


%add path to data 
addpath(genpath('F:\JJM\miniscope_analysis\clustering_analysis\')); 
%addpath(genpath('/Volumes/My_Passport/cnmfe_analysis_files/OpenFieldAnalysis/2020/D1_mGluRKO_clustering/data/'));
%add path to scripts
addpath(genpath('\Users\scanimage\Documents\JJM\post_cnmfe_analysis\'));

%session to load

dir_path = 'F:\JJM\miniscope_analysis\clustering_analysis\';
%session = 'DO_2_Day1_16_46_28';
save_path = strcat(dir_path, 'frame_subset\' , erase(frameFileInput, '.csv') , '_');

%load csv file with frame subset to test
framesSubset = readtable(strcat(dir_path, 'frame_subset\', frameFileInput), 'ReadVariableNames', true); 


%load filtered fluorescence traces from python output
disp('loading data')
cell_eg = readtable(strcat(dir_path,session,'_C_traces_filtered.csv'),'ReadVariableNames', true);

%variable names in the table will be x1, x2 etc... for cell 1, cell 2 

%cell centroids 
cellXYcoords = readtable(strcat(dir_path,session,'_com_filtered.csv'), 'ReadVariableNames', true);

%remove nonnumeric variables
%cell_eg_numeric = removevars(cell_eg,{'Var1','msCamFrame','velocity_bins'});

%convert to array
%remove 1st column, which is just index 
size_array = size(cell_eg);

numFramesToAnalyze = size(framesSubset);
frameSubsetIndicies = table2array(framesSubset(:, 2));


cell_traces = table2array(cell_eg(:,2:size_array(1,2)));
%convert to nCells x nFrames matrix
cell_traces = cell_traces';

disp('finding signal peaks')

% get "peaks" in signal, F/F0 above a, here 2.5, SD threshold
[signalPeaks, ~, ~] = computeSignalPeaks(cell_traces, 'doMovAvg', 0, 'reportMidpoint', 1, 'numStdsForThresh', 2.5);

%in the PD paper, we pad each 'event' to make is 1-s duration. Note that we
%no longer do this with our GCaMP7f data, but I would do it with GCaMP6
%data. 

disp('padding signal peaks')

%should adjust padded signal peaks to work with different input sampling intervals 
paddedSignalPeaks = getPaddedSignalPeaks(signalPeaks);


%compute the distances between all the pairs of cells
%note that in our movies, the pixel size is 2.5um. We can take your
%microscope and image a grid slide to determine the pixel size of your
%microscope after all the processing steps.

%convert cellXYcoords table to array
size_com_table = size(cellXYcoords);
XY_coords_array = table2array(cellXYcoords(:,2:size_com_table(1,2))); 
XY_coords_array = XY_coords_array';

cellDistances = pdist(XY_coords_array, 'euclidean')*micronsPerPixel;%distances multiplied by 2.5 = microns
%ouput squareform array for comparison in python later 
cellDistances_squareform = squareform(cellDistances); 

%we often want to compare treatments and behavioral states (e.g., periods
%of movement during amphetamine treatment). I am just going to analyse all
%of your frames here, but you can select subsets of frames corresponding to
%speed (which I would recommend, because the measurement appears to be
%higher at rest and lower at higher running speeds). We can look closer at
%this later. 

% transpose and add 1 to correct for python 0 indexing
frames_to_analyze = 1:size(cell_traces, 2);
within_frames_to_analyze = frameSubsetIndicies.'+1;

%now define the cell-cell distance bins you want to average the
%correlations within. We usually do 20 um bins out to 500um separation. We
%also ignore the first bin (<20um) because sometimes very nearby cells have
%high correlations because they are spatially overlapped (although I don't
%think this is a huge program with CNMFe, because it merges these cells)

maxDist = 500;%compare out to 500 um
binSize = 50;%compare in 50 um bins
numBins = maxDist/binSize-1;%throw out the first bin (overlapping cells)
binVector = 25:binSize:maxDist;%cells must be atleast 20um apart. 
numFrames = length(signalPeaks);
numCells = size(cellXYcoords, 1);

disp('computing jaccard scores')

[~, CellJaccards, ShuffledCellJaccards, normlBinnedCellJaccards, ...
    normlShuffledBinnedCellJaccards, proximalPairIndices] = ...
p355_jaccard_shuffle(paddedSignalPeaks,frames_to_analyze,within_frames_to_analyze, cellXYcoords, numCells, cellDistances, numBins, binVector, 1);

%% save these outputs to csv files
disp('saving output')

csvwrite(strcat(save_path,'signalPeaks','.csv'), signalPeaks);
csvwrite(strcat(save_path,'paddedSignalPeaks','.csv'),  paddedSignalPeaks);

csvwrite(strcat(save_path,'CellJaccards','.csv'), CellJaccards);
csvwrite(strcat(save_path,'ShuffledCellJaccards','.csv'), ShuffledCellJaccards);
csvwrite(strcat(save_path,'normlBinnedCellJaccards','.csv'), normlBinnedCellJaccards);
csvwrite(strcat(save_path,'normlShuffledBinnedCellJaccards','.csv'), normlShuffledBinnedCellJaccards);
csvwrite(strcat(save_path,'proximalPairIndices','.csv'), proximalPairIndices);

%% for computing the spatial coordination index

% calcuate the CellJaccards at each time point, set frames_to_analyze to 1?
% alternatively, just don't pad signal peaks and compute over padded frame length here?  

% perform a KS test on the normlBinnedCellJaccards and the normlShuffledBinnedCellJaccards 

% log(P) is the spatial coordination index 




