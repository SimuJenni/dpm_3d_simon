function [dets, boxes, targets] = bboxpred_data(pos, n)
% Collects training data for traning the bounding box predictor.

globals;
featureExtractor=featureExtractor;  % Needed for parfor as it gets confused otherwise
cnn=cnn;
cls='car';

try
  load([cachedir cls '_bboxdata_' num2str(n)]);
catch
  % load final model for class
  load([cachedir cls '_finalNoBB_' num2str(n)]);
  numpos = length(pos);
  model.interval = 5;
  pixels = model.minsize * model.sbin;
  if(extraLevel)
      pixels = pixels/2;  
  end
  if(cnn)
      pixels=pixels/2;
      model.interval = 2;
  end
  minsize = prod(pixels);
  numComp = model.numcomponents;
  parb = cell(1,numpos);
  part = cell(1,numpos);
  overlap = 0.7;
  % compute latent filter locations and record target bounding boxes
  parfor i = 1:numpos
    pard{i} = cell(1,numComp);
    parb{i} = cell(1,numComp);
    part{i} = cell(1,numComp);
    fprintf('%s %s: bboxdata: %d/%d\n', procid(), cls, i, numpos);
    bbox = [pos(i).x1 pos(i).y1 pos(i).x2 pos(i).y2];
    % skip small examples
    if (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1) < minsize
      continue;
    end
    % get example
    im = imreadx(pos(i));
    [im, bbox] = croppos(im, bbox);
    pyra = featpyramid(im, model, featureExtractor, cnn);
    o=overlap;
    if pos(i).occluded==1   % only use 0.5 overlap for occluded examples
        o=0.5;
    end
    [det, boxes] = detect(pyra, model, 0, bbox, o, pos(i).component, false,...
        inf, 1, i, pos(i).compCoarse, pos(i).trunc, pos(i).occluded);
    if ~isempty(det)
      % component index
      c = det(1,end-1);
      det = clipboxes(im, det);
      pard{i}{c} = [pard{i}{c}; det(:,1:end-2)];
      parb{i}{c} = [parb{i}{c}; boxes{1}(:,5:end-2)];
      part{i}{c} = [part{i}{c}; bbox];
    end
  end
  dets = cell(1,numComp);
  boxes = cell(1,numComp);
  targets = cell(1,numComp);
  for i = 1:numpos
    for c = 1:numComp
      dets{c} = [dets{c}; pard{i}{c}];
      boxes{c} = [boxes{c}; parb{i}{c}];
      targets{c} = [targets{c}; part{i}{c}];
    end
  end
  save([cachedir cls '_bboxdata_' num2str(n)], 'dets', 'boxes', 'targets');
end
