function MAIN(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% This is the main function for the machine learning assisted tracking of
% off-axis holographic reconstructions
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global masterDir
masterDir = varargin{1};
if length(varargin) == 2
    global trainDir
    trainDir = varargin{2};
end

% Very often, there is not enough RAM to load the entire xyzt stack to be
% tracked. This means that it must be broken down into a subset of z and t
% sets
zRange = [-7, -6];
tRange = [0, 20];

% Do you want to preProcess the data? 1 = yes, 0 = no
preProcess = 0;

% Do you want to run the training phases? 1 = yes, 0 = no
train = 1;

% Do you want to track? 1 = yes, 0 = no
track = 0;

if length(varargin) ~=2 && train == 0
    error('Without running the training protocol, a file path to training data must be provided. Either variable track must be 1 or more inputs are needed');
end

% Define global variables
global n
n = 2048;

% Define tracking parameters
max_linking_distance = 30;
max_gap_closing = 1;

z_separation = 2.5;

% Define image parameters
pCutoff = 0.005;
minCluster = 10;
cropSize = 15;

% Which type of data do you want to track? Amplitude or Phase?
global type
type = 'Amplitude';

% Add the preprocess and training subdolders to MATLAB search path, and run
% the respective functions if applicable
if preProcess == 1
    addpath('.\preProcessing');
    [times, zSorted] = preProcessingMain(masterDir);
end
if train == 1
    addpath('.\training');
    if preProcess == 0
        load(fullfile(masterDir, 'MeanStack','metaData.mat'));
    end
    [dTrain]    = import4D(masterDir, zSorted, times, zRange, tRange);
    dTrain(:,:,:,2:end) = [];
    [b, Xtrain] = trainingStage1(dTrain);
    [dTrainC]   = trainingStage2(dTrain, b, Xtrain);
    [b]         = trainingStage3(dTrainC);
end
if track == 1
    if train == 0 && length(varargin) == 2
        % If the dataset is already trained, load the model variables
        load(trainDir);
    end
    addpath('/supportingAlgorithms');
    addpath('/createVideos');
    D = dTrain;
    croppedD = cropEdges(D,cropSize);
    D = addEdges(croppedD,cropSize);
    X = zeros(0,9);
    for t = times(1) : times(end)
        for z = 1 : size(D,3)
            if z == 1
                input_slice(:,:,1) = D(:,:,z, times(t));
                input_slice(:,:,2) = D(:,:,z);
            else
                if z == 2
                    input_slice(:,:,1) = D(:,:,z-1, times(t));
                    input_slice(:,:,2) = D(:,:,z-1, times(t));
                else
                    input_slice(:,:,1) = D(:,:,z-2, times(t));
                    input_slice(:,:,2) = D(:,:,z-1, times(t));
                end
            end
            input_slice(:,:,3) = D(:,:,z, times(t));
            if z==dim3
                input_slice(:,:,4) = D(:,:,z, times(t));
                input_slice(:,:,5) = D(:,:,z, times(t));
            else
                if z == dim3-1
                    input_slice(:,:,4) = D(:,:,z+1, times(t));
                    input_slice(:,:,5) = D(:,:,z+1, times(t));
                else
                    input_slice(:,:,4) = D(:,:,z+1, times(t));
                    input_slice(:,:,5) = D(:,:,z+2, times(t));
                end
            end
            X = [X; getInputMatrixV5zs(input_slice)];
        end
        
        %function glmval() is from statistical and machine learning
        %toolbox. It calculates the probability of a pixel being bacteria
        %by the pixel feature matrix 'X' and the weight vector 'b',
        %which was found from training.
        %----------------------------------------
        y = glmval(b,X,'logit');
        %------------------------------------------
        
        D_C = classify(y, pCutoff, minCluster, size(D,1),size(D,2),size(D,3),size(D,4));
        
        points{t} = findCentroids(D_C);
        points2{t} = points{t}*[360/size(D,1) 0 0;0 360/size(D,2) 0;0 0 z_separation];
        %----------------------------------------------------------
        [tracks, adjacency_tracks] = simpletracker(points2, ...
            'MaxLinkingDistance', max_linking_distance, ...
            'MaxGapClosing', max_gap_closing);
        %The function plotTracks, takes as input adjacency tracks and points to
        %to plot the results in a 3D line graph.
        
        plotTracksAndVelocity(adjacency_tracks,points2);
        daspect([1 1 1])
        createTracks
        toc
    end
end