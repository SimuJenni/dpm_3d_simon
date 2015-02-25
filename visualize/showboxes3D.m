function showboxes3D(im, boxes, box2d)

% showboxes(im, boxes)
% Draw boxes on top of image.

clf;
image(im); 
axis equal;
axis on;
for comp=1:length(boxes)
    if ~isempty(boxes{comp})
      numfilters = floor(size(boxes{comp}, 2)/16);
      for i = 1:numfilters
        x1 = boxes{comp}(:,1+(i-1)*16);
        y1 = boxes{comp}(:,2+(i-1)*16);
        x2 = boxes{comp}(:,3+(i-1)*16);
        y2 = boxes{comp}(:,4+(i-1)*16);
        x3 = boxes{comp}(:,5+(i-1)*16);
        y3 = boxes{comp}(:,6+(i-1)*16);
        x4 = boxes{comp}(:,7+(i-1)*16);
        y4 = boxes{comp}(:,8+(i-1)*16);
        x5 = boxes{comp}(:,9+(i-1)*16);
        y5 = boxes{comp}(:,10+(i-1)*16);
        x6 = boxes{comp}(:,11+(i-1)*16);
        y6 = boxes{comp}(:,12+(i-1)*16);
        x7 = boxes{comp}(:,13+(i-1)*16);
        y7 = boxes{comp}(:,14+(i-1)*16);
        x8 = boxes{comp}(:,15+(i-1)*16);
        y8 = boxes{comp}(:,16+(i-1)*16);
        if comp == 1
          c = 'r';
        else
          c = 'b';
        end
        line([x1 x2]', [y1 y2]', 'color', c, 'linewidth', 3);
        line([x3 x4]', [y3 y4]', 'color', c, 'linewidth', 3);
        line([x5 x6]', [y5 y6]', 'color', c, 'linewidth', 3);
        line([x7 x8]', [y7 y8]', 'color', c, 'linewidth', 3);
        line([x1 x3]', [y1 y3]', 'color', c, 'linewidth', 3);
        line([x2 x4]', [y2 y4]', 'color', c, 'linewidth', 3);
        line([x5 x7]', [y5 y7]', 'color', c, 'linewidth', 3);
        line([x6 x8]', [y6 y8]', 'color', c, 'linewidth', 3);
        line([x1 x5]', [y1 y5]', 'color', c, 'linewidth', 3);
        line([x2 x6]', [y2 y6]', 'color', c, 'linewidth', 3);
        line([x3 x7]', [y3 y7]', 'color', c, 'linewidth', 3);
        line([x4 x8]', [y4 y8]', 'color', c, 'linewidth', 3);
      end
    end
end

for comp=1:length(box2d)
    if ~isempty(box2d{comp})
      numfilters = floor(size(box2d{comp}, 2)/4);
      for i = 1:numfilters
        x1 = box2d{comp}(:,1+(i-1)*4);
        y1 = box2d{comp}(:,2+(i-1)*4);
        x2 = box2d{comp}(:,3+(i-1)*4);
        y2 = box2d{comp}(:,4+(i-1)*4);
        if i == 1
          c = 'g';
        else
          c = 'b';
        end
        line([x1 x1 x2 x2 x1]', [y1 y2 y2 y1 y1]', 'color', c, 'linewidth', 3);
      end
    end
end

drawnow;
