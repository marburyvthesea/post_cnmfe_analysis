
CNMFE_path = 'F:\JJM\miniscope_analysis\dSPNs\clustering_analysis' ; 
cd(CNMFE_path)

% 'DIO_r2.20_JNJ_15_28_00',


sessions =  {'GRIN013_H13_M33_S54', 'GRIN026_H16_M35_S34', 'GRIN027_H13_M29_S44', ...
             'GRIN032_H16_M49_S22', 'GRIN032_H17_M30_S22', ...
             'GRIN033_H13_M42_S33', 'GRIN033_H14_M34_S32', ...
             'GRIN035_H13_M31_S20', 'GRIN035_H13_M50_S58', 'GRIN035_H14_M40_S34', ...
             'GRIN039_H12_M26_S54', 'GRIN039_H12_M33_S29', 'GRIN039_H14_M8_S53', ...
             'GRIN009_H13_M59_S14', 'GRIN011_H10_M19_S59', ...
             'GRIN012_H16_M57_S23', 'GRIN012_H17_M32_S17', ...
             'GRIN018_H17_M41_S43', 'GRIN018_H16_M13_S53', ...
             'GRIN038_H11_M57_S0', 'GRIN038_H13_M37_S23', 'GRIN038_H15_M39_S40', ...
             'GRIN041_H12_M54_S49'
             } ; 

inputPeakThreshold = 2.5 ; 
inputMicronsPerPixel = 1.85 ; % micronsPerPixel 2.5 = microns (inscopix), 1 (v3), 1.85 (v4)
inputMaxDist = 500 ; 
inputBinSize = 50 ; 
inputBStart = 50 ;
inputNumBins = 9; %9 for 50um Size
%inputBinVector = inputBStart:inputBinSize:inputMaxDist;
%%
regExp= '_velocityBin*' ; 

%framesDir= 'F:\JJM\miniscope_analysis\PAM\clustering_analysis\frames_subset_Wed_11_Oct_2023_16_57_14\' ;
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


