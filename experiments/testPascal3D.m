% cls: class name
% n: view number
function testPascal3D(cls, n, N,test)
if nargin<4
    test='val';
end

globals;

try
    load(sprintf([expdir '/data/VOC2012/%s_%d_test.mat'], cls, n));
catch
    load([cachedir cls '_final_' num2str(n)]);
    model.thresh = min(-1.1, model.thresh);
    model.featureExtractor=featureExtractor;
    model.cnn=cnn;
    index_pose = (1:n);

    % initialize the PASCAL development kit 
    tmp = pwd;
    cd([Pascal3D '/PASCAL/VOCdevkit/']);
    addpath([cd '/VOCcode']);
    VOCinit;
    cd(tmp);

    % read ids of validation images
    ids = textread(sprintf(VOCopts.imgsetpath, test), '%s');

    if(nargin<3)
        N = numel(ids);
    end

    dets = cell(N, 1);
    % parfor gets confused if we use VOCopts
    opts = VOCopts;
    parfor i = 1:N
        fprintf('%s view %d: %d/%d\n', cls, n, i, N);
        file_img = sprintf(opts.imgpath, ids{i});
        I = imread(file_img);
        det = process(I, model, model.thresh);
        num = size(det, 1);
        for j = 1:num
            det(j,5) = index_pose(det(j,5));
        end
        dets{i} = det;
    end

    filename = sprintf([expdir '/data/VOC2012/%s_%d_test.mat'], cls, n);
    save(filename, 'dets');
end

