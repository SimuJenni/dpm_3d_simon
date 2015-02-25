function [mutmp,sigmatmp]=computeMeanFeature(type)
globals;
pascal_init;
ids = textread(sprintf(VOCopts.imgsetpath, 'trainval'), '%s');
ex = [];
numneg = 0;    
for i = 1:length(ids);
    if mod(i, 500) == 0
        fprintf('%s: parsing examples: %d/%d\n', cls, i, length(ids));
    end 
    rec = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
    numneg = numneg+1;
    ex(numneg).im = [VOCopts.datadir rec.imgname];
end

% Computes mean feature vector on training examples
steps=8;
d=(featureDim-1)/steps;
for j=1:steps
    X=[];
    for i=1:10000
        fprintf('computing feature mean:%d/%d\n', i, length(ex));
        im=imread(ex(i).im);
        f=featureExtractor(im);
        f=f(:,:,(j-1)*d+1:j*d);
        f=permute(f,[3 1 2]);
        X=[X,f(:,:)];
    end
    mutmp=mean(X');
    sigmatmp = std(X');
    mutmp=permute(mutmp,[3 1 2]);
    sigmatmp=permute(sigmatmp,[3 1 2]);
    m((j-1)*d+1:j*d)=mutmp;
    s((j-1)*d+1:j*d)=sigmatmp;
end
mu(1,1,:)=m(1,:);
sigma(1,1,:)=s(1,:);
save(type,'mu','sigma');
end




