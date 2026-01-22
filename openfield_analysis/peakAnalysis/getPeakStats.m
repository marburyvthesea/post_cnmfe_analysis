function [ampMax, lengthSamples, onsetIdx, offsetIdx, clippedRegion] = getPeakStatsFn(peakIdx, inputTol, ...
    inputWindowLenOnset, inputWindowLenOffset, inputPltRegion, ...
    inputZScores, inputCellTrace)

    % Set a tolerance for what is considered "baseline" (z close to 0)
    tol = inputTol;  % adjust as needed
    windowLenOnset = inputWindowLenOnset;  % require 3 consecutive samples within tol
    windowLenOffset = inputWindowLenOffset; 
    zScores = inputZScores;
    cellTrace = inputCellTrace; 
    % For plotting 
    pltRegion = inputPltRegion;  % For example, 10 samples before and after the onset
    % --- Find onset ---
    % We search backward from peakIdx. We want to find the first window of length windowLen (ending before the peak)
    % where every sample has |z| < tol. We then define onset as the first index of that window.
    onsetIdx = [];
    for i = peakIdx:-1:windowLenOnset
        if all(abs(zScores(i-windowLenOnset+1:i)) < tol)
            onsetIdx = i - windowLenOnset + 1;
            break;
        end
    end
    if isempty(onsetIdx)
        onsetIdx = 1;
    end
    % --- Find offset ---
    % Now search forward from the peak. We look for the first window of length windowLen
    % where every sample has |z| < tol, and define offset as the last index of that window.
    offsetIdx = [];
    N = length(zScores);
    for i = peakIdx:(N - windowLenOffset + 1)
        if all(abs(zScores(i:i+windowLenOffset-1)) < tol)
            offsetIdx = i + windowLenOffset - 1;
            break;
        end
    end
    if isempty(offsetIdx)
        offsetIdx = N;
    end

    ampMax = max(cellTrace(1,onsetIdx:offsetIdx)); 
    lengthSamples = offsetIdx-onsetIdx; 

    % Ensure the clipping indices are within the trace boundaries
    clipStart = max(1, onsetIdx - pltRegion);
    clipEnd   = min(length(cellTrace), offsetIdx + pltRegion);
    % Extract the clipped region from the full trace
    clippedRegion = cellTrace(clipStart:clipEnd);

end