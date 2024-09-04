%% Input data
dirPath='F:\JJM\miniscope_analysis\dSPNs\clustering_analysis'
C_traces_eg='GRIN013_H13_M33_S54_C_traces_filtered.csv';
com_eg='GRIN013_H13_M33_S54_com_filtered.csv';

%% Options
peakThreshold = 2.5 ; 
micronsPerPixel = 1.85 ; % micronsPerPixel 2.5 = microns (inscopix), 1 (v3), 1.85 (v4)
maxDist = 500 ; 
binSize = 50 ; 
bStart = 50 ;
numBins = 9;

frameFileInput='all_frames';
%% for loading subset of frames
%frameSubsetDir= 'F:\JJM\miniscope_analysis\dSPNs\clustering_analysis\frames_subset_Fri_06_Oct_2023_05_59_10\';
%frameFileInput= 'GRIN038_H13_M37_S23_velocityBin0.csv';

%framesSubset = readtable(strcat(frameSubsetDir, frameFileInput), 'ReadVariableNames', true); 
%numFramesToAnalyze = size(framesSubset);
%frameSubsetIndicies = table2array(framesSubset(:, 2));

%%
cell_eg = readtable(fullfile(dirPath,C_traces_eg),'ReadVariableNames', true);
cellXYcoords = readtable(fullfile(dirPath,com_eg), 'ReadVariableNames', true);
size_array = size(cell_eg);
cell_traces = table2array(cell_eg(:,2:size_array(1,2)));
cell_traces = cell_traces';
[signalPeaks, ~, ~] = computeSignalPeaks(cell_traces, 'doMovAvg', 0, 'reportMidpoint', 1, 'numStdsForThresh', peakThreshold);
%%
paddedSignalPeaks = getPaddedSignalPeaks(signalPeaks);
size_com_table = size(cellXYcoords);
XY_coords_array = table2array(cellXYcoords(:,2:size_com_table(1,2)));
XY_coords_array = XY_coords_array';
cellDistances = pdist(XY_coords_array, 'euclidean')*micronsPerPixel;
cellDistances_squareform = squareform(cellDistances);

%%
frames_to_analyze = 1:size(cell_traces, 2);
if strcmp(frameFileInput, 'all_frames')
    within_frames_to_analyze_trimmed = frames_to_analyze ;
else
    within_frames_to_analyze = frameSubsetIndicies.'+1;
    %remove values exceeding cnmfe length 
    logical_index = within_frames_to_analyze <= height(cell_eg);
    within_frames_to_analyze_trimmed = within_frames_to_analyze(logical_index);

end

%%
if within_frames_to_analyze_trimmed > 0
%now define the cell-cell distance bins you want to average the
%correlations within. We usually do 20 um bins out to 500um separation. We
%also ignore the first bin (<20um) because sometimes very nearby cells have
%high correlations because they are spatially overlapped (although I don't
%think this is a huge program with CNMFe, because it merges these cells)

%maxDist = 500;%compare out to 500 um
%binSize = 50;%compare in 50 um bins
%numBins = maxDist/binSize-1;%throw out the first bin (overlapping cells)
    binVector = bStart:binSize:maxDist;%cells must be atleast 25um apart, 25:binSize:maxDist  
    numFrames = length(signalPeaks);
    numCells = size(cellXYcoords, 1);
        
    disp('computing jaccard scores')
    disp('bins:')
    disp(binVector)
    disp('num bins')
    disp(numBins)
end
%%

%    [~, CellJaccards, ShuffledCellJaccards, normlBinnedCellJaccards, ...
%    normlShuffledBinnedCellJaccards, proximalPairIndices] = ...
%    p355_jaccard_shuffle(paddedSignalPeaks,frames_to_analyze,within_frames_to_analyze_trimmed, cellXYcoords, numCells, cellDistances, numBins, binVector, 1);

%% p355_jaccard_shuffle script
% inputs
paddedSignalPeaksInput=paddedSignalPeaks;
thisTreatmentFrames=frames_to_analyze;
thisMoveTypeFrames=within_frames_to_analyze_trimmed;
type=1;

%%
if type == 2 
    %what does this do? -JJM 
    %paddedSignalPeaks = cellTraces;
    paddedSignalPeaksInput = paddedSignalPeaksInput; 
end
%get also the padded event traces for rest and movement

thisTreatment_PaddedSignalPeaks = paddedSignalPeaksInput(:, thisTreatmentFrames);
thisMoveType_PaddedSignalPeaks = thisTreatment_PaddedSignalPeaks(:, thisMoveTypeFrames);
nComparisons = length(cellDistances);%just to keep track of the number of cell-cell comparisons

%%
%compute cross correlations as a function of distance (jaccard)
if type == 1 
    disp('type is jaccard');
    %pdist with jaccard option gives the percentage of nonzero
    %"coordinates" or samples that differ between the cell traces, so
    %1-pdist gives % of similar samples in the traces, generally these are
    %close to 0, e.g. mostly all different 
    CellJaccards = 1-pdist(thisMoveType_PaddedSignalPeaks,'jaccard');
else if type == 2 
     disp('type is pearson');
     CellJaccards = corr(thisMoveType_PaddedSignalPeaks'); %creates a correlation matrix
     idx = 1:size(CellJaccards, 1)+1:numel(CellJaccards);%finds the diagonal
     CellJaccards(idx) = 0; %sets the diagonal to zero
     CellJaccards = squareform(CellJaccards); %converts square matrix with zeros diagonal to linear (same as pdist)    
     %plot a histogram of the cell jaccards 
     %histogram(CellJaccards, 'EdgeColor', 'white', 'FaceColor', [0.5 0.5 0.5]);
    end
end
%% shuffle Ca2+ traces and compute Jaccards
nComparisons = length(cellDistances);%just to keep track of the number of cell-cell comparisons

%pre-allocate
thisTreatment_ShiftVector = zeros(numCells, 1);
shiftedEventTrace = zeros(numCells, length(thisMoveTypeFrames),1000);
thisTreatment_ShiftedJaccardMatrix = zeros(1000,nComparisons);

%shuffle
for x = 1:1000;
    if length(thisMoveTypeFrames) >= numCells
        thisTreatment_ShiftVector = randperm(length(thisMoveTypeFrames), numCells);
    else
        thisTreatment_ShiftVector = randsample(length(thisMoveTypeFrames), numCells, true);
    end
    
    for cell = 1:numCells;
        shiftedEventTrace(cell,:,x) = circshift(thisMoveType_PaddedSignalPeaks(cell,:),thisTreatment_ShiftVector(cell),2);
    end
    if type == 1
        thisTreatment_ShiftedJaccardMatrix(x, :) = 1-pdist(shiftedEventTrace(:,:,x),'jaccard');
    else if type == 2
         theseShiftedJaccards = corr(shiftedEventTrace(:,:,x)');
         idx = 1:size(theseShiftedJaccards, 1)+1:numel(theseShiftedJaccards);%finds the diagonal
         theseShiftedJaccards(idx) = 0; %sets the diagonal to zero
         theseShiftedJaccards = squareform(theseShiftedJaccards); %converts square matrix with zeros diagonal to linear (same as pdist)   
         
         thisTreatment_ShiftedJaccardMatrix(x, :) = theseShiftedJaccards;
         
        end
    end         
         
end

%average the results
%using nanmean here to get rid of NaNs due to jaccard correlations between
%cells in which neither cell had an event (division by zero)

ShuffledCellJaccards = nanmean(thisTreatment_ShiftedJaccardMatrix);
% drug_restShuffledCellJaccards = nanmean(drug_restShiftedJaccardMatrix);

%%
%%now let's bin these into 20-um bins, plot the results, and store the
%%proximal and distal jaccard for actual and shuffled data. 


proximalPairIndices = find(cellDistances(:) >= binVector(1) & cellDistances(:) <= binVector(2));

%find the indices of the distance bins
for bIdx = 1:numBins
     binStructure(bIdx).bin = find(cellDistances(:) > binVector(bIdx)+0.00001 & cellDistances(:) < binVector(bIdx+1));
end

%now bin the correlations, compute the mean and sem per bin
thisTreatment_binnedCellJaccards = zeros(1, numBins);thisTreatment_binnedShuffledCellJaccards = zeros(1, numBins);

for bIdx = 1:numBins
    %using nanmean here to ignore comparisons in which neither of the two
    %cells being compared had a calcium event
         thisTreatment_binnedCellJaccards(1,bIdx) = nanmean(CellJaccards(1,binStructure(bIdx).bin));
         thisTreatment_binnedShuffledCellJaccards(1,bIdx) = nanmean(ShuffledCellJaccards(1,binStructure(bIdx).bin));
end

%normalize the comparisons
if type == 1 
    
normlBinnedCellJaccards = thisTreatment_binnedCellJaccards./thisTreatment_binnedShuffledCellJaccards;
normlShuffledBinnedCellJaccards = thisTreatment_binnedShuffledCellJaccards./thisTreatment_binnedShuffledCellJaccards;
end

if type == 2 

normlBinnedCellJaccards = thisTreatment_binnedCellJaccards-thisTreatment_binnedShuffledCellJaccards;
normlShuffledBinnedCellJaccards = thisTreatment_binnedShuffledCellJaccards-thisTreatment_binnedShuffledCellJaccards;
    
end