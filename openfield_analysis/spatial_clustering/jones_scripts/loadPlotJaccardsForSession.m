function [sessionArray] = loadPlotJaccardsForSession(fileArray)
%Inputs: cell array with each sessions nomrmalized Jaccards filename as row

    sessionArray = {} ; 
for i=1:length(fileArray)
    VBinName = fileArray{i,1} ;
    jaccardsVBin = csvread(fileArray{i,1}) ;
    sessionArray{i,1} = VBinName ; 
    sessionArray{i,2} = jaccardsVBin ; 
    figure()
    plot(jaccardsVBin);
    title(VBinName);
end

end