
CNMFE_path = 'F:\JJM\miniscope_analysis\dSPNs\clustering_analysis\' ; 
cd(CNMFE_path)

% 'DIO_r2.20_JNJ_15_28_00',


sessions =  {'DIO_r2_19_Day_1_14_20_58', 'DIO_r2_19_Day_1_14_36_06', ...
             'DIO_r2_1_Day1_18_05_16'
             } ; 

inputPeakThreshold = 2.5 ; 
inputMicronsPerPixel = 1.85 ; % micronsPerPixel 2.5 = microns (inscopix), 1 (v3), 1.85 (v4)
inputMaxDist = 500 ; 
inputBinSize = 225 ; 
inputBStart = 50 ;
inputNumBins = 2; %9 for 50um Size
%inputBinVector = inputBStart:inputBinSize:inputMaxDist;
%%
%regExp= '_velocityBin*' ; 

%framesDir= 'F:\\JJM\\miniscope_analysis\\dSPNs\\clustering_analysis\\dSPNs_framesSubsetAnalysis\\' ;
framesDir = 'all_frames';

sizeSessions = size(sessions);

    if  strcmp(framesDir, 'all_frames')
        dirName = strcat('all_frames_', string(datetime('now', 'format', 'y_M_d_HH_mm-ss'), "yyyy-MM-dd-HH-mm-ss"), '_analysisOutput');
        mkdir(dirName);
        dirInput = dirName ;
    else
        dirInput = framesDir ;
    end
%%
for i=1:sizeSessions(1,2)
    session=sessions{1,i} ;
    analyzeJaccardsForSessionFn(session, dirInput, regExp, CNMFE_path, inputPeakThreshold, inputMicronsPerPixel, ...
        inputMaxDist, inputBinSize, inputBStart, inputNumBins) ; 

end


