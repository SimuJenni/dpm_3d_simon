% Loads and sets up global variables used throughout the code.

load('opts.mat');

Datadir=globals.Datadir;

% object class
cls=globals.cls;

% file size limit
bytelimit = globals.bytelimit;   % normally 4GB, on cluster 16 GB

% turn visualization of detections on or off
visualize=globals.visualize;

% Chose datasets to use here
useVOC2007=globals.useVOC2007;
use3DDataset=globals.use3DDataset;
usePascal3D=globals.usePascal3D;

% Use flipped positives? 
flipped=globals.flipped;

if(globals.cnn)
    % cnn features 
    featureDim=257;
    sbin=16;
    featureExtractor = cnnFeatureExtractor(Datadir);
    featPad=0;
    cnn=true;
    extraLevel=false;    
else
    % vl_HOG features
    rootSizeFactor=0.2;      
    featureDim=32;
    sbin=8;                  
    featureExtractor = @(im) featuresVL( im, sbin );
    featPad=0;
    cnn=false;
    extraLevel=globals.extraLevel;
end

% Using positives as negative examples? (mainly for cnn-features...)
posAsNeg=globals.posAsNeg;     

% constraints on root size
if(cnn)
    maxRootArea=55*sbin^2;
    minRootArea=50*sbin^2;
else
    maxRootArea=72*sbin^2;
    minRootArea=62*sbin^2;
end

% number of elevations used to train the model
numElev=globals.numElev;          

% number of 3D parts
numParts=globals.numParts;

% maximum number of parts per mixture components
partsPerComp=globals.partsPerComp;

% directory for caching models and intermediate data
cachedir = globals.cachedir;
if exist(cachedir) == 0
  unix(['mkdir -p ' cachedir]);
  if exist([cachedir 'learnlog/']) == 0
    unix(['mkdir -p ' cachedir 'learnlog/']);
  end
end

% directory for LARGE temporary files created during training
tmpdir = globals.tmpdir;
if exist(tmpdir) == 0
  unix(['mkdir -p ' tmpdir]);
end

% directory for experiment data and results
expdir = globals.expdir;
if exist(expdir) == 0
  unix(['mkdir -p ' expdir]);
  datapath=[expdir '/data'];
  unix(['mkdir -p ' datapath]);
  unix(['mkdir -p ' datapath '/VOC2007']);
  unix(['mkdir -p ' datapath '/VOC2012']);
  unix(['mkdir -p ' datapath '/3DDataset']);
  resultpath=[expdir '/results'];
  unix(['mkdir -p ' resultpath]);
  unix(['mkdir -p ' resultpath '/VOC2007']);
  unix(['mkdir -p ' resultpath '/VOC2012']);
  unix(['mkdir -p ' resultpath '/3DDataset']);
end

% 3dDataset
Dataset3D=globals.Dataset3D;

% Pascal3D+ Dataset
Pascal3D=globals.Pascal3D;

% dataset to use
if exist('setVOCyear') == 1
  VOCyear = setVOCyear;
  clear('setVOCyear');
else
  VOCyear = '2012';
end

% directory with PASCAL VOC development kit and dataset
VOCdevkit = [Pascal3D '/PASCAL/VOCdevkit/'];