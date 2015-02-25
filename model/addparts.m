function model = addparts(model, numparts, partsPerComp)
% Initializes 3D parts based on high scoring rootfilter responses across
% views. A maximum number of numparts 3D parts will be added to the model
% and each model component will be seeing a maximum of partPerComp parts
% and a minimum of numpart/2 parts.
% Input:    numparts - maximal number of 3d-parts to initialize
%           partsPerComp - max number of partfilters for each 
%                          mixture-component 

globals;
numComp=model.numcomponents;

try 
  load([cachedir cls '_parts_init_' num2str(numComp)]);
catch

[angles, elevs]=getViewpoints(numComp, numElev);

% Fix viewpoints of each component and warp rootfilters to twice its size    
for i=1:model.numcomponents
    angle=angles(mod(i-1,numComp/numElev)+1);
    elev=elevs(floor((i-1)/(numComp/numElev))+1);
    model.components{i}.angle=angle;
    model.components{i}.elev=elev;
    ridx{i}=model.components{i}.rootindex;
    rootfilter{i}=imresize(model.rootfilters{ridx{i}}.w,2,'bicubic');
end

% Constructing 3D bounding box based on rootfilter sizes of front and right
% view of the model
frontComp=1;             
rightComp=numComp/(numElev*4)+1;
weights{frontComp}=rootfilter{frontComp};
weights{rightComp}=rootfilter{rightComp};
height3DBox=max(size(weights{frontComp},1),size(weights{rightComp},1));    
weights{frontComp}=imresize(weights{frontComp},[height3DBox,NaN]);
weights{rightComp}=imresize(weights{rightComp},[height3DBox,NaN]);
energyBox=zeros(size(weights{frontComp},1),size(weights{frontComp},2),size(weights{rightComp},2));
model.size3dBox=size(energyBox);

% Choosing possible part boxes
volume = 0.8*numel(energyBox) / numparts; % volume occupied by each part
numShapes = 0;
dL=round(0.25*volume^(1/3));
for h = 3:1:size(energyBox, 1)-2
    for w = 3:1:size(energyBox, 2)-2
        for d=3:size(energyBox,3)-2
            % constraints on shapes
            if (w*h*d <= volume*1.2 && w*h*d >= 0.8*volume && ...
            w >= h-dL && w <= h+dL && h >= w-dL && h <= w+dL ...
            && d>=h-dL && d<=h+dL && d>=w-dL && d<=w+dL)
            numShapes = numShapes+1;
            shapes{numShapes}=[h w d];
            template{numShapes}.x = fspecial('average', [h w]);
            template{numShapes}.y = fspecial('average', [h d]);
            end
        end
    end
end

% picking parts
numadded = 0;
while numadded < numparts
fprintf('Choosing part %d/%d\n', numadded+1, numparts);

  for i = 1:numShapes
    % Create a score box/grid of possible part placements inside the 3D box
    B=ones(shapes{i}(1),shapes{i}(2),shapes{i}(3));
    energyBoxCord=getBBcoordFromSize(size(energyBox));
    shapeBoxCord{i}=getBBcoordFromSize(shapes{i});
    score=convn(energyBox,B,'valid');
    fprintf('Computing part-shape score: %d/%d\n', i, numShapes);
    for z = 1:size(score,1)
        for x = 1:size(score,2)
            for y = 1:size(score,3)
                for comp=1:model.numcomponents  
                    % Change of coordinates: Moves origin from corner of 3d
                    % box to its center
                    xc=x-size(energyBox,2)/2+shapes{i}(2)/2-1;
                    yc=y-size(energyBox,3)/2+shapes{i}(3)/2-1;
                    zc=z-height3DBox/2+shapes{i}(1)/2-1;
                    score(z,x,y)=score(z,x,y)+computeScore(xc,yc,-zc,model,energyBoxCord,shapeBoxCord{i}, comp, rootfilter{comp});  
                end
            end
        end
    end
    
    % pick best part with this shape
    [M,I] = max(score(:));
    [I1,I2,I3] = ind2sub(size(score),I);   
    % Again change of coordinates into center of 3D box
    xs(i)=I2-size(energyBox,2)/2+shapes{i}(2)/2-1;
    ys(i)=I3-size(energyBox,3)/2+shapes{i}(3)/2-1;
    zs(i)=I1-height3DBox/2+shapes{i}(1)/2-1;
    vs(i) = M;
  end
  
  % pick best part, over all shapes
  [maxScore, i] = max(vs);
  
  % Delete the region occupied by the chosen part from the energyBox so
  % that we ommit overlapping 3d-parts
  energyBox=deleteFromBox(xs(i),ys(i),zs(i), i, template, energyBox, maxScore);
  numadded = numadded + 1;
  
  % save part info
  parts{numadded}.xAnc=xs(i);
  parts{numadded}.yAnc=ys(i);
  parts{numadded}.zAnc=-zs(i);
  parts{numadded}.shapeBoxCord=shapeBoxCord{i};
  parts{numadded}.shape=shapes{i};
  parts{numadded}.partID=numadded;
end

% add parts
for c=1:model.numcomponents
  model=chooseParts(model, parts, energyBoxCord, c, rootfilter{c}, partsPerComp);
end

% Check how many 3d parts have actually been chosen and write number to
% model
for i=1:length(model.partfilters)
    pIds(i)=model.partfilters{i}.partID;
end
pIds=unique(pIds);
numDiffParts=size(pIds,2);
model.actualNumParts=numDiffParts;
model.numparts=numparts;
fprintf('%d 3D parts added to the model, %d parts per mixture component \n', numDiffParts, partsPerComp);
save([cachedir cls '_parts_init_' num2str(numComp)], 'model');
end

% Adjust the lowerbounds and initialisation of defs for CNN-features
if cnn  
      for i=1:length(model.defs)
          model.defs{i}.w=[1,0,1,0];
          model.lowerbounds{model.defs{i}.blocklabel}=[0.2,-100,0.2,-100];
          model.partfilters{i}.w(:,:,:) = model.partfilters{i}.w(:,:,:)/2;
      end
end
end


% Chooses the highest scoring n(=partsPerComp) parts based on their
% rootfilter-responses and adds them to the model.
function model=chooseParts(model, parts, energyBoxCord, comp, rootFilter, partsPerComp)
    angle=-model.components{comp}.angle;
    elev=model.components{comp}.elev;
    projMat=viewmtx(angle,elev);
    A=projMat*energyBoxCord';
    widthEnergy=max(A(1,:))-min(A(1,:));
    heightEnergy=max(A(2,:))-min(A(2,:));
    scaleWidth=size(rootFilter,2)/widthEnergy;
    scaleHeight=size(rootFilter,1)/heightEnergy;
    energy=sum(max(rootFilter,0).^2,3); 
    availableParts=parts;
    numToAdd=round(length(parts)/2);
    enough=false;
    for i=1:partsPerComp
        [part, energy, availableParts] = chooseBest(availableParts, energy, projMat, scaleWidth, scaleHeight, enough);
        if(isempty(part))
            continue;
        else
            numToAdd=numToAdd-1;
            enough=numToAdd<=0;
        end
        model=addPart(model, part, comp, rootFilter, projMat, scaleWidth, scaleHeight);
    end
end

% Choose best part for this rootfilter-energy
function [part, energy, parts] = chooseBest(parts, energy, projMat, scaleWidth, scaleHeight, enough)
    for i=1:size(parts,2)
        B=projMat*parts{i}.shapeBoxCord';
        width(i)=round(scaleWidth*(max(B(1,:))-min(B(1,:))));
        height(i)=round(scaleHeight*(max(B(2,:))-min(B(2,:))));
        posInW=projMat*[parts{i}.xAnc,parts{i}.yAnc,parts{i}.zAnc,1]';
        xInW(i)=round(scaleWidth*posInW(1)+size(energy,2)/2-width(i)/2+1);        
        yInW(i)=round(scaleHeight*-posInW(2)+size(energy,1)/2-height(i)/2+1);
        template = fspecial('average', [height(i) width(i)]);
        score = conv2(energy, template, 'valid');
        if(posInW(3)<0)
            scores(i)=score(yInW(i),xInW(i))/(1-2*posInW(3));
        else
            scores(i)=score(yInW(i),xInW(i));
        end
    end
    [v, pidx]=max(scores);
    if(v<=0&&enough)
        part=[];
        return;
    end
    startY=max(1,yInW(pidx)-1);
    endY=min(size(energy,1),yInW(pidx)+height(pidx));
    startX=max(1,xInW(pidx)-1);
    endX=min(size(energy,2),xInW(pidx)+width(pidx));
    energy(startY:endY,startX:endX)=0;
    part.width=width(pidx);
    part.height=height(pidx);
    part.xInW=xInW(pidx);
    part.yInW=yInW(pidx);
    part.partID=parts{pidx}.partID;
    part.xAnc=parts{pidx}.xAnc;
    part.yAnc=parts{pidx}.yAnc;
    part.zAnc=parts{pidx}.zAnc;
    part.size3dBox=parts{pidx}.shape;
    parts(pidx)=[];
end

% add part to the model with all the needed parameters
function model=addPart(model, part, comp, rootFilter, projMat, scaleWidth, scaleHeight)
    width=part.width;
    height=part.height;
    
    % add partfilter
    pidx = length(model.partfilters) + 1;
    xInW=part.xInW;        
    yInW=part.yInW;
    filter=rootFilter(yInW:yInW+height-1, xInW:xInW+width-1, :);
    model.partfilters{pidx}.w = filter;
    model.partfilters{pidx}.fake = false;
    model.partfilters{pidx}.partner = 0;
    model.partfilters{pidx}.partID = part.partID;
    model.partfilters{pidx}.size3dBox = part.size3dBox;

    % add feature block
    model.numblocks = model.numblocks + 1;
    model.partfilters{pidx}.blocklabel = model.numblocks;
    model.blocksizes(model.numblocks) = width * height * model.featureDim;  
    wsize = model.blocksizes(model.numblocks);
    model.regmult(model.numblocks) = 1;
    model.learnmult(model.numblocks) = 1;
    model.lowerbounds{model.numblocks} = -100*ones(wsize,1);
    
    % add deformation model
    didx = length(model.defs) + 1;
    model.defs{didx}.anchor = [part.xAnc part.yAnc part.zAnc];
    model.defs{didx}.w = [0.1 0 0.1 0];
    
    scaleMat=[scaleWidth, 0, 0, 0;
              0, -scaleHeight, 0, 0;
              0, 0, 1, 0;
              0, 0, 0, 1;];
    projMat=scaleMat*projMat;
    projMat(:,4)=[size(rootFilter,2)/2-width/2,size(rootFilter,1)/2-height/2,0,1];
    model.defs{didx}.projectMat=projMat;
    model.defs{didx}.scaleHeight=scaleHeight;
    model.defs{didx}.scaleWidth=scaleWidth;
    
    model.numblocks = model.numblocks + 1;
    model.defs{didx}.blocklabel = model.numblocks;
    model.blocksizes(model.numblocks) = 4;
    model.regmult(model.numblocks) = 10;
    model.learnmult(model.numblocks) = 0.1;
    model.lowerbounds{model.numblocks} = [0.01 -100 0.01 -100];
    
    % link part to component
    j = length(model.components{comp}.parts) + 1;
    model.components{comp}.parts{j}.partindex = pidx;
    model.components{comp}.parts{j}.defindex = didx;
    model.components{comp}.dim = ...
    model.components{comp}.dim + 6 + wsize;
    model.components{comp}.numblocks = model.components{comp}.numblocks + 2;
end

% Delets regions in the 3d-energy corresponding to added parts.
function energyBox=deleteFromBox(x,y,z, i, template, energyBox, maxScore)
  x=round(x+size(energyBox,2)/2-size(template{i}.x,2)/2+1);
  y=round(y+size(energyBox,3)/2-size(template{i}.y,2)/2+1);
  z=round(z+size(energyBox,1)/2-size(template{i}.x,1)/2+1);
  for xp = x:x+size(template{i}.x,2)-1
      for yp = y:y+size(template{i}.y,2)-1
          for zp=z:z+size(template{i}.x,1)-1
                energyBox(zp, xp, yp) = -maxScore;
          end
      end
  end
end

% Returns vectors corresponding to edges of a 3D-Box of size s and relative
% to the box-center
function BBVectors=getBBcoordFromSize(s)
    BBVectors=[0, 0, 0, 1;...
               0, s(3), 0, 1;... 
               0, 0, -s(1),1; ...
               0, s(3), -s(1), 1;...
               s(2), 0, 0, 1; ...
               s(2), s(3), 0, 1; ...
               s(2), 0, -s(1),1; ...
               s(2), s(3), -s(1), 1;];
end

% Computes the score of this part placement in the 3d-energyBox computed 
% from the rootfilter of component comp.
function score=computeScore(x,y,z,model,energyBoxCord,shapeBoxCord, comp, rootFilter)
    angle=-model.components{comp}.angle;
    elev=model.components{comp}.elev;
    projMat=viewmtx(angle,elev);
    A=projMat*energyBoxCord';
    widthEnergy=max(A(1,:))-min(A(1,:));
    heightEnergy=max(A(2,:))-min(A(2,:));
    scaleWidth=size(rootFilter,2)/widthEnergy;
    scaleHeight=size(rootFilter,1)/heightEnergy;
    energy=sum(max(rootFilter,0).^2,3);  
    B=projMat*shapeBoxCord';
    width=round(scaleWidth*(max(B(1,:))-min(B(1,:))));
    height=round(scaleHeight*(max(B(2,:))-min(B(2,:))));
    posInW=projMat*[x,y,z,1]';
    xInW=round(scaleWidth*posInW(1)+size(energy,2)/2-width/2+1);        
    yInW=round(scaleHeight*-posInW(2)+size(energy,1)/2-height/2+1);
    template = fspecial('average', [height width]);
    scoreTot = conv2(energy, template, 'valid');
    score=scoreTot(yInW,xInW); 
end