% cls: class name
% n: view number
function test3DDataset(cls, n)
globals;

try
    load(sprintf([expdir '/data/3DDataset/%s_%d_test3DDataset.mat'], cls, n));
catch
    
    if(nargin<3)
        load([cachedir cls '_final_' num2str(8)]);
    end
    model.featureExtractor=featureExtractor;
    model.cnn=cnn;
    model.thresh = min(-1.1, model.thresh);
    index_pose = (1:n);

    numA=8;
    numH=2;
    numS=3; 
    idx=1;
    numTest=5*numA*numH*numS;
    for i=6:10   % use cars 1:5 for training and rest for testing!
        carFolder=[Dataset3D 'car_' num2str(i) '/'];
        for j=1:numA
            for k=1:numH
                for l=1:numS
                    if(i>=7)
                        imPath=[carFolder 'car' num2str(i) '_A' num2str(j) '_H' num2str(k) '_S' num2str(l) '.bmp'];
                    else
                        imPath=[carFolder 'car_A' num2str(j) '_H' num2str(k) '_S' num2str(l) '.bmp'];
                    end
                    fprintf('%s view %d: %d/%d\n', cls, n, idx, numTest);
                    I = imread(imPath);
                    det = process(I, model, model.thresh);
                    num = size(det, 1);
                    for m = 1:num
                        det(m,5) = index_pose(det(m,5));
                    end
                    dets{idx} = det;
                    idx=idx+1;
                end
            end
        end
    end
    
    filename = sprintf([expdir '/data/3DDataset/%s_%d_test3DDataset.mat'], cls, n);
    save(filename, 'dets');
end

