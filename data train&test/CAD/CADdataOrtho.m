function [ pos ] = CADdataOrtho( pos, numpos )
% Gets positive CAD training examples. 
% Examples are rendered using orthographic projections and on backgrounds
% obtained by negative training images.

globals;
renderedDataPath='../data/synthetic cars/all cars, all view/';
npos=2800;
for i=1:npos
    fprintf('%s: parsing positives CAD: %d/%d\n', cls, i, npos);
    numpos=numpos+1;
    [G, S, pos(numpos).im]=cars_read(i, renderedDataPath); 
    
    % Uses bounding boxes that tightly cover 3D BB-Box. Not tightly cover
    % car boundarys...
    parts=S.X;
    dx=0.15, dy=0.15,dz=0.15;
    shift=[-dx,-dy,-dz;-dx,dy,-dz;-dx,-dy,dz;-dx,dy,dz;dx,-dy,-dz;dx,dy,-dz;dx,-dy,dz;dx,dy,dz]';
    pcenter=parts(:,10);
    p1=bsxfun(@plus,pcenter,shift);
    pIm1=G.P*[p1;ones(1,size(p1,2))];
    pIm=G.P*[parts;ones(1,size(parts,2))];   
    pos(numpos).x1=round(min(pIm(1,:)));
    pos(numpos).x2=round(max(pIm(1,:)));
    pos(numpos).y1=round(min(pIm(2,:)));
    pos(numpos).y2=round(max(pIm(2,:)));
    im=imread(pos(numpos).im);
    box3D{1}=[pIm(1:2,1)',pIm(1:2,2)',pIm(1:2,3)',pIm(1:2,4)',pIm(1:2,5)',pIm(1:2,6)',pIm(1:2,7)',pIm(1:2,8)'];
    box3D{2}=[pIm1(1:2,1)',pIm1(1:2,2)',pIm1(1:2,3)',pIm1(1:2,4)',pIm1(1:2,5)',pIm1(1:2,6)',pIm1(1:2,7)',pIm1(1:2,8)'];
    showboxes3D(im,box3D); 
    pos(numpos).trunc = false;
    pos(numpos).angle=computeAngle(numpos);
    pos(numpos).elev=computeElev(numpos);
    pos(numpos).modelID=computeCarID(numpos);
    pos(numpos).flip=false;
end
end

% computes angle of positive examples. Computation is based on the order of
% positive examples! 
function angle=computeAngle(numpos)
angle=mod(numpos, 40)*2 * pi * 0.025;
end

% computes elevation of positive examples. Computation is based on the order of
% positive examples! 
function elev=computeElev(numpos)
elevs= 2 * pi * [0, 0.1, 0.25, 0.4, 0.6]/4;
index=mod(floor((numpos-1)/40),5)+1;
elev=elevs(index);
end

% computes car-ID of positive examples. Computation is based on the order of
% positive examples! 
function id=computeCarID(numpos)
id=floor((numpos-1)/200);
end

