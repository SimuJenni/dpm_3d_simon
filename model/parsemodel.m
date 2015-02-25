function model = parsemodel(model, blocks)

% parsemodel(model, blocks)
% Update model parameters from weight vector representation.

% update root filters
for i = 1:length(model.rootfilters)
  s = size(model.rootfilters{i}.w);
  f = reshape(blocks{model.rootfilters{i}.blocklabel}, s);
  model.rootfilters{i}.w=f;
end

% update offsets
for i = 1:length(model.offsets)
  model.offsets{i}.w = blocks{model.offsets{i}.blocklabel};
end

% update part filters and deformation models
for i = 1:length(model.partfilters)
  model.defs{i}.w = reshape(blocks{model.defs{i}.blocklabel}, ...
                            size(model.defs{i}.w));
    s = size(model.partfilters{i}.w);
    model.partfilters{i}.w=reshape(blocks{model.partfilters{i}.blocklabel}, s);
end
