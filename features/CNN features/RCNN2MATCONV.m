net.layers{1}.filters=rcnn_model.cnn.layers(1).weights{1,1};
net.layers{1}.biases=rcnn_model.cnn.layers(1).weights{2,1};

net.layers{5}.filters=rcnn_model.cnn.layers(2).weights{1,1};
net.layers{5}.biases=rcnn_model.cnn.layers(2).weights{2,1};

net.layers{9}.filters=rcnn_model.cnn.layers(3).weights{1,1};
net.layers{9}.biases=rcnn_model.cnn.layers(3).weights{2,1};

net.layers{11}.filters=rcnn_model.cnn.layers(4).weights{1,1};
net.layers{11}.biases=rcnn_model.cnn.layers(4).weights{2,1};

net.layers{13}.filters=rcnn_model.cnn.layers(5).weights{1,1};
net.layers{13}.biases=rcnn_model.cnn.layers(5).weights{2,1};

net.normalization.averageImage=rcnn_model.cnn.image_mean;

layers=net.layers;
classes=net.classes;
normalization=net.normalization;
save('../data/cnn/r-cnn_ILSVRC.mat','layers','classes','normalization');
