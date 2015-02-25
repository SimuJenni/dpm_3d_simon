function [ cnnFeatures ] = cnnFeatureExtractor(Datadir)
% load net
net = load([Datadir '/data/cnn/imagenet-vgg-f.mat']);

% adding padding to all the layers. This way we get an easier mapping from
% features to image by (xIm, yIm) = stride*(xFeat, yFeat)
net.layers{1}.pad=[5,5,5,5];
net.layers{4}.pad=[1,1,1,1];
net.layers{8}.pad=[1,1,1,1];

normPixel=mean(mean(net.normalization.averageImage));
net.normPixel=normPixel;

tmp=load('meanCNN.mat');

[ cnnFeat ] = cnn_factory( net, 15, tmp.mu, tmp.sigma );

cnnFeatures=@(im) double(cnnFeat(im));

save('normPixel.mat','normPixel');

end

