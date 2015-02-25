function pyra = featpyramid(im, model, featureExtractor, cnn)
% [feat, scale] = featpyramid(im, sbin, interval);
% Compute feature pyramid.
%
% sbin is the size of a feature cell / stride - it should be even.
% interval is the number of scales in an octave of the pyramid.
% feat{i} is the i-th level of the feature pyramid.
% scale{i} is the scaling factor used for the i-th level.
% feat{i+interval} is computed at exactly half the resolution of feat{i}.
% first octave halucinates higher resolution data.

if(nargin<4)
    cnn=false;
end
interval=model.interval;
sbin=model.sbin;

if(cnn)
    oversampleFactor=4;
else
    oversampleFactor=2;
end

if(model.extraLevel)
    oversampleFactor=oversampleFactor*2;
end

sc = 2 ^(1/interval);
imsize = [size(im, 1) size(im, 2)];
imsize = imsize*oversampleFactor/2;
max_scale = 1 + floor(log(min(imsize)/(5*sbin))/log(sc));
pyra.feat = cell(max_scale + interval, 1);
pyra.scales = zeros(max_scale + interval, 1);
pyra.imsize=imsize;

% our resize function wants floating point values
im = double(im);
im=imresize(im,oversampleFactor,'bilinear');
for i = 1:interval
  scaled = resize(im, 1/sc^(i-1));
  % "first" 2x interval
  pyra.feat{i} = featureExtractor(scaled);
  pyra.scales(i) = oversampleFactor/sc^(i-1);
  for j = i:interval:max_scale
    scaled = resize(scaled, 0.5);
    pyra.feat{j+interval} = featureExtractor(scaled);
    pyra.scales(j+interval) = 0.5 * pyra.scales(j);
  end
end
