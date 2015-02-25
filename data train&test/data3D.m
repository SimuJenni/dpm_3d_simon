function [pos, neg] = data3D()
% [pos, neg] = pascal_data(cls)
% Get training data from 3D-dataset as well as the Pascal-VOC 2007 and 2012 set.
% Output:  - pos: positive examples with the following fields:
%                 .angle    - viewpoint angle in rad
%                 .elev     - viewpoint elevation in rad
%                 .modelID  - identifies car model
%                 .im       - path to examples image
%                 .x1 .x2 .y1 .y2  - bounding-box coordinates
%                 .trunc    - indicates truncated objects
%                 .occluded
%                 .flip     - if true example gets flipped
%                 .numInstances - #object instances present in image
%          - neg: negative examples with the fiels .im specifying the imagepath       

globals;

try
  load([cachedir cls '_train']);
catch
    
pascal_init;
pos = [];

% Getting positive CAD examples with annotations
% [ pos ] = CADdataPerspective( pos );
[ pos ] = CADPerspectiveMeanPixel( pos );

if(useVOC2007)
    % positive examples from VOC2007
    pos = voc2007( pos, flipped );
end

if(use3DDataset)
    % adding training data from 3d-Dataset
    [ pos ] = examples3dDataset(pos);
end

if(usePascal3D)
    % adding annotated examples from Pascal VOC2012
    numpos=length(pos);
    pos = pascal3Dpos(cls, VOCopts, Pascal3D, pos, numpos, flipped);
end

% % adding annotated examples from Imagenet
% numpos=length(pos);
% pos = imagenet3Dpos(cls, Pascal3D, pos, numpos, flipped);

% negative examples from VOC train-set 
ids = textread(sprintf(VOCopts.imgsetpath, 'train'), '%s');
neg = [];
numneg = 0;

% using badly located positives as negative examples for CNN features
if(cnn)  
    uniquePos=[pos(:).numInstances]==1;
    neg=pos(uniquePos);
    numneg=length(neg);
end
   
% Parse negative examples
for i = 1:length(ids);
    if mod(i, 100) == 0
        fprintf('%s: parsing negatives: %d/%d\n', cls, i, length(ids));
    end 
    rec = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
    clsinds = strmatch(cls, {rec.objects(:).class}, 'exact');
    if isempty(clsinds)
      numneg = numneg+1;
      neg(numneg).im = [VOCopts.datadir rec.imgname];
    end
end
  save([cachedir cls '_train'], 'pos', 'neg');
end  
end
