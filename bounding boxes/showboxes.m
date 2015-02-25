function showboxes(im, boxes)
% showboxes(im, boxes)
% Draw boxes on top of image.

clf;
image(im); 
axis equal;
axis on;
for comp=1:length(boxes)
    if ~isempty(boxes{comp})
      numfilters = floor(size(boxes{comp}, 2)/4);
      for i = 1:numfilters
        x1 = boxes{comp}(:,1+(i-1)*4);
        y1 = boxes{comp}(:,2+(i-1)*4);
        x2 = boxes{comp}(:,3+(i-1)*4);
        y2 = boxes{comp}(:,4+(i-1)*4);
        if i == 1
          c = 'r';
        else
          c = 'b';
        end
        line([x1 x1 x2 x2 x1]', [y1 y2 y2 y1 y1]', 'color', c, 'linewidth', 3);
      end
    end
end
drawnow;
