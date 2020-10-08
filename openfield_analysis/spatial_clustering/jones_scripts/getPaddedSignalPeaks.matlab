function [paddedSignalPeaks] = getPaddedSignalPeaks(signalPeaksUnpadded)
	%% Pad signal peaks
	% to do:
	% 	make pad length adjustable 

	%
	sizeArray = size(signalPeaksUnpadded);
	numFrames = sizeArray(1,2);
	numCells = sizeArray(1,1);

	%preallocate
	paddedSignalPeaks = zeros(SizaArray);

	% do padding
	for cell = 1:numCells;
		for frame = 1:numFrames-4;
			if signalPeaks(cell, frame) == 1;
				paddedSignalPeaks(cell, frame:frame+4) = ones(1,5)
			end
		end
	end
end 