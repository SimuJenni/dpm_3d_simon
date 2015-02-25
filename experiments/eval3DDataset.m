function [ recall, precision, accuracy, ap, aa, MPPE ] = eval3DDataset( cls, numComp )
% Evaluates detections on the 3D Object Dataset for cars. The detections
% have to be computed first by running test3DDataset.m

globals;
pascal_init;
azimuth_interval = [0 (360/(8*2)):(360/8):360-(360/(8*2))];

% open prediction file
filename = sprintf([expdir '/data/3DDataset/%s_%d_test3DDataset.mat'], cls, numComp);
object = load(filename);
dets_all = object.dets;

numA=8;
numH=2;
numS=3; 
elevs=[0, 2 * pi *0.1/4];
angles=[0:7]*360 /8;
M=5*numA*numH*numS;

energy = [];
correct = [];
correct_view = [];
overlap = [];
count = zeros(M,1);
num = zeros(M,1);
num_pr = 0;
view=cell(8,1);

idx=1;
for i=6:10   
    carFolder=[Dataset3D 'car_' num2str(i) '/'];
    for m=1:numA
        for k=1:numH
            for l=1:numS
                if(i>=7)
                    imPath=[carFolder 'car' num2str(i) '_A' num2str(m) '_H' num2str(k) '_S' num2str(l) '.bmp'];
                    maskPath=[carFolder 'mask/' 'car' num2str(i) '_A' num2str(m) '_H' num2str(k) '_S' num2str(l) '.mask'];
                else
                    imPath=[carFolder 'car_A' num2str(m) '_H' num2str(k) '_S' num2str(l) '.bmp'];
                    maskPath=[carFolder 'mask/' 'car_A' num2str(m) '_H' num2str(k) '_S' num2str(l) '.mask'];
                end
                fprintf('%s train view %d test view %d: %d\n', cls, 8, idx, M);    
                azimuth=angles(mod(m+3,8)+1);
                view_gt = find_interval(azimuth, azimuth_interval);
                [Data, Size] = ReadPointsData(maskPath);
                I=find(Data(:,:)>0);
                [I,J]=ind2sub(size(Data),I);
                x1=min(J);
                x2=max(J);
                y1=min(I);
                y2=max(I);
                bbox=[x1, y1, x2, y2];
                count(idx) = size(bbox, 1);
                det = zeros(count(idx), 1);
                % get predicted bounding box
                dets = dets_all{idx};           
                num(idx) = size(dets, 1);
                % for each predicted bounding box
                for j = 1:num(idx)
                    num_pr = num_pr + 1;
                    energy(num_pr) = dets(j, 6);        
                    bbox_pr = dets(j, 1:4);
                    view_pr = find_interval((dets(j, 5) - 1) * (360 / 8), azimuth_interval);

                    % compute box overlap
                    if isempty(bbox) == 0
                        o = box_overlap(bbox, bbox_pr);
                        [maxo, index] = max(o);
                        if maxo >= 0.5 && det(index) == 0
                            overlap{num_pr} = index;
                            correct(num_pr) = 1;
                            det(index) = 1;
                            % check viewpoint
                            if view_pr == view_gt(index)
                                correct_view(num_pr) = 1;
                                view{view_gt(index)}(end+1)=1;
                            else
                                correct_view(num_pr) = 0;
                                view{view_gt(index)}(end+1)=0;
                            end
                        else
                            overlap{num_pr} = [];
                            correct(num_pr) = 0;
                            correct_view(num_pr) = 0;
                        end
                    else
                        overlap{num_pr} = [];
                        correct(num_pr) = 0;
                        correct_view(num_pr) = 0;
                    end
                end
                idx=idx+1;
            end
        end
    end
end

overlap = overlap';

[threshold, index] = sort(energy, 'descend');
correct = correct(index);
correct_view = correct_view(index);
n = numel(threshold);
recall = zeros(n,1);
precision = zeros(n,1);
accuracy = zeros(n,1);
num_correct = 0;
num_correct_view = 0;
for i = 1:n
    % compute precision
    num_positive = i;
    num_correct = num_correct + correct(i);
    if num_positive ~= 0
        precision(i) = num_correct / num_positive;
    else
        precision(i) = 0;
    end
    
    % compute accuracy
    num_correct_view = num_correct_view + correct_view(i);
    if num_correct ~= 0
        accuracy(i) = num_correct_view / num_positive;
    else
        accuracy(i) = 0;
    end
    
    % compute recall
    recall(i) = num_correct / sum(count);
end


ap = VOCap(recall, precision);
fprintf('AP = %.4f\n', ap);

aa = VOCap(recall, accuracy);
fprintf('AA = %.4f\n', aa);

for i=1:length(view)
    v(i)=mean(view{i});
end
MPPE=mean(v(i));

if visualize
    % draw recall-precision and accuracy curve
    figure;
    hold on;
    plot(recall, precision, 'b', 'LineWidth',3);
    plot(recall, accuracy, 'g', 'LineWidth',3);
    xlabel('Recall');
    ylabel('Precision/Accuracy');
    grid on;
    tit = sprintf('Average Precision = %.1f / Average Accuracy = %.1f', 100*ap, 100*aa);
    title(tit);
    hold off;
end

% save results
filename = sprintf([expdir '/results/3DDataset/%s_%d_results.mat'], cls, numComp);
save(filename, 'recall', 'precision', 'accuracy', 'ap', 'aa', 'MPPE');

function ind = find_interval(azimuth, a)

for i = 1:numel(a)
    if azimuth < a(i)
        break;
    end
end
ind = i - 1;
if azimuth > a(end)
    ind = 1;
end



