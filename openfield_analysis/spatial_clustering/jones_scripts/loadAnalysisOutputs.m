

%should be able to load up the output from the "All Frames" folder and the
%"Frames Subset" folder

%then check that the frames from "Frames Subset" folder match with frames
%in "All Frames" folder


%% Iterate through the cell arrays in the second row for "All Frames" data
for i = 1:size(analysisOutputs, 2)
    % Check if the current cell is not empty
    if ~isempty(analysisOutputs{2, i})
        % Create an empty cell array to store loaded data
        loadedData = cell(size(analysisOutputs{2, i}));

        % Iterate through the list of files in the current cell
        for j = 1:numel(analysisOutputs{2, i})
            % Load the CSV file
            disp(currentFile)
            currentFile = analysisOutputs{2, i}{j};
            data = csvread(currentFile);  % You can adjust this based on your file format

            % Store the loaded data in the cell array
            loadedData{j} = data;
        end

        % Store the loaded data in the third row
        analysisOutputs{3, i} = loadedData;
    end
end
%% Iterate through the cell arrays in the second row for "Frames Subset" data
% Iterate through the cell arrays in the second row
for i = 1:size(analysisOutput, 2)
    % Check if the current cell is not empty
    disp(analysisOutput{1, i})
    if ~isempty(analysisOutput{2, i})
        % Create an empty cell array to store loaded data
        loadedData = cell(size(analysisOutput{2, i}));

        % Iterate through the inner cell array
        for j = 1:numel(analysisOutput{2, i})
            % Check if the current inner cell is not empty
            if ~isempty(analysisOutput{2, i}{j})
                % Create an empty cell array to store loaded data
                innerLoadedData = cell(size(analysisOutput{2, i}{j}));

                % Iterate through the list of files in the current inner cell
                for k = 1:numel(analysisOutput{2, i}{j})
                    % Load the CSV file as a double matrix
                    currentFile = analysisOutput{2, i}{j}{k};
                    data = csvread(currentFile);  % You can use readmatrix as an alternative

                    % Store the loaded data in the cell array
                    innerLoadedData{k} = data;
                end

                % Store the loaded data in the inner cell array
                loadedData{j} = innerLoadedData;
            end
        end

        % Store the loaded data in the second row
        analysisOutput{2, i} = loadedData;
    end
end

% Now, analysisOutput{2, :} contains nested cell arrays of matrices loaded from the CSV files as doubles
%% load frame subset indices files

framesSubsetDir = 'F:\\JJM\\miniscope_analysis\\dSPNs\\clustering_analysis\\frames_subset_Fri_06_Oct_2023_05_59_10\\';

% Iterate through the cell arrays in the third row
for i = 1:size(analysisOutput, 2)
    % Check if the current cell is not empty
    if ~isempty(analysisOutput{3, i})
        % Create an empty cell array to store loaded data
        loadedData = cell(size(analysisOutput{3, i}));

        % Iterate through the list of files in the current cell
        szArray=size(analysisOutput{3, i});
        numFiles=szArray(1,1);

        for j = 1:numFiles
            % Load the CSV file as a double matrix
            currentFile = analysisOutput{3, i}(j,:);
            disp(currentFile)
            framesSubset = readtable(strcat(framesSubsetDir, currentFile), 'ReadVariableNames', true); 
            numFramesToAnalyze = size(framesSubset);
            frameSubsetIndicies = table2array(framesSubset(:, 2));
            % Store the loaded data in the cell array
            loadedData{j} = frameSubsetIndicies;
        end

        % Store the loaded data in the third row
        analysisOutput{3, i} = loadedData;
    end
end

% Now, analysisOutput{3, :} contains cell arrays of matrices loaded from the CSV files as doubles

%%
% sum the length of all vectors in each cell array in row 3, add to row 4
% Iterate through the cell arrays in the third row
for i = 1:size(analysisOutput, 2)
    % Check if the current cell is not empty
    if ~isempty(analysisOutput{3, i})
        
        totalLength = 0;
        for j=1:size(analysisOutput{3,i}, 1)
        % Variable to store the total length of vectors
            totalLength = totalLength+length(analysisOutput{3,i}{j,1});
        end
        analysisOutput{4, i} = totalLength;

    end
end


