function model = train3D(n)
% Trains a 3D DPM with n components

globals; 
cachesize=40000;
maxneg=300;
overlap=0.7;

% Get positive and negative examples
[pos, neg] = data3D();

% Split the data into different training sets. spos{c} consists of training
% examples used to initialise component c
[pos, spos] = split(pos, n, numElev);    

% train root filters using warped positives & random negatives
try
  load([cachedir cls '_random_' num2str(n)]);
catch
  for i=1:n
    models{i} = initmodel(spos{i}, featureDim, sbin);
    models{i} = trainLSVM(cls, models{i}, spos{i}, neg, 1, 1, 1, 1, cachesize);  
  end
  save([cachedir cls '_random_' num2str(n)], 'models');
end

% using badly located positives as negative examples for CNN features
if(posAsNeg)  
    neg = usePosAsNeg( pos, neg );
end

% merge models and train using latent detections & hard negatives
try 
  load([cachedir cls '_hard_'  num2str(n)]);
catch
  model = mergemodels(models);
  model = trainLSVM(cls, model, pos, neg(1:2*maxneg), 0, 0, 1, 5,...
      cachesize, true, overlap);
  save([cachedir cls '_hard_' num2str(n)], 'model');
end

% add parts and update models using latent detections & hard negatives.
try 
  load([cachedir cls '_parts_' num2str(n)]);
catch
  model = addparts(model, numParts, partsPerComp);
  if(cnn) 
      model = trainLSVM(cls, model, pos, neg(1:maxneg), 0, 0, 5, 5,...
          cachesize, true, overlap);
  else
      model = trainLSVM(cls, model, pos, neg(1:maxneg), 0, 0, 8, 10,...
          cachesize, true, overlap);
  end
  save([cachedir cls '_parts_' num2str(n)], 'model');
end

% update models using full set of negatives.
try 
  load([cachedir cls '_mine_' num2str(n)]);
catch
  model = trainLSVM(cls, model, pos, neg, 0, 0, 1, 5, cachesize, true,...
      overlap, true); 
  save([cachedir cls '_mine_' num2str(n)], 'model');
end

% train bounding box prediction
try
  load([cachedir cls '_final_' num2str(n)]);
catch
  save([cachedir cls '_finalNoBB_' num2str(n)], 'model');  
  boxtrain=[pos(:).modelID]'>0; % don't use CAD for bbpred train
  model = bboxpred_train(pos(~boxtrain), n); 
  model.featureExtractor=featureExtractor;
  save([cachedir cls '_final_' num2str(n)], 'model');
end
