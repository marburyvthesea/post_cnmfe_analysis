
CNMFE_path = 'F:\JJM\miniscope_analysis\mGluR5_NAM\clustering_analysis_SYdata\' ; 

% 'DIO_r2.20_JNJ_15_28_00',


sessions =  { '20220808_m974_fen02_Feno', '20220808_m973_fen02_Feno', ...
              '20220808_f979_fen02_Feno', '20220808_f977_fen02_Feno', ...
              '20220808_f976_fen02_Feno', ...
              '20220801_m974_fen01', '20220801_m973_fen01', ...
              '20220801_f979_fen01', '20220801_f977_fen01', ...
              '20220801_f976_fen01'
              } ; 

inputPeakThreshold = 2.5 ; 
inputMicronsPerPixel = 2.5 ; % micronsPerPixel 2.5 = microns (inscopix), 1 (v3), 1.85 (v4)
inputMaxDist = 500 ; 
inputBinSize = 450 ; 
inputBStart = 50 ;
inputNumBins = 1; %9 for 50um Size
%inputBinVector = inputBStart:inputBinSize:inputMaxDist;

%%
sizeSessions = size(sessions); 
numSessions = sizeSessions(1,2);
allPeakStatsSession = cell(2, numSessions);
for i=1:sizeSessions(1,2)
    session=sessions{1,i} ;
    % call function to get peak amplitude here (as z score)
    peakStatsSession = getPeakAmpsForSessionFN(session, CNMFE_path, inputPeakThreshold);  
    allPeakStatsSession{1,i} = peakStatsSession;
    allPeakStatsSession{2,i} = session; 
end

%%
