function model = bboxpred_train(pos, n)
% Train a bounding box predictor.
%
% name    class name
% year    dataset year
% method  regression method (default is LS regression)

globals;

if nargin < 3
  method = 'default';
  if cnn
      method = 'minl2';
  end
end

name=cls;

% load final model for class
load([cachedir name '_finalNoBB_' num2str(n)]);

try
  % test to see if the bbox predictor was already trained
  bboxpred = model.bboxpred;
catch
  % get training data
  [traindets, trainboxes, targets] = bboxpred_data(pos, n);
  % train bbox predictor
  fprintf('%s %s: bbox predictor training...', procid(), name);
  numComp = model.numcomponents;
  bboxpred = cell(numComp, 1);
  for c = 1:numComp
    [A x1 y1 x2 y2 w h] = bboxpred_input(traindets{c}, trainboxes{c});
    bboxpred{c}.x1 = getcoeffs(method, A, (targets{c}(:,1)-x1)./w);
    bboxpred{c}.y1 = getcoeffs(method, A, (targets{c}(:,2)-y1)./h);
    bboxpred{c}.x2 = getcoeffs(method, A, (targets{c}(:,3)-x2)./w);
    bboxpred{c}.y2 = getcoeffs(method, A, (targets{c}(:,4)-y2)./h);
  end
  fprintf('done\n');
  % save bbox predictor coefficients in the model
  model.bboxpred = bboxpred;
  save([cachedir name '_final_' num2str(n)], 'model');
end


function beta = getcoeffs(method, X, y)
switch lower(method)
  case 'default'
    % matlab's magic box of matrix inversion tricks
    beta = X\y;
  case 'minl2'
    % regularized LS regression
    lambda = 0.01;
    Xr = X'*X + eye(size(X,2))*lambda;
    iXr = inv(Xr);
    beta = iXr * (X'*y);
  case 'minl1'
    % require code from http://www.stanford.edu/~boyd/l1_ls/
    addpath('l1_ls_matlab');
    lambda = 0.01;
    rel_tol = 0.01;
    beta = l1_ls(X, y, lambda, rel_tol, true);
  case 'rtls'
    beta = rtlsqepslow(X, y, eye(size(X,2)), 0.2)
  otherwise
    error('unknown method');
end
