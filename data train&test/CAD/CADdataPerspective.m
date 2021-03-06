function [ pos ] = CADdataPerspective( pos )
globals;
numpos=length(pos);
renderedDataPath='../data/perspectiveCAD';
npos=2016;
for i=1:npos
    fprintf('%s: parsing positives CAD: %d/%d\n', cls, i, npos);
    numpos=numpos+1;
    pos(numpos).im = sprintf('%s/car_%d.tif',renderedDataPath,i);
    groundpath = sprintf('%s/car_%d.mat',renderedDataPath,i);
    load(groundpath); % G and S
    pos(numpos).x1=data.bbox(1);
    pos(numpos).x2=data.bbox(3);
    pos(numpos).y1=data.bbox(2);
    pos(numpos).y2=data.bbox(4);
    box{1}=[pos(numpos).x1,pos(numpos).y1,pos(numpos).x2,pos(numpos).y2];
%     im=imread(pos(numpos).im);
%     showboxes(im,box);
    pos(numpos).trunc = false;
    pos(numpos).angle=computeAngle(numpos);
    pos(numpos).elev=computeElev(numpos);
    pos(numpos).modelID=computeCarID(numpos);
    pos(numpos).flip=false;
    pos(numpos).occluded=false;
    pos(numpos).numInstances=0;  % Don't use CAD as negatives for cnn
end


end

% computes angle of positive examples. Computation is based on the order of
% positive examples! 
function angle=computeAngle(numpos)
angle=mod(numpos, 16)*2 * pi * 0.0625;
end

% computes elevation of positive examples. Computation is based on the order of
% positive examples! 
function elev=computeElev(numpos)
elevs= 2 * pi * [0, 0.1, 0.2, 0.3]/4;
index=mod(floor((numpos-1)/16),4)+1;
elev=elevs(index);
end

% computes car-ID of positive examples. Computation is based on the order of
% positive examples! 
function id=computeCarID(numpos)
id=floor((numpos-1)/64);
end

