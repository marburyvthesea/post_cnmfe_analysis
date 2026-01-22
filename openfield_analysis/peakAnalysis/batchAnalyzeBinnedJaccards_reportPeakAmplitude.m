
CNMFE_path = 'F:\JJM\miniscope_analysis\mGluR5_NAM\clustering_analysis\' ; 

% 'DIO_r2.20_JNJ_15_28_00',

sessions =  {'Vehicle_DIO_r2.7_15_20_30', 'Vehicle_DIO_r2.7_15_51_07', ...
              'Vehicle_DIO_r2.8_16_45_11', 'Vehicle_DIO_r2.8_17_16_03', ...
              'Vehicle_DIO_r2.14_17_25_26', 'Vehicle_DIO_r2.14_17_40_46', 'Vehicle_DIO_r2.14_18_11_01', ...
              'Vehicle_DIO_r2.19_13_45_01', 'Vehicle_DIO_r2.19_14_15_20', ...
              'Fenobam_DIO_r2.7_17_00_12', 'Fenobam_DIO_r2.7_17_30_50', ...
              'Fenobam_DIO_r2.8_16_00_28', 'Fenobam_DIO_r2.8_16_30_39', ...
              'Fenobam_DIO_r2.14_14_00_13', 'Fenobam_DIO_r2.14_14_30_28', ...
              'Fenobam_DIO_r2.19_16_04_27', 'Fenobam_DIO_r2.19_16_34_31'
              } ; 


inputPeakThreshold = 2.5 ; 
inputMicronsPerPixel = 1.85 ; % micronsPerPixel 2.5 = microns (inscopix), 1 (v3), 1.85 (v4)
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

%% all peaks for stats

allPeaksVeh = horzcat(peakData_veh{1,:});
allPeaksFen = horzcat(peakData_fen{1,:});

