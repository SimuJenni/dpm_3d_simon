function [ grid_extractor ] = cnn_factory( net, lidx, mu, sigma )

net.layers = net.layers(1:lidx-1); % we only need these layers
grid_extractor = @(im) cnn_factory_grid( im, net, mu ,sigma );
end

function [ feat ] = cnn_factory_grid( im, net, mu, sigma )
% Computes CNN features
% 
% input: im: image. It has to be 3 channel RGB image and the range of
%            intensities is [0,255]
%        net: the neural network
%
% output: cnnfeat: the output feature map

im_ = single(im) ; % note: 255 range
sz = size(im_);
im_ = im_ - repmat(net.normPixel,[sz(1),sz(2)]);
% im_=padarray(im_, [16 16], 0);

% extranct layer output
res = vl_simplenn(net, im_);
feat = res(end).x;
feat = bsxfun (@rdivide, bsxfun (@minus, feat, mu), sigma);
feat(:, :, end+1) = 0;
end
