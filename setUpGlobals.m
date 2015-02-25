% Set up global variables used throughout the code

% The data directory
% Datadir='..';   
Datadir='/data/cvg/simon'; % Cluster
globals.Datadir=Datadir;

% object class
globals.cls='car';

% file size limit
globals.bytelimit = 24*2^30;   % normally 4GB, on cluster 24 GB

% turn visualization of detections on or off
globals.visualize=false;

% Chose datasets to use here
globals.useVOC2007=true;
globals.use3DDataset=true;
globals.usePascal3D=true;

% Use flipped positives? 
globals.flipped=true;

% Use positves as negative examples?
globals.posAsNeg=false;

% Use CNN features?
globals.cnn=false;

% Use extra pyramid octave?
globals.extraLevel=true;

% number of elevations used to train the model
globals.numElev=1;          

% number of 3D parts
globals.numParts=20;

% maximum number of parts per mixture components
globals.partsPerComp=12;

% directory for caching models and intermediate data
globals.cachedir = [Datadir '/tmp/voccache/'];

% directory for LARGE temporary files created during training
globals.tmpdir = [Datadir '/tmp/var/'];

% directory for experiment data and results
globals.expdir = [Datadir '/tmp/experiments/'];

% 3dDataset
globals.Dataset3D = [Datadir '/3rd_party/3Ddataset/car/'];

% Pascal3D+ Dataset
globals.Pascal3D=[Datadir '/3rd_party/PASCAL3D+_release1.1'];

save('opts.mat','globals');