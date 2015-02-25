function [ modelVec ] = model2Vector( model )
% Converts the model into vector format which can be used as input to an
% SVM solver. The vector is a concatenation of the parameter-vectors of one
% mixture-component. The format of a mixture component is as follows:
% - offset
% - rootfilter
% for all parts:
%   - partfilters
%   - deformations


for i=1:model.numcomponents
    ridx{i}=model.components{i}.rootindex;
    oidx{i}=model.components{i}.offsetindex;
    root{i} = model.rootfilters{ridx{i}}.w;
    rsize{i} = [size(root{i},1) size(root{i},2)];

    for j=1:size(model.components{i}.parts,2)
        pidx{i,j} = model.components{i}.parts{j}.partindex;
        didx{i,j} = model.components{i}.parts{j}.defindex;
        part{i,j} = model.partfilters{pidx{i,j}}.w;
        psize{i,j} = [size(part{i,j},1) size(part{i,j},2)];
    end
end

index=1;
for i=1:model.numcomponents
    % offset
    blOffset=model.offsets{oidx{i}}.blocklabel;
    sizeBlock=model.blocksizes(blOffset);
    modelVec(index:index+sizeBlock-1)=model.offsets{oidx{i}}.w;
    index=index+sizeBlock;
    %rootfilter
    blRoot=model.rootfilters{ridx{i}}.blocklabel;
    sizeBlock=model.blocksizes(blRoot);
    f = root{i}(1:1+rsize{i}(1)-1, 1:1+rsize{i}(2)-1, :);
    modelVec(index:index+sizeBlock-1)=f;
    index=index+sizeBlock;
    for j=1:size(model.components{i}.parts,2)
        blPart=model.partfilters{pidx{i,j}}.blocklabel;
        sizeBlock=model.blocksizes(blPart);
        modelVec(index:index+sizeBlock-1)=part{i,j}(1:1+psize{i,j}(1)-1, 1:1+psize{i,j}(2)-1, :);
        index=index+sizeBlock;
        blDef=model.defs{pidx{i,j}}.blocklabel;
        sizeBlock=model.blocksizes(blDef);
        modelVec(index:index+sizeBlock-1)=model.defs{pidx{i,j}}.w;
        index=index+sizeBlock;     
    end    
end

end