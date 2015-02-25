setup;

% Train and evaluate 3D-DPM+
setUpGlobals;
globals.expdir = [Datadir '/tmp/experiments/3D-DPM+/'];
globals.cachedir = [Datadir '/tmp/voccache/3D-DPM+/'];
save('opts.mat','globals');
trainAndTest3DDPM;

% Train and evaluate 3D-DPM on VOC2012
setUpGlobals;
globals.extraLevel=false;
globals.useVOC2007=false;
globals.expdir = [Datadir '/tmp/experiments/VOC2012/'];
globals.cachedir = [Datadir '/tmp/voccache/VOC2012/'];
save('opts.mat','globals');
trainAndTest3DDPM;

% Train and evaluate 3D-DPM on VOC2007
setUpGlobals;
globals.extraLevel=false;
globals.usePascal3D=false;
globals.expdir = [Datadir '/tmp/experiments/VOC2007/'];
globals.cachedir = [Datadir '/tmp/voccache/VOC2007/'];
save('opts.mat','globals');
trainAndTest3DDPM;

% Train and evaluate 3D-DPM CNN
setUpGlobals;
globals.cnn=true;
globals.numParts=16;
globals.partsPerComp=8;
globals.expdir = [Datadir '/tmp/experiments/cnn/'];
globals.cachedir = [Datadir '/tmp/voccache/cnn/'];
save('opts.mat','globals');
trainAndTest3DDPM;

% Train and evaluate 3D-DPM CNN PN
setUpGlobals;
globals.cnn=true;
globals.numParts=16;
globals.partsPerComp=8;
globals.posAsNeg=true;
globals.expdir = [Datadir '/tmp/experiments/cnnPN/'];
globals.cachedir = [Datadir '/tmp/voccache/cnnPN/'];
save('opts.mat','globals');
trainAndTest3DDPM;

% Train and evaluate 3D-DPM with 16 parts and 10 parts per view
setUpGlobals;
globals.numParts=16;
globals.partsPerComp=10;
globals.useVOC2007=false;
globals.expdir = [Datadir '/tmp/experiments/16parts/'];
globals.cachedir = [Datadir '/tmp/voccache/16parts/'];
save('opts.mat','globals');
train3D(4);
evaluateModel(4);

% Train and evaluate 3D-DPM with 12 parts and 8 parts per view
setUpGlobals;
globals.numParts=12;
globals.partsPerComp=8;
globals.useVOC2007=false;
globals.expdir = [Datadir '/tmp/experiments/12parts/'];
globals.cachedir = [Datadir '/tmp/voccache/12parts/'];
save('opts.mat','globals');
train3D(4);
evaluateModel(4);
