function [ pos ] = voc2007( pos, flippedpos )
% Get positive examples from VOC2007. 
% If flippedpos=true flipped positves will be used.
% numpos must be the  

globals; 
numpos=length(pos);
VOCdevkit = [Datadir '/3rd_party/VOCdevkit/'];
pascal_init;

if nargin < 2
  flippedpos = false;
end

% positive examples from train+val
ids = textread(sprintf(VOCopts.imgsetpath, 'trainval'), '%s');
for i = 1:length(ids);
if mod(i, 100) == 0
    fprintf('%s: parsing positives VOC2007: %d/%d\n', cls, i, length(ids));
end
rec = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
clsinds = strmatch(cls, {rec.objects(:).class}, 'exact');
% skip difficult examples
diff = [rec.objects(clsinds).difficult];
clsinds(diff) = [];
for j = clsinds(:)'
  numpos = numpos+1;
  pos(numpos).im = [VOCopts.datadir rec.imgname];
  bbox = rec.objects(j).bbox;
  pos(numpos).x1 = bbox(1);
  pos(numpos).y1 = bbox(2);
  pos(numpos).x2 = bbox(3);
  pos(numpos).y2 = bbox(4);
  pos(numpos).trunc = rec.objects(j).truncated;
  pos(numpos).angle=NaN;
  pos(numpos).elev=NaN;
  pos(numpos).modelID=0;
  pos(numpos).flip=false;
  pos(numpos).occluded=true;
  pos(numpos).numInstances=0;
  if flippedpos
    oldx1 = bbox(1);
    oldx2 = bbox(3);
    bbox(1) = rec.imgsize(1) - oldx2 + 1;
    bbox(3) = rec.imgsize(1) - oldx1 + 1;
    numpos = numpos+1;
    pos(numpos).im = [VOCopts.datadir rec.imgname];
    pos(numpos).x1 = bbox(1);
    pos(numpos).y1 = bbox(2);
    pos(numpos).x2 = bbox(3);
    pos(numpos).y2 = bbox(4);
    pos(numpos).trunc = rec.objects(j).truncated;
    pos(numpos).angle=NaN;
    pos(numpos).elev=NaN;
    pos(numpos).modelID=NaN;
    pos(numpos).flip=true;
    pos(numpos).occluded=true;  
    pos(numpos).numInstances=0;
  end
end
end


