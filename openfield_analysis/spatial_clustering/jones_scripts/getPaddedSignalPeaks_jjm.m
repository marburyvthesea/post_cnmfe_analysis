function [paddedSignalPeaks] = getPaddedSignalPeaks_jjm(signalPeaksUnpadded, samplesToPad)
	%% Pad signal peaks
	% to do:
	% 	make pad length adjustable 

	%
	sizeArray = size(signalPeaksUnpadded);
	numFrames = sizeArray(1,2);
	numCells = sizeArray(1,1);

	%preallocate
	paddedSignalPeaks = zeros(sizeArray);

	% do padding
	for cell = 1:numCells;
		for frame = 1:numFrames-(samplesToPad-1);
			if signalPeaksUnpadded(cell, frame) == 1;
				paddedSignalPeaks(cell, frame:frame+(samplesToPad-1)) = ones(1,samplesToPad);
			end
		end
	end
end 