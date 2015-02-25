3D-DPM
======

This is an implementation of a 3D DPM as described in my BSc Thesis.
The implementation is based on DPM voc-release 3&4. 


Installing Datasets and 3rd Party Software
==========================================
All the data should be placed in a separete directory specified in 
setUpGlobals.m (variable Datadir).
Install the following 3rd party software and data sets into 
Datadir/3rd_party

Datasets:
- Pascal VOC2007: http://pascallin.ecs.soton.ac.uk/challenges/VOC/voc2007/
- Pascal3D+: http://cvgl.stanford.edu/projects/pascal3d.html
- 3D Object Dataset: http://www.vision.caltech.edu/savarese/3Ddataset.html

Software:
- VL_Feat: http://www.vlfeat.org
- MatconvNet: http://www.vlfeat.org/matconvnet/

The CAD examples used during training should be placed in: 
Datadir/data/perspectiveCADblack

The imagenet-vgg-f CNN from http://www.vlfeat.org/matconvnet/pretrained/
should be placed in:
Datadir/data/cnn

Basic Usage:
============
To train and evaluate a model:

1. Start matlab and cd to this directory.
2. Run compile.m to compile c++ helper functions and the learning code.
3  Run trainAndTest3DDPM.m

This will train and evaluate models with 4, 8 and 16 views. The results of 
the experiments will be saved to Datadir/tmp/experiments/results and the 
final models can be found under Datadir/tmp/voccache (i.e. car_final_8.mat 
would be the 8 viewpoint model).

To run the experiments leading to the main results of the thesis, run the 
runExperiments.m script. Results will be saved in Datadir/tmp as well. 

To run the experiments on the cluster you can simply submit the 
trainAndTest3DDPM.sub script. This way the experiments will be run on one
one node using 12 parallel workers.