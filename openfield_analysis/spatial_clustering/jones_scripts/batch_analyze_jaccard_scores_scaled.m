

%path to cell key 

%cell_key = readtable('/Volumes/My_Passport/cnmfe_analysis_files/batch_output_files/cnmfe_key.csv', 'ReadVariableNames', true); 

%base data dir

%dataDirectory = '/projects/p30771/miniscope/analysis/OpenFieldAnalysis/spatial_clusters/jones_script_analysis/data/ko/' ;

% sessions = {{'GRIN011_H10_M19_S59';1.02}}

% scales:
% f=12, 0.9
% f=15, 0.96
% f=20, 1.02
%input sessions
%create variable for sdThreshold beforehand
%loop over sessions
size_array = size(sessions);
%save array with pixel scales for each indiv session
%maybe save a tuple with session name and pixel scale values

%structure to store data
batchData = cell(size_array(1,1), 1);

for session = 1:size_array(1,1);
	disp('loading');
	disp(sessions{session, :}{1});
	% inputs = (dataDir, session, regExp,  sdThreshold, pixelScale, maxDist, binSize,  option to pad peaks, )
	% regExp e.g. = 'movement_regions_C_traces_filtered.csv', 'rest_regions_C_traces_filtered.csv'
	
	sessionOutput = jaccard_compute_fn_jjm(dataDirectory, sessions{session, :}{1}, regExp, sdThreshold, sessions{session, :}{2}, 500, 20, true);
	batchData{session, 1} = sessionOutput ;
end

disp('done') ; 
