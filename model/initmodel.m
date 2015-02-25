function model = initmodel(pos, featureDim, sbin, size)
% model = initmodel(pos, sbin, size)
% Initialize model structure.
%
% If not supplied the dimensions of the model template are computed
% from statistics in the postive examples.

globals;

% pick mode of aspect ratios
h = [pos(:).y2]' - [pos(:).y1]' + 1;
w = [pos(:).x2]' - [pos(:).x1]' + 1;
xx = -2:.02:2;
filter = exp(-[-100:100].^2/400);
aspects = hist(log(h./w), xx);
aspects = convn(aspects, filter, 'same');
[peak, I] = max(aspects);
aspect = exp(xx(I));

% pick rootSizeFactor percentile area
areas = sort(h.*w);
area = areas(floor(length(areas) * 0.2));
area = max(min(area, maxRootArea), minRootArea);  % constrain root-size

% pick dimensions
w = sqrt(area/aspect);
h = w*aspect;
model.featureDim=featureDim;
model.featPad=featPad;

% size/stride of features
if nargin < 3
  model.sbin = 8;
else
  model.sbin = sbin;
end

% size of root filter
if nargin < 4
  model.rootfilters{1}.size = [floor(h/model.sbin) floor(w/model.sbin)];
else
  model.rootfilters{1}.size = size;
end

% set up offset 
model.offsets{1}.w = 0;
model.offsets{1}.blocklabel = 1;
model.blocksizes(1) = 1;
model.regmult(1) = 0;
model.learnmult(1) = 20;
model.lowerbounds{1} = -100;

% set up root filter
model.rootfilters{1}.w = zeros([model.rootfilters{1}.size featureDim]);
height = model.rootfilters{1}.size(1);
width = model.rootfilters{1}.size(2);
model.rootfilters{1}.blocklabel = 2;
model.blocksizes(2) = width * height * featureDim;
model.regmult(2) = 1;
model.learnmult(2) = 1;
model.lowerbounds{2} = -100*ones(model.blocksizes(2),1);

% set up one component model
model.components{1}.rootindex = 1;
model.components{1}.offsetindex = 1;
model.components{1}.parts = {};
model.components{1}.dim = 2 + model.blocksizes(1) + model.blocksizes(2);
model.components{1}.numblocks = 2;

% initialize the rest of the model structure
if cnn
    model.interval = 5;
else
    model.interval = 10;
end
model.numcomponents = 1;
model.numblocks = 2;
model.partfilters = {};
model.defs = {};
model.maxsize = model.rootfilters{1}.size;
model.minsize = model.rootfilters{1}.size;
model.cnn=cnn;
model.extraLevel=extraLevel;

