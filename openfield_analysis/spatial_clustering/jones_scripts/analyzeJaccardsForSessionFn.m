function [outputSessionArrayJaccards, outputSessionArraysignalPeaks] = analyzeJaccardsForSessionFn(session, framesDir, regExp, CNMFE_path)
%Input
    
    if ~contains(framesDir, 'all_frames') 
        cd (framesDir) ; 
        mkdir('analysisOutput'); 
        frameFiles = dir(strcat(session, regExp)); 
        frameFileNames = vertcat(frameFiles.name);
        sizeFrameFileNames = size(frameFileNames);

        outputSessionArrayJaccards = {} ;
        outputSessionArraysignalPeaks = {} ;

        for i=1:sizeFrameFileNames(1,1)

            disp('loading session');
            disp(frameFileNames(i,:)); 
            outputFileArray = jaccardComputeJjm50umBinsFrameSubsetFn(session, ...
                frameFileNames(i,:), framesDir, CNMFE_path) ; 
    
            if ~isempty(outputFileArray)
                outputSessionArrayJaccards{i, 1} = outputFileArray{5, 1} ;
                outputSessionArraysignalPeaks{i, 1} = outputFileArray{1, 1} ;

            end 
        end

        writecell(outputSessionArrayJaccards, strcat(session, '_VBinnedJaccardFiles_rest.csv'));
        %this will actually save all peaks in file, not just binned peaks... 
        %writecell(outputSessionArraysignalPeaks, strcat(session, '_VBinnedPeaks.csv'));
    else 

        %create save path here
        
        outputFileArray = jaccardComputeJjm50umBinsFrameSubsetFn(session, ...
                'all_frames', framesDir, CNMFE_path); 

    end

end