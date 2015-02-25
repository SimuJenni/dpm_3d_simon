function [angles, elevs]=getViewpoints(numComp, numElev)
% Computes the viewpoints the model will be trained on based on the number
% of components and the number of different elevations used.

angles=[0:360/(numComp/numElev):360];
elevations = 2*pi * [0, 0.12, 0.2]/4;
for i=1:numElev
   elevs(i)=elevations(i);  % elevations the model will be trained on
end
end

