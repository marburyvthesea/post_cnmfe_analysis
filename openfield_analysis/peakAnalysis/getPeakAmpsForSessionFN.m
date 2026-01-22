function [peakStats] = getPeakAmpsForSessionFN(inputSession, inputDirPath, inputPeakThreshold)
%do "GetPeakStats" script as fn

    disp('loading data')
    cell_eg = readtable(strcat(inputDirPath, inputSession,'_C_traces_filtered.csv'),'ReadVariableNames', true);

    %convert to array
    %remove 1st column, which is just index 
    size_array = size(cell_eg);
    
    cell_traces = table2array(cell_eg(:,2:size_array(1,2)));
    %convert to nCells x nFrames matrix
    cell_traces = cell_traces';
    disp('finding signal peaks')
    % get "peaks" in signal, F/F0 above a, here 2.5, SD threshold
    [signalPeaks, ~, ~] = computeSignalPeaks(cell_traces, 'doMovAvg', 0, 'reportMidpoint', 1, 'numStdsForThresh', inputPeakThreshold);

    % loop over all cells - parallel processing 
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
    for k = 1:length(peakStats)
        peakStats(k).session = inputSession;
    end
end

