function [ model, W] = vec2model( model, W )
compIndex=getIndexesOfComponent(model);

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

for i=1:model.numcomponents
    % offset
    index=compIndex(i);
    model.offsets{oidx{i}}.w=W(index);
    index=index+1;
   
    %rootfilter
    blRoot=model.rootfilters{ridx{i}}.blocklabel;
    sizeBlock=model.blocksizes(blRoot);
    model.rootfilters{ridx{i}}.w=reshape(W(index:index+sizeBlock-1), size(model.rootfilters{ridx{i}}.w));
    index=index+sizeBlock;
    
    for j=1:size(model.components{i}.parts,2)
        blPart=model.partfilters{pidx{i,j}}.blocklabel;
        sizeBlock=model.blocksizes(blPart);
        model.partfilters{pidx{i,j}}.w=reshape(W(index:index+sizeBlock-1),size(model.partfilters{pidx{i,j}}.w));
        index=index+sizeBlock;
        blDef=model.defs{pidx{i,j}}.blocklabel;
        sizeBlock=model.blocksizes(blDef);
        W(index:index+sizeBlock-1)=max(W(index:index+sizeBlock-1),model.lowerbounds{blDef});
        model.defs{pidx{i,j}}.w=W(index:index+sizeBlock-1);
        index=index+sizeBlock;     
    end    
end

end

function index=getIndexesOfComponent(model)
index(1)=1;
for c=1:model.numcomponents
    numparts = length(model.components{c}.parts);
    index(c+1)=index(c)+model.components{c}.dim-2*(1+numparts);
end
end

