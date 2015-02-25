function [num, numpositives, scores] = poslatent(name, t, model, pos, overlap, fid, visualize)
% get positive examples using latent detections
globals;
numpos = length(pos);
model.featureExtractor=featureExtractor;
model.interval = 5;
numpositives = zeros(model.numcomponents, 1);
pixels = model.minsize * model.sbin;
if(extraLevel)
    pixels = pixels/2;  
end
if(cnn)
    pixels = pixels/2;  
    model.interval = 2;
end
minsize = prod(pixels);
scores=[];
num = 0;
batchsize = 16;
for i = 1:batchsize:numpos
    thisbatchsize = batchsize - max(0, (i+batchsize-1) - numpos);
    data = cell(thisbatchsize);
    parfor k = 1:thisbatchsize
        j = i+k-1;
        fprintf('%s %s: iter %d: latent positive: %d/%d', procid(), name, t, j, numpos);
        bbox = [pos(j).x1 pos(j).y1 pos(j).x2 pos(j).y2];
        % skip small examples
        if (bbox(3)-bbox(1)+1)*(bbox(4)-bbox(2)+1) < minsize
            fprintf(' (too small)\n');
            continue;
        end
        % get example
        im = imreadx(pos(j));
        [im, bbox] = croppos(im, bbox, overlap);
        pyra = featpyramid(im, model, model.featureExtractor, model.cnn);
        o=overlap;
        if pos(j).occluded==1
            o=0.5;
        end
        [det, box, info] = detect(pyra, model, 0, bbox, o, pos(j).component...
            , true, inf, 1, j, pos(j).compCoarse, pos(j).trunc, pos(j).occluded);
        data{k}.det=det;
        data{k}.box=box;
        data{k}.info = info;
        data{k}.pyra = pyra;
        if ~isempty(det)
            fprintf(' (comp %d  score %.3f)\n', det(1,end-1), det(1,end));
        else
          fprintf(' (no overlap)\n');
        end
    end
    for k = 1:thisbatchsize
        if isempty(data{k})
          continue;
        end
        j = i+k-1;
        det=data{k}.det;
        if ~isempty(det)
            c = det(1,end-1);
            numpositives(c) = numpositives(c)+1;
            num = num+1;
            scores(num) = det(1,end);
            writeExamples(data{k}, model, fid);
            if(visualize)
                box=data{k}.box;
                im = imreadx(pos(j));
                bbox = [pos(j).x1 pos(j).y1 pos(j).x2 pos(j).y2];
                [im, bbox] = croppos(im, bbox, overlap);
                showboxes(im, box);
            end
        end
    end
end
