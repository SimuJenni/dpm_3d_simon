function writecomponentinfo(f, model)

% writecomponentinfo(f, model)
% write the block labels used by each component
% format: #components {#blocks blk1 ... blk#blocks}^#components
% used in the interface with learn.cc

n = model.numcomponents;
comp = cell(n, 1);
for i = 1:n
  % component offset block
  bl = model.offsets{model.components{i}.offsetindex}.blocklabel;
  comp{i}(end+1) = bl-1;
  bl = model.rootfilters{model.components{i}.rootindex}.blocklabel;
  comp{i}(end+1) = bl-1;
  % collect part blocks
  for j = 1:length(model.components{i}.parts)
      bl=model.defs{model.components{i}.parts{j}.defindex}.blocklabel;
      comp{i}(end+1) = bl-1;
      bl=model.partfilters{model.components{i}.parts{j}.partindex}.blocklabel;
      comp{i}(end+1) = bl-1;
  end
end
buf = n;
numblocks = 0;
for i = 1:n
  k = length(comp{i});
  buf = [buf k comp{i}];
  numblocks = numblocks + k;
end
% sanity check
if numblocks ~= model.numblocks
  error('numblocks mismatch');
end
fid = fopen(f, 'wb');
fwrite(fid, buf, 'int32');
fclose(fid);
