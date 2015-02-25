function writeExamples( data, model, fid )
% Writes examples of latent positive and hard negative search to file.
pyra=data.pyra;
info=data.info;
levels=unique([info(:).level]);
featr=cell(max(levels));
featp=cell(max(levels));
padx = info.padx;
pady = info.pady;
interval=info.interval;
featPad=model.featPad;
for i=1:length(levels)
    featr{levels(i)}=padFeature(pyra.feat{levels(i)},pady-1+featPad,padx-1+featPad);
    if ~isempty(model.partfilters)
        featp{levels(i)} = padFeature(pyra.feat{levels(i)-interval}, 2*pady-1+featPad, 2*padx-1+featPad);
    end
end
for i=1:length(info)
    level=info(i).level;
    ex.header=info(i).header;
    ex.offset=info(i).offset;
    ex.root.bl=info(i).root.bl;
    rsize=info(i).root.rsize;
    x=info(i).root.x;
    y=info(i).root.y;
    f = featr{level}(y:y+rsize(1)-1, x:x+rsize(2)-1, :);
    ex.root.w = f;
    ex.part=[];
    for j=1:size(info(i).part,2)
        psize = info(i).part(j).psize;
        py = info(i).part(j).py;
        px = info(i).part(j).px;
        f = featp{level}(py:py+psize(1)-1,px:px+psize(2)-1,:);
        ex.part(j).bl = info(i).part(j).bl;
        ex.part(j).w = f;
        ex.def(j).bl = info(i).def(j).bl;
        ex.def(j).w = info(i).def(j).w;
    end
    exwrite(fid, ex);
end
end

% write an example to the data file
function exwrite(fid, ex)
fwrite(fid, ex.header, 'int32');
buf = [ex.offset.bl; ex.offset.w(:); ...
       ex.root.bl; ex.root.w(:)];
fwrite(fid, buf, 'single');
for j = 1:length(ex.part)
  if ~isempty(ex.part(j).w)
    buf = [ex.part(j).bl; ex.part(j).w(:); ...
           ex.def(j).bl; ex.def(j).w(:)];
    fwrite(fid, buf, 'single');
  end
end
end