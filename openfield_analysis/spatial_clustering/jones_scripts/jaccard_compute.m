)
cellXYcoords = csvread('C:\Users\jgp3408\Dropbox\Shared_Folders\John Marshall\testData\GRIN026_H16_M35_S34_com.csv', 1, 1); %exclude first row and first column

cell_traces = csvread('C:\Users\jgp3408\Dropbox\Shared_Folders\John Marshall\testData\GRIN026_H16_M35_S34_cells_f_traces_filtered.csv', 1, 1);

speed_trace = csvread('C:\Users\jgp3408\Dropbox\Shared_Folders\John Marshall\testData\GRIN026_H16_M35_S34_animal_velocity_trimmed.csv', 1, 1);


%event detection on the calcium traces
%you can play around with the number of standard deviations above threshold
%to improve this in your data. we us 2.5 for CNMFe data

cell_traces = cell_traces'; %convert to nCells x nFrames matrix

[signalPeaks, ~, ~] = computeSignalPeaks(cell_traces, 'doMovAvg', 0, 'reportMidpoint', 1, 'numStdsForThresh', 2.5);%


%in the PD paper, we pad each 'event' to make is 1-s duration. Note that we
%no longer do this with our GCaMP7f data, but I would do it with GCaMP6
%data. 

paddedSignalPeaks = zeros(size(signalPeaks));%pre-allocate
numFrames = length(signalPeaks);
numCells = size(cellXYcoords, 1);


    for frame = 1:numFrames-4;
        if signalPeaks(cell, frame) == 1;
            paddedSignalPeaks(cell, frame:frame+4) = ones(1,5);
        end
    end
end

%plot the event traces and speed trace
figure(1); 
subplot(2, 1, 1); plot(speed_trace); xlim([1 length(speed_trace)])
ylabel('Speed (cm/s)'); xlabel('Time (5-Hz frames)');
subplot(2, 1, 2); imagesc(paddedSignalPeaks);
ylabel('Cell No.'); xlabel('Time (5-Hz frames)');

%compute the distances between all the pairs of cells
%note that in our movies, the pixel size is 2.5um. We can take your
%microscope and image a grid slide to determine the pixel size of your
%microscope after all the processing steps. 

cellDistances = pdist(cellXYcoords, 'euclidean')*2.5;%distances multiplied by 2.5 = microns

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

maxDist = 500;%compare out to 500 um
binSize = 20;%compare in 20 um bins
numBins = maxDist/binSize-1;%throw out the first bin (overlapping cells)
binVector = 20:binSize:maxDist;%cells must be atleast 20um apart. 



[~, CellJaccards, ShuffledCellJaccards, normlBinnedCellJaccards, ...
    normlShuffledBinnedCellJaccards, proximalPairIndices] = ...
p355_jaccard_shuffle(paddedSignalPeaks,frames_to_analyze,within_frames_to_analyze, cellXYcoords, numCells, cellDistances, numBins, binVector, 1);
    


%there are several way to analyze the outputs. Specifically, you could look
%at the average of all cells or do more detailed analyses of individual
%cell paris. 

%we commonly look at the nearby (proximal cell pairs)
proximalJaccard = nanmean(CellJaccards(proximalPairIndices));%average jaccard of nearby cells
proximalJaccard_Shuffled = nanmean(ShuffledCellJaccards(proximalPairIndices));%average of nearby cells where the traces were circularly permuted 1K times
proximalJaccard_shuffle_normalized =  nanmean(CellJaccards(proximalPairIndices)./ShuffledCellJaccards(proximalPairIndices));%shuffle normalized proximal cell co-activity (the shuffle normalized to itself will equal 1)

%this is the jaccard vs distance in the binned comparisons. We usually plot
%these. 
jaccardTrace_shuffle_normalized =  normlBinnedCellJaccards;

figure(2); 
plot(binVector(2:end), jaccardTrace_shuffle_normalized)
ylabel('Shuffle-normalized cell-cell co-activity (jaccard)')
xlabel('Cell-cell distance bin (um)')