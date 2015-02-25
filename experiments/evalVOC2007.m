function [ recall, prec, ap ] = evalVOC2007( cls, n )
globals;
VOCdevkit = [Datadir '/3rd_party/VOCdevkit/'];
testset='test';
pascal_init;
suffix='tryout';

ids = textread(sprintf(VOCopts.imgsetpath,testset), '%s');
if(nargin<4)
    M = numel(ids);
end

% open prediction file
filename = sprintf([expdir '/data/VOC2007/%s_%d_test.mat'], cls, n);
object = load(filename);
dets_all = object.dets;

% write out detections in PASCAL format and score
fid = fopen(sprintf(VOCopts.detrespath, 'comp3', cls), 'w');
for i = 1:length(ids);
  bbox = dets_all{i};
  for j = 1:size(bbox,1)
    fprintf(fid, '%s %f %d %d %d %d\n', ids{i}, bbox(j,end), bbox(j,1:4));
  end
end
fclose(fid);

VOCopts.testset = testset;
if str2num(VOCyear) == 2006
  [recall, prec, ap] = VOCpr(VOCopts, 'comp3', cls, true);
elseif str2num(VOCyear) < 2013
  [recall, prec, ap] = VOCevaldet(VOCopts, 'comp3', cls, true);
else
  recall = 0;
  prec = 0;
  ap = 0;
end

if str2num(VOCyear) < 2013
  % force plot limits
  ylim([0 1]);
  xlim([0 1]);

  % save results
  filename = sprintf([expdir '/results/VOC2007/%s_%d_pr.mat'], cls, n);
  save(filename, 'recall', 'prec', 'ap');
%   print(gcf, '-djpeg', '-r0', [cachedir cls '_pr_' testset '_' suffix '.jpg']);
end

if visualize
    % draw recall-precision and accuracy curve
    figure;
    hold on;
    plot(recall, prec, 'b', 'LineWidth',3);
    xlabel('Recall');
    ylabel('Precision');
    grid on;
    tit = sprintf('Average Precision = %.1f', 100*ap);
    title(tit);
    hold off;
end