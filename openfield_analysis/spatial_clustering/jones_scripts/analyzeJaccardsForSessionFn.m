function [outputFileArray, frameFileNames] = analyzeJaccardsForSessionFn(session, framesDir, regExp, CNMFE_path, ...
    inputPeakThreshold, inputMicronsPerPixel, inputMaxDist, inputBinSize, inputBStart, inputNumBins)
%Input
    

    if ~contains(framesDir, 'all_frames') 
        cd (framesDir) ; 
        mkdir('analysisOutput'); 
        frameFiles = dir(strcat(session, regExp)); 
        frameFileNames = vertcat(frameFiles.name);
        sizeFrameFileNames = size(frameFileNames);

        outputSessionArrayJaccards = {} ;
        outputSessionArraysignalPeaks = {} ;
        outputFilesPerVBin = cell(sizeFrameFileNames(1,1), 1);

        for i=1:sizeFrameFileNames(1,1)

            disp('loading session');
            disp(frameFileNames(i,:)); 
            outputFileArray_vbin = jaccardComputeJjmBinInputFrameSubsetFn(session, ...
                frameFileNames(i,:), framesDir, CNMFE_path, inputPeakThreshold, ...
                inputMicronsPerPixel, inputMaxDist, inputBinSize, inputBStart, inputNumBins) ; 
    
            %if ~isempty(outputFileArray)
            %    outputSessionArrayJaccards{i, 1} = outputFileArray{5, 1} ;
            %    outputSessionArraysignalPeaks{i, 1} = outputFileArray{1, 1} ;

            
            outputFilesPerVBin{i, 1}=outputFileArray_vbin;
        end
        outputFileArray=outputFilesPerVBin;

        %writecell(outputSessionArrayJaccards, strcat(session, '_VBinnedJaccardFiles_rest.csv'));
        %this will actually save all peaks in file, not just binned peaks... 
        %writecell(outputSessionArraysignalPeaks, strcat(session, '_VBinnedPeaks.csv'));
    else 
        frameFileNames = {};
        %create save path here
        
        outputFileArray = jaccardComputeJjmBinInputFrameSubsetFn(session, ...
                'all_frames', framesDir, CNMFE_path, inputPeakThreshold, ...
                inputMicronsPerPixel, inputMaxDist, inputBinSize, inputBStart, inputNumBins); 

    end

end