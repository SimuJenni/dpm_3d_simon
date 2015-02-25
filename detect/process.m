function det = process(image, model, thresh)

% bbox = process(image, model, thresh)
% Detect objects that score above a threshold, return bonding boxes.
% If the threshold is not included we use the one in the model.
% This should lead to high-recall but low precision.

if nargin < 3
  thresh = model.thresh;
end
image = color(image);
pyra = featpyramid(image, model, model.featureExtractor, model.cnn);
[det, all] = detect(pyra, model, thresh);

if ~isempty(det)
  try
    %attempt to use bounding box prediction, if available
    bboxpred = model.bboxpred;
    [det all] = clipboxes(image, det, all);
    [det all] = bboxpred_get(bboxpred, det, all);
  catch
    warning('no bounding box predictor found');
  end
  det = clipboxes(image, det);
  det = nms(det, 0.5);
end
