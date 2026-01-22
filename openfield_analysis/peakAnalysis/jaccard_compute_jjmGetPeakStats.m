

%add path to data 
addpath(genpath('/projects/p30771/miniscope/analysis/OpenFieldAnalysis/spatial_clusters/jones_script_analysis/data/')); 
%addpath(genpath('/Volumes/My_Passport/cnmfe_analysis_files/OpenFieldAnalysis/2020/D1_mGluRKO_clustering/data/'));
%add path to scripts
addpath(genpath('/home/jma819/post_cmfe_analysis'));
%session to load
dir_path = 'F:\JJM\miniscope_analysis\mGluR5_NAM\clustering_analysis\';
session = 'Vehicle_DIO_r2.7_15_20_30';
save_path = strcat(dir_path, session, '_');
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

%% loop over all cells - parallel processing 
%Inputs for getPeakStatsFn
inputTol = 0.2;
inputWindowLenOnset = 3;
inputWindowLenOffset = 3;
inputPltRegion = 10;

% Make sure a parallel pool is available (this may start one if needed)
if isempty(gcp('nocreate'))
    parpool;
end
numCells = size(cell_traces, 1);  % Number of cells (rows)
tempPeakStats = cell(numCells, 1); % Preallocate cell array to hold each cell's results
parfor cellIdx = 1:numCells
    % Use a local cell array to collect results for this cell.
    localPeakStats = {};  
    cellPeaks = signalPeaks(cellIdx, :);
    peakIndices = find(cellPeaks == 1);
    cellTrace = cell_traces(cellIdx, :);       
    % Compute the global mean and standard deviation for this trace.
    mu = mean(cellTrace);
    sigma = std(cellTrace);
    % Compute z-scores for the entire trace.
    zScores = (cellTrace - mu) / sigma;   
    % Loop over each detected peak in this cell.
    for p = 1:length(peakIndices)
        currentPeakIdx = peakIndices(p);      
        % Call your function with the current peak index, zScores, and cellTrace.
        [ampMax, lengthSamples, onsetIdx, offsetIdx, clippedRegion] = ...
            getPeakStatsFn(currentPeakIdx, inputTol, inputWindowLenOnset, inputWindowLenOffset, ...
                           inputPltRegion, zScores, cellTrace);                      
        % Store the results in a structure for this peak.
        % (We create a local structure variable inside the loop.)
        newStruct = struct();
        newStruct.cellIdx = cellIdx;
        newStruct.peakIdx = currentPeakIdx;
        newStruct.ampMax = ampMax;
        newStruct.lengthSamples = lengthSamples;
        newStruct.onsetIdx = onsetIdx;
        newStruct.offsetIdx = offsetIdx;
        newStruct.clippedRegion = {clippedRegion};      
        % Append to the local cell array.
        localPeakStats{end+1} = newStruct;  
    end   
    % Store the results for this cell in the temporary cell array.
    if isempty(localPeakStats)
        tempPeakStats{cellIdx} = [];  % or an empty structure array if you prefer
    else
        tempPeakStats{cellIdx} = [localPeakStats{:}];
    end
end
% Outside the parfor loop, concatenate all results into one structure array.
nonEmptyCells = tempPeakStats(~cellfun(@isempty, tempPeakStats));
peakStats = horzcat(nonEmptyCells{:});

%% plot peak examples with onset and offset 

idxFromStructure = 9 ; 
clippedRegionCell = peakStats(idxFromStructure).clippedRegion;
clippedRegion = clippedRegionCell{1,1}; 
onsetIdx = peakStats(idxFromStructure).onsetIdx;
offsetIdx = peakStats(idxFromStructure).offsetIdx;
clipStart = onsetIdx - 10;
clipEnd = clipStart+length(clippedRegion)-1;

% Plot the clipped region
figure;
plot(clipStart:clipEnd, clippedRegion, 'k-', 'LineWidth', 1.5);
hold on;
% Mark the onset on the clipped plot (onsetIdx is in the original indexing)
plot(onsetIdx, cellTrace(onsetIdx), 'ro', 'MarkerFaceColor', 'r');
plot(offsetIdx, cellTrace(offsetIdx), 'ro', 'MarkerFaceColor', 'b');
xlabel('Index');
ylabel('Signal Value');
title('Clipped Region of Trace around Onset');
legend('Clipped Signal', 'Onset','Location','Best');
hold off;







