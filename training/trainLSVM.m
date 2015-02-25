function model = trainLSVM(name, model, pos, neg, warp, randneg, iter, ...
                       negiter, maxnum, keepsv, overlap, cont, C, J)
% model = train(name, model, pos, neg, warp, randneg, iter,
%               negiter, maxsize, keepsv, overlap, cont, C, J)
% Train LSVM.
%
% warp=1 uses warped positives
% warp=0 uses latent positives
% randneg=1 uses random negaties
% randneg=0 uses hard negatives
% iter is the number of training iterations
% negiter is the number of data-mining steps within each training iteration
% maxsize is the maximum size of the training data file
% keepsv=true keeps support vectors between iterations
% overlap is the minimum overlap in latent positive search
% cont=true we restart training from a previous run
% C & J are the parameters for LSVM objective function

if nargin < 9
  maxnum = 24000;
end

if nargin < 10
  keepsv = false;
end

if nargin < 11
  overlap = 0.7;
end

if nargin < 12
  cont = false;
end

if nargin < 13
  C = 0.002;   
end

if nargin < 14
  J = 1;
end

maxnum = max(length(pos)*10, maxnum+length(pos));

globals;

if(cnn)
    C = 0.00002;
    J = 1;
end

hdrfile = [tmpdir name '.hdr'];
datfile = [tmpdir name '.dat'];
modfile = [tmpdir name '.mod'];
inffile = [tmpdir name '.inf'];
lobfile = [tmpdir name '.lob'];
cmpfile = [tmpdir name '.cmp'];
objfile = [tmpdir name '.obj'];

labelsize = 5;  % [label id level x y]
negpos = 0;     % last position in data mining

if ~cont
  % reset data file
  fid = fopen(datfile, 'wb');
  fclose(fid);
  % reset header file
  writeheader(hdrfile, 0, labelsize, model);  
  % reset info file
  fid = fopen(inffile, 'w');
  fclose(fid);
  % reset initial model 
  fid = fopen(modfile, 'wb');
  fwrite(fid, zeros(sum(model.blocksizes), 1), 'double');
  fclose(fid);
  % reset lower bounds
  writelob(lobfile, model)
end

datamine = true;
pos_loss = zeros(iter,2);
for t = 1:iter
  fprintf('%s iter: %d/%d\n', procid(), t, iter);
  [labels, vals, unique] = readinfo(inffile);
  num = length(labels);
  
  if ~cont || t > 1
    % compute loss on positives before relabeling
    if warp == 0
      I = find(labels == 1);
      pos_vals = vals(I);
      hinge = max(0, 1-pos_vals);
      pos_loss(t,1) = J*C*sum(hinge);
    end
  
    % remove old positives
    I = find(labels == -1);
    rewritedat(datfile, inffile, hdrfile, I);
    num = length(I);

    % add new positives
    fid = fopen(datfile, 'a');
    if warp > 0
      numadded = poswarp(name, t, model, warp, pos, fid, featureExtractor);
      fusage = numadded;
    else
      [numadded, fusage, scores] = latentPositives(name, t, model, ...
                        pos, fid, featureExtractor, overlap, visualize);
    end
    num = num + numadded;
    fclose(fid);

    % save positive filter usage statistics
    model.fusage = fusage;
    fprintf('\nComponent usage stats:\n');
    for i = 1:model.numcomponents
      fprintf('  component %d got %d/%d (%.2f%%) positives\n', ...
              i, fusage(i), numadded, 100*fusage(i)/numadded);
    end

    % compute loss on positives after relabeling
    if warp == 0
      hinge = max(0, 1-scores);
      pos_loss(t,2) = J*C*sum(hinge);
      for tt = 1:t
        fprintf('positive loss before: %f, after: %f, ratio: %f\n', ...
                pos_loss(tt,1), pos_loss(tt,2), pos_loss(tt,2)/pos_loss(tt,1));
      end
      if t > 1 && pos_loss(t,2) > pos_loss(t,1)+0.0001
        fprintf('warning: pos loss went up\n');
      else
          % stop if relabeling doesn't reduce the positive loss by much
          if (t > 1) && (pos_loss(t,2)/pos_loss(t,1) > 0.999)&& (pos_loss(t,2)/pos_loss(t,1) < 1.0001)
            break;
          end
      end
    end
  end

  % data mine negatives
  cache = zeros(negiter,4);
  neg_loss = zeros(negiter,1);
  neg_comp = zeros(negiter,1);
  
  for tneg = 1:negiter
    fprintf('%s iter: %d/%d, neg iter %d/%d\n', procid(), t, iter, tneg, negiter);
       
    if datamine
      % add new negatives
      fid = fopen(datfile, 'a');
      if randneg > 0
        num = num + negrandom(name, t, model, randneg, neg, maxnum-num,...
                              fid, featureExtractor);
        randneg = randneg - 1;
      else
        [numadded, negpos, fusage, scores, complete] = ...
            neghard(name, tneg, negiter, model, neg, bytelimit, ...
                    fid, negpos, maxnum-num, visualize);
        num = num + numadded;
        hinge = max(0, 1+scores);
        neg_loss(tneg) = C*sum(hinge);
        neg_comp(tneg) = complete;
        fprintf('complete: %d, negative loss of old model: %f\n', ...
                neg_comp(tneg), neg_loss(tneg,1));
        for tt = 2:tneg
          cache_val = cache(tt-1,4);
          full_val = cache(tt-1,4)-cache(tt-1,1) + neg_loss(tt);
          fprintf('obj on cache: %f, obj on full: %f, ratio %f\n', ...
                  cache_val, full_val, full_val/cache_val);
        end
      end
      fclose(fid);

      fprintf('\nComponent usage stats:\n');
      for i = 1:model.numcomponents
        fprintf('  component %d got %d/%d (%.2f%%) negatives\n', ...
                i, fusage(i), numadded, 100*fusage(i)/numadded);
      end
      
      if randneg == 0 && tneg > 1 && neg_comp(tneg)
        cache_val = cache(tneg-1,4);
        full_val = cache(tneg-1,4)-cache(tneg-1,1) + neg_loss(tneg);
        if full_val/cache_val < 1.05
          fprintf('Data mining convergence condition met.\n');
          datamine = false;
          break;
        end
      end
    else
      fprintf('Skipping data mining iteration.\n');
      fprintf('The model has not changed since the last data mining iteration.\n');
      datamine = true;
    end
        
    % learn model
    writeheader(hdrfile, num, labelsize, model);
    writemodel(modfile, model);
    writecomponentinfo(cmpfile, model);
    logtag = [name '_' num2str(t) '_' num2str(tneg)];

    cmd = sprintf('./bin/learn %.6f %.6f %s %s %s %s %s %s %s %s %s', ...
                  C, J, hdrfile, datfile, modfile, inffile, lobfile, ...
                  cmpfile, objfile, cachedir, logtag);
    fprintf('executing: %s\n', cmd);
    status = unix(cmd);
    if status ~= 0
      fprintf('command `%s` failed\n', cmd);
      keyboard;
    end
    
    fprintf('parsing model\n');
    blocks = readmodel(modfile, model);
    model = parsemodel(model, blocks);
    [labels, vals, unique] = readinfo(inffile);
    
    % compute threshold for high recall
    P = find((labels == 1) .* unique);
    pos_vals = sort(vals(P));
    model.thresh = pos_vals(ceil(length(pos_vals)*0.05));
    pos_sv = numel(find(pos_vals < 1));

    % cache model
    save([cachedir name '_model_' num2str(t) '_' num2str(tneg)], 'model');
    
    % keep negative support vectors?
    neg_sv = 0;
    if keepsv
      % compute max number of elements that could fit into cache based
      % on average element size
      datinfo = dir(datfile);
      % bytes per example
      exsz = datinfo.bytes/length(labels);
      % estimated number of examples that will fit in the cache
      % respecting the byte limit
      maxcachesize = min(maxnum, round(bytelimit/exsz));
      U = find((labels == -1) .* unique);
      V = vals(U);
      [ignore, S] = sort(-V);
      % keep the cache at least half full
      sv = round((maxcachesize-length(P))/2);
      % but make sure to include all negative support vectors
      neg_sv = numel(find(V > -1));
      sv = max(sv, neg_sv);
      if length(S) > sv
        S = S(1:sv);
      end
      N = U(S);
    else
      N = [];
    end    
    
    fprintf('rewriting data file\n');
    I = [P; N];
    rewritedat(datfile, inffile, hdrfile, I);
    num = length(I);    
    fprintf('cached %d positive and %d negative examples\n', ...
            length(P), length(N));    
    fprintf('# neg SVs: %d\n# pos SVs: %d\n', neg_sv, pos_sv);
    
    [nl, pl, rt] = textread(objfile, '%f%f%f', 'delimiter', '\t');
    cache(tneg,:) = [nl pl rt nl+pl+rt];
    for tt = 1:tneg
      fprintf('cache objective, neg: %f, pos: %f, reg: %f, total: %f\n', ...
              cache(tt,1), cache(tt,2), cache(tt,3), cache(tt,4));
    end
  end
end

% get positive examples by warping positive bounding boxes
function num = poswarp(name, t, model, c, pos, fid, featureExtractor)
numpos = length(pos);
warped = warppos(name, model, c, pos);
ridx = model.components{c}.rootindex;
oidx = model.components{c}.offsetindex;
rblocklabel = model.rootfilters{ridx}.blocklabel;
oblocklabel = model.offsets{oidx}.blocklabel;
dim = model.components{c}.dim;
pixels = model.rootfilters{ridx}.size * model.sbin;
minsize = prod(pixels);
num = 0;
for i = 1:numpos 
    fprintf('%s: iter %d: warped positive: %d/%d\n', name, t, i, numpos);
    bbox = [pos(i).x1 pos(i).y1 pos(i).x2 pos(i).y2];
    % skip small examples
    if (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1) < minsize
      continue
    end    
    % get example
    im = warped{i};
    feat=featureExtractor(im);
    fwrite(fid, [1 i 0 0 0 2 dim], 'int32');
    fwrite(fid, [oblocklabel 1], 'single');
    fwrite(fid, rblocklabel, 'single');
    fwrite(fid, feat, 'single');    
    num=num+1;
end

% get hard negative examples
function [num, j, Cusage, scores, complete] = neghard(name, t, negiter,...
                    model, neg, maxsize, fid, negpos, maxnum, visualize)
model.interval = 2;
globals;
% model.cnn=false;
model.featureExtractor=featureExtractor;
Cusage = zeros(model.numcomponents, 1);
numneg = length(neg);
num = 0;
scores = [];
complete = 1;
batchsize = 4;
inds = circshift(1:numneg, [0 -negpos]);
for i = 1:batchsize:numneg
    thisbatchsize = batchsize - max(0, (i+batchsize-1) - numneg);
    data = {};
    parfor k = 1:thisbatchsize
        j = inds(i+k-1);
        fprintf('%s %s: iter %d/%d: hard negatives: %d/%d (%d)\n', procid(), name, t, negiter, i+k-1, numneg, j);
        im = imreadx(neg(j));
        pyra = featpyramid(im, model, model.featureExtractor, model.cnn);
        if isfield(neg(j),'x1') && ~isempty(neg(j).x1) % Check if positive bb is annotated
            bbox=[neg(j).x1,neg(j).y1,neg(j).x2,neg(j).y2];
            compCoarse=0;
            if isfield(neg(j),'compCoarse') 
                compCoarse=neg(j).compCoarse;
            end
            [det, box, info] = detect(pyra, model, -1.002, bbox, 0, 0, true, maxnum, -1, j, compCoarse);
        else
            bbox=[];
            [det, box, info] = detect(pyra, model, -1.002, bbox, 0, 0, true, maxnum, -1, j);
        end
        data{k}.det=det;
        data{k}.box=box;
        data{k}.info = info;
        data{k}.pyra = pyra;
    end
    for k = 1:thisbatchsize
        if isempty(data{k})
          continue;
        end
        j = inds(i+k-1);
        det=data{k}.det;
        num = num+size(det, 1);
        if ~isempty(det)
            scores = [scores; det(:,end)];
            Cusage = Cusage+getCompUsage(det, model.numcomponents);
            writeExamples(data{k}, model, fid);
        end
        if(visualize)
            box=data{k}.box;
            im = imread(neg(j).im);
            showboxes(im, box);
        end
        if ftell(fid) >= maxsize || num >= maxnum
            fprintf('reached memory limit\n');
            complete = 0;
            break;
        end
    end
    if complete == 0
        break;
    end
end

% get random negative examples
function num = negrandom(name, t, model, c, neg, maxnum, fid, featureExtractor)
numneg = length(neg);
rndneg = floor(maxnum/numneg);
ridx = model.components{c}.rootindex;
oidx = model.components{c}.offsetindex;
rblocklabel = model.rootfilters{ridx}.blocklabel;
oblocklabel = model.offsets{oidx}.blocklabel;
rsize = model.rootfilters{ridx}.size;
dim = model.components{c}.dim;
num = 0;
for i = 1:numneg
  fprintf('%s: iter %d: random negatives: %d/%d\n', name, t, i, numneg);
  im = color(imread(neg(i).im));
  feat=featureExtractor(im);
  if size(feat,2) > rsize(2) && size(feat,1) > rsize(1)
    for j = 1:rndneg
      x = randi(size(feat,2)-rsize(2)+1);
      y = randi(size(feat,1)-rsize(1)+1);
      f = feat(y:y+rsize(1)-1, x:x+rsize(2)-1,:);
      fwrite(fid, [-1 (i-1)*rndneg+j 0 0 0 2 dim], 'int32');
      fwrite(fid, [oblocklabel 1], 'single');
      fwrite(fid, rblocklabel, 'single');
      fwrite(fid, f, 'single');
    end
    num = num+rndneg;
  end
end

% collect component usage statistics
function u = getCompUsage(boxes, numComponents)
components=unique(boxes(:,end-1));
u = zeros(numComponents, 1);
for i = 1:size(components,1)
  u(components(i)) = sum(boxes(:,end-1)==components(i));
end
