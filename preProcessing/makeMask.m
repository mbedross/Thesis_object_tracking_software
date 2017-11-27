function [mask] = makeMask(N, innerRadius, outerRadius, centerx, centery)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Manuel Bedrossian
% Date Created: 2017.08.18
% Date Last Modified: 2017.08.18
%
% This function creates a mask of 0's and 1's to be used in the frequency
% filtering of images (ifft(mask) gets convolved with an image)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[x, y] = meshgrid((1:N), (1:N));
mask = zeros(N,N);
mask((x-centerx).^2 + (y-centery).^2 < outerRadius^2) = 1;
mask((x-centerx).^2 + (y-centery).^2 < innerRadius^2) = 0;