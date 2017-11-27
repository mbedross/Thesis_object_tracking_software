function [I] = import4D(dataDir, zSorted, times, zRange, tRange)

global type n

% Define the range in z-steps to use in training (this is because using the
% entire z-stack will be too RAM heavy)
zSorted(zSorted > zRange(2)) = [];
zSorted(zSorted < zRange(1)) = [];
zNF = length(zSorted);

% Find how many time sequences exist
%filePath = dir(fullfile(dataDir, 'MeanStack', char(type), sprintf('%0.2f', zSorted(1))));
%tNF = length(filePath(not([filePath.isdir])));  % number of time sequeces
times(times > tRange(2)) = [];
times(times < tRange(1)) = [];
tNF = length(times);

% Begin loading images into dTrain
I = uint8(zeros(n, n, zNF, tNF));
% to avoid constantly changing working directories, dTrain will be
% populated by z first (e.g. all times for z = zLow will be imported than z
% = zLow+zStep, on and on)
for i = 1: zNF
    reconPath = fullfile(dataDir, 'MeanStack', char(type), sprintf('%0.2f', zSorted(i)));
    for t = 1 : length(times)
        I(:, :, i, t) = imread(fullfile(reconPath, sprintf('%05d.tiff', times(t))));
    end
end