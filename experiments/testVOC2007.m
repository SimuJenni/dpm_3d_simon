% cls: class name
% n: view number
function testVOC2007(cls, n)
globals;
try
    load(sprintf([expdir '/data/VOC2007/%s_%d_test.mat'], cls, n));
catch
    VOCdevkit = [Datadir '/3rd_party/VOCdevkit/'];
    pascal_init;
    load([cachedir cls '_final_' num2str(n)]);
    model.thresh = min(-1.1, model.thresh);
    model.featureExtractor=featureExtractor;
    model.cnn=cnn;
    if(cnn)
        model.interval=2;
    end
    % read ids of validation images
    ids = textread(sprintf(VOCopts.imgsetpath, 'test'), '%s');
    N = numel(ids);
    dets = cell(N, 1);
    % parfor gets confused if we use VOCopts
    opts = VOCopts;
    parfor i = 1:N
        fprintf('%s VOC2007 test %d: %d/%d\n', cls, n, i, N);
        file_img = sprintf(opts.imgpath, ids{i});
        I = imread(file_img);
        det = process(I, model, model.thresh);
        num = size(det, 1);
        dets{i} = det;
    end
    filename = sprintf([expdir '/data/VOC2007/%s_%d_test.mat'], cls, n);
    save(filename, 'dets');
end

