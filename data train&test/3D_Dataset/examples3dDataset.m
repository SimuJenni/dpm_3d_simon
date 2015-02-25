function [ pos ] = examples3dDataset(pos)
% Parses positive example from 3dDataset according to the structure defined
% in data3D.m

globals;
numA=8; % num of different angles
numH=2; % num of different heights
numS=3; % num of different scales
elevs=[0, 2 * pi *0.1/4];
angles=[0:7]*2 * pi /8;
idx=length(pos)+1;
numCars=5;  % number of cars for training
numAdd=numCars*numA*numH*numS+idx-1;
for i=1:numCars   % use cars 1:5 for training and 6-10 for testing!
    carFolder=[Dataset3D 'car_' num2str(i) '/'];
    for j=1:numA
        for k=1:numH
            for l=1:numS
                if(i>=7)
                    imPath=[carFolder 'car' num2str(i) '_A' num2str(j) '_H' num2str(k) '_S' num2str(l) '.bmp'];
                    maskPath=[carFolder 'mask/' 'car' num2str(i) '_A' num2str(j) '_H' num2str(k) '_S' num2str(l) '.mask'];
                else
                    imPath=[carFolder 'car_A' num2str(j) '_H' num2str(k) '_S' num2str(l) '.bmp'];
                    maskPath=[carFolder 'mask/' 'car_A' num2str(j) '_H' num2str(k) '_S' num2str(l) '.mask'];
                end
                fprintf('%s: parsing positives 3D-Dataset: %d/%d\n', cls, idx, numAdd);
                pos(idx).im=imPath;
                pos(idx).angle=angles(mod(j+3,8)+1);
                pos(idx).elev=elevs(k);
                pos(idx).modelID=NaN;
                [Data, Size] = ReadPointsData(maskPath);
                I=find(Data(:,:)>0);
                [I,J]=ind2sub(size(Data),I);
                pos(idx).x1=min(J);
                pos(idx).x2=max(J);
                pos(idx).y1=min(I);
                pos(idx).y2=max(I);
                pos(idx).trunc = false;
                pos(idx).flip=false;
                pos(idx).numInstances=1;
                pos(idx).occluded=false;
                idx=idx+1;
            end
        end
    end
end

