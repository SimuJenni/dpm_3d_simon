function [numAdded, numPositives, scores] = latentPositives(name, t, ...
                    model, pos, fid, featureExtractor, overlap, visualize)
% Generates positive examples by extracting latent detections and writes
% them to the data-file. 
% If the training data is related to a component, only the highest scoring 
% detections for this component will be used. 
% If the training data is annotated with a modelID and pos(i).constrained
% is set to true, the latent part placements will be inferred across all
% views/components. (3d constraints on 3d part-placements)
% Input:    - pos: positive training examples
%           - fid: file-identifier of the data file
%           - featureExtractor: function-handle of a function used to
%             extract features from positive examples
%           - overlap: minimum overlap for latent detections to be accepted
%             as positive examples
% Output:   - numAdded: number of examples added to data file
%           - numPositives(c): Number of positive examples added that
%             correspond to component c

padAmount=1; % Amount of padding used for part-featuremap (in feature dim)

% divide positive examples into set with 3d-constraint annotations and set
% without those.
if(size(model.partfilters,2)==0)
    posUnconstrained=pos;
else
    L=[pos(:).constrained]';
    pos3DConstrained=pos(L);
    posUnconstrained=pos(~L);
end

% Get latent detections on unanotated examples
[numAdded, numPositives, scores] = poslatent(name, t, model, posUnconstrained, overlap, fid, visualize);

if(size(model.partfilters,2)>0&&~isempty(pos3DConstrained))
    % cache some model index mappings
    for c=1:model.numcomponents
        ridx(c) = model.components{c}.rootindex;
        oidx(c) = model.components{c}.offsetindex;
        rblocklabel(c) = model.rootfilters{ridx(c)}.blocklabel;
        oblocklabel(c) = model.offsets{oidx(c)}.blocklabel;
        dim(c) = model.components{c}.dim;
        pixels = model.rootfilters{ridx(c)}.size * model.sbin;
        minsize(c) = prod(pixels);
        root{c} = model.rootfilters{ridx(c)}.w;
        rsize{c} = [size(root{c},1) size(root(c),2)];
        numparts{c} = length(model.components{c}.parts);
        for j = 1:numparts{c}
            pidx{c,j} = model.components{c}.parts{j}.partindex;
            didx{c,j} = model.components{c}.parts{j}.defindex;
            part{c,j} = model.partfilters{pidx{c,j}}.w;
            partfilters{c}{j} = model.partfilters{pidx{c,j}}.w;
            psize{c,j} = [size(part{c,j},1) size(part{c,j},2)];
            % reverse map from partfilter index to (component, part#)
            rpidx{pidx{c,j}} = [c j];
        end
    end

    % We have to get the best part-placement in 3D for each car model.
    [posModel, numModels]=splitByModel(pos3DConstrained);
    id=numAdded+1;
    for i=1:numModels
        fprintf('%s: iter %d: latent 3d-constraints: %d/%d\n',...
                    name, t, i, numModels);
        warped = warp2roots(name, model, posModel{i});
        % Extract features from the warped image regions
        for j=1:length(warped)
            comp=warped{j}.component;
            featRoot{comp}=featureExtractor(warped{j}.im1);     
            featPart{comp}=featureExtractor(warped{j}.im2);     
            partmatch{comp} = fconv(featPart{comp}, partfilters{comp}, ...
                                    1, length(partfilters{comp}));    
        end
        
        % Generate 3D-grid box of possible part placements and sum up
        % part-scores at each position of each mixture-component
        size3dBB=model.size3dBox+2*padAmount;   % 3d box is padded
        box3d=zeros(size3dBB);   
        parts = get3DpartInfo(model);
        for n=1:length(parts)  
            fprintf('computing part scores: %d/%d\n',n, length(parts));    
            partBox=zeros(parts{n}.size3dBox);
            score=convn(box3d,partBox,'valid');  % generates the grid
            for z = 1:size(score,1)
                for x = 1:size(score,2)
                    for y = 1:size(score,3)
                        % Change of coordinates: Move origin from corner to
                        % center of the 3D box
                        xc=x-size(box3d,2)/2+size(partBox,2)/2-1;
                        yc=y-size(box3d,3)/2+size(partBox,3)/2-1;
                        zc=z-size(box3d,1)/2+size(partBox,1)/2-1;
                        for k=1:size(parts{n}.filteridx,2)
                            I=rpidx{parts{n}.filteridx(k)};
                            score(z,x,y)=score(z,x,y)+computeScore(xc,yc,...
                                -zc,model, partmatch{I(1)}{I(2)},...
                                parts{n}.filteridx(k), padAmount); 
                        end
                    end
                end
            end
            
             % pick best part-position
            [M,I] = max(score(:));
            [I1,I2,I3] = ind2sub(size(score),I);   
            % Transform coordinates of best part placement
            xs(n)=I2-size(box3d,2)/2+size(partBox,2)/2-1;
            ys(n)=I3-size(box3d,3)/2+size(partBox,3)/2-1;
            zs(n)=-(I1-size(box3d,1)/2+size(partBox,1)/2-1);
            vs(n) = M;      
            score(:,:,:)=0;    
        end
        if(visualize)
            visualizePlacement(model, warped, parts, xs, ys, zs, rpidx, padAmount);
        end
        % write examples to file and compute the score of each individual
        % example
        [numAdded, numPositives, id, scores] = writeExamples(model, fid,...
            featRoot, featPart, parts, xs, ys, zs, id, numAdded, ...
            numPositives, rpidx, padAmount, scores);    
    end

end

function visualizePlacement(model, warped, parts, xs, ys, zs, rpidx, padAmount)
% Visualizes the latent placemet across views. (for debugging)

for c=1:model.numcomponents
    sizeIm=size(warped{c}.im2);
    x1=model.sbin;
    y1=model.sbin;
    x2=sizeIm(2)-model.sbin;
    y2=sizeIm(1)-model.sbin;
    boxes{warped{c}.component}{1}=[x1, y1, x2, y2];
end
for n=1:length(parts)
    for k=1:size(parts{n}.filteridx,2)
        pidx=parts{n}.filteridx(k);
        I=rpidx{parts{n}.filteridx(k)};
        comp=I(1);
        projMat=model.defs{pidx}.projectMat;
        partSize=size(model.partfilters{pidx}.w);
        width=partSize(2);
        height=partSize(1);
        posInW=projMat*[xs(n), ys(n), zs(n), 1]';
        xInF=posInW(1)+padAmount+model.featPad;
        yInF=posInW(2)+padAmount+model.featPad;
        x1=model.sbin*(xInF);
        y1=model.sbin*(yInF);
        x2=model.sbin*(xInF+width);
        y2=model.sbin*(yInF+height);
        boxes{comp}{1}(end+1:end+4)=[x1 ,y1 ,x2 ,y2];
    end
end
for c=1:model.numcomponents
    im=uint8(warped{c}.im2);
    showboxes(im,boxes{warped{c}.component});
    pause(1);
end


function [numAdded, numPositives, id, scores] = writeExamples(model, fid, ...
    featRoot, featPart, parts, xs, ys, zs, id, numAdded, numPositives,...
    rpidx, padAmount, scores)
% Writes the examples with the best 3d-constrained part-placements to the 
% data file and returns the score of each written example

for n=1:length(parts)
    for k=1:size(parts{n}.filteridx,2)
        pidx=parts{n}.filteridx(k);
        I=rpidx{parts{n}.filteridx(k)};
        comp=I(1);
        projMat=model.defs{pidx}.projectMat;
        partSize=size(model.partfilters{pidx}.w);
        width=partSize(2);
        height=partSize(1);
        posInW=projMat*[xs(n), ys(n), zs(n), 1]';
        xInW=round(posInW(1)+1);
        yInW=round(posInW(2)+1);
        xInF=xInW+padAmount;
        yInF=yInW+padAmount;
        pFeat{pidx}.f=featPart{comp}(yInF:yInF+height-1,xInF:xInF+width-1,:);
        anchor = model.defs{pidx}.anchor;
        anchVec=[anchor 1];
        anchorProj=projMat*anchVec';  
        ax = round(anchorProj(1)+1);
        ay = round(anchorProj(2)+1);
        pFeat{pidx}.def = -[(ax-xInW)^2; ax-xInW; (ay-yInW)^2; ay-yInW];
    end
end
for c=1:model.numcomponents
    ridx = model.components{c}.rootindex;
    oidx = model.components{c}.offsetindex;
    rblocklabel = model.rootfilters{ridx}.blocklabel;
    oblocklabel = model.offsets{oidx}.blocklabel;
    ex = [];
    ex.header = [1; id; 0; 0; 0; model.components{c}.numblocks; ...
               model.components{c}.dim];    
    ex.offset.bl = oblocklabel;
    ex.offset.w = 1;
    ex.root.bl = rblocklabel;
    ex.root.w=featRoot{c};
    ex.part = [];
    idx=numAdded+1;
    % computing the score of the example
    rf{1}=model.rootfilters{ridx}.w;
    s=fconv(featRoot{c},rf,1,1);
    scores(idx)=s{1};
    scores(idx)= scores(idx)+model.offsets{oidx}.w;
    for j = 1:length(model.components{c}.parts)
        pidx=model.components{c}.parts{j}.partindex;
        pblocklabel = model.partfilters{pidx}.blocklabel;
        dblocklabel = model.defs{pidx}.blocklabel;
        ex.part(j).bl = pblocklabel;
        ex.part(j).w = pFeat{pidx}.f;
        ex.def(j).bl = dblocklabel;
        ex.def(j).w = pFeat{pidx}.def;
        pf{1}=model.partfilters{pidx}.w;
        s=fconv(pFeat{pidx}.f,pf, 1,1);
        scores(idx)=scores(idx)+s{1};
        scores(idx)=scores(idx)+dot(pFeat{pidx}.def,model.defs{pidx}.w);
    end
    exwrite(fid, ex);
    id=id+1;
    numAdded=numAdded+1;
    numPositives(c)=numPositives(c)+1;
end

function exwrite(fid, ex)
% write an example to the data file

fwrite(fid, ex.header, 'int32');
buf = [ex.offset.bl; ex.offset.w(:); ...
       ex.root.bl; ex.root.w(:)];
fwrite(fid, buf, 'single');
for j = 1:length(ex.part)
  if ~isempty(ex.part(j).w)
    buf = [ex.part(j).bl; ex.part(j).w(:); ...
           ex.def(j).bl; ex.def(j).w(:)];
    fwrite(fid, buf, 'single');
  end
end    

function [posModel, numModels]=splitByModel(pos)
models=unique([pos(:).modelID]');
numModels=size(models,1);
for i=1:numModels
    I=[pos(:).modelID]'==models(i);
    posModel{i}=pos(I);
end

function parts = get3DpartInfo(model)
filteridx=cell(model.numparts,1);
for i=1:length(model.partfilters)
    pIds(i)=model.partfilters{i}.partID;
    shapeSize{pIds(i)}=model.partfilters{i}.size3dBox;
    filteridx{pIds(i)}(end+1)=i;
end
pIds=unique(pIds);
numDiffParts=size(pIds,2);
for i=1:numDiffParts
    parts{i}.filteridx=filteridx{pIds(i)};
    parts{i}.size3dBox=shapeSize{pIds(i)};
end

function score=computeScore(x,y,z,model, partmatch, pidx, padAmount)
    pMat=model.defs{pidx}.projectMat;
    posInW=pMat*[x,y,z,1]';
    xInW=round(posInW(1)+1);
    yInW=round(posInW(2)+1);
    score=partmatch(yInW+padAmount,xInW+padAmount);
    anchor = model.defs{pidx}.anchor;
    anchVec=[anchor 1];
    anchorProj=pMat*anchVec';  
    ax = round(anchorProj(1)+1);
    ay = round(anchorProj(2)+1);
    def = -[(ax-xInW)^2; ax-xInW; (ay-yInW)^2; ay-yInW];
    defScore=model.defs{pidx}.w*def;
    score=score+defScore;
           
           
 
