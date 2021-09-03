function [shiftedEventTrace, CellJaccards, ShuffledCellJaccards, normlBinnedCellJaccards, ...
    normlShuffledBinnedCellJaccards, proximalPairIndices] = p355_jaccard_shuffle(paddedSignalPeaksInput, ...
    thisTreatmentFrames,thisMoveTypeFrames, cellXYcoords, numCells, cellDistances, numBins, binVector, type)

%changed paddedSignalPeaks to paddedSignalPeaksInput -JJM

%INPUTS:
%1) numFrames
%2) paddedSignalPeaks
%3) thisTreatmentFrames
%4) thisMoveTypeFrames
%5) cellXYcoords
%6) numCells
%7) cellDistances
%8) numBins
%9) binVector
%10) type (jaccard 1 or pearson 2)

%OUTPUTS:
%1) shiftedEventTrace
%2) CellJaccards
%3) ShuffledCellJaccards
%4) normlBinnedCellJaccards 
%5) normlShuffledBinnedCellJaccards
if type == 2 
    %what does this do? -JJM 
    %paddedSignalPeaks = cellTraces;
    paddedSignalPeaksInput = paddedSignalPeaksInput; 
end
%get also the padded event traces for rest and movement

thisTreatment_PaddedSignalPeaks = paddedSignalPeaksInput(:, thisTreatmentFrames);
thisMoveType_PaddedSignalPeaks = thisTreatment_PaddedSignalPeaks(:, thisMoveTypeFrames);
nComparisons = length(cellDistances);%just to keep track of the number of cell-cell comparisons

%compute cross correlations as a function of distance (jaccard)
if type == 1 
    disp('type is jaccard');
    CellJaccards = 1-pdist(thisMoveType_PaddedSignalPeaks,'jaccard');
else if type == 2 
     disp('type is pearson');
     CellJaccards = corr(thisMoveType_PaddedSignalPeaks'); %creates a correlation matrix
     idx = 1:size(CellJaccards, 1)+1:numel(CellJaccards);%finds the diagonal
     CellJaccards(idx) = 0; %sets the diagonal to zero
     CellJaccards = squareform(CellJaccards); %converts square matrix with zeros diagonal to linear (same as pdist)    
     
    end
end
     
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


%%now let's bin these into 20-um bins, plot the results, and store the
%%proximal and distal jaccard for actual and shuffled data. 


proximalPairIndices = find(cellDistances(:) >= 20 & cellDistances(:) <= 100);

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