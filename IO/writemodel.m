function writemodel(modfile, model)

blocks = cell(model.numblocks, 1);

% root filters
for i = 1:length(model.rootfilters)
  bl= model.rootfilters{i}.blocklabel; 
  blocks{bl}=model.rootfilters{i}.w(:);
end

% offsets
for i = 1:length(model.offsets)
  bl=model.offsets{i}.blocklabel;
  blocks{bl}=model.offsets{i}.w;
end

% part filters and deformation models
for i = 1:length(model.partfilters)
    bl=model.defs{i}.blocklabel;
    blocks{bl}=model.defs{i}.w(:);
    bl=model.partfilters{i}.blocklabel;
    blocks{bl}=model.partfilters{i}.w(:);
end

% concatenate
m = [];
for i = 1:model.numblocks
  m = [m; blocks{i}];
end

% sanity check
if sum(model.blocksizes) ~= length(m)
  error('model size error');
end

% write to modfile
fid = fopen(modfile, 'wb');
fwrite(fid, m, 'double');
fclose(fid);
