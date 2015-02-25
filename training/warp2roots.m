function [ warped ] = warp2roots( name, model, pos )
% warped = warppos(name, model, c, pos)
% Warps positive examples to fit model dimensions.
% Used for training root and part filters from positive bounding boxes.
% Output: warped{i}.im1 - image extracted from positive BB, resized to fit
%                         rootfilter dimensions
%         warped{i}.im2 - image extracted from positive BB, resized and
%                         padded to be used for partfilter-matches.
%                         (twice the resolution of im1 and padded with
%                         model.sbin on each side)
%         warped{i}.component - The mixture-component related to this
%                               example
heights = [pos(:).y2]' - [pos(:).y1]' + 1;
widths = [pos(:).x2]' - [pos(:).x1]' + 1;
areas = heights.*widths;
scales=zeros(size(areas));

for c=1:model.numcomponents
    ridx(c) = model.components{c}.rootindex;
    rootSize(:,c) = model.rootfilters{ridx(c)}.size';
    pixels(:,c) = rootSize(:,c) * model.sbin;
    rootArea(c) = prod(pixels(:,c));
    L=[pos(:).component]'==c;
%     scales(L)=sqrt(areas(L)/rootArea(c));
    scales(L)=floor(widths(L)/(rootSize(2,c)*model.sbin));
    cropsize(:,c) = (rootSize(:,c)+2*model.featPad) * model.sbin;
end
numpos = length(pos);
warped = cell(numpos);
for i = 1:numpos
  im = imreadx(pos(i));
  c = pos(i).component;
  bbCenter = [(pos(i).x1+pos(i).x2)/2;(pos(i).y1+pos(i).y2)/2];
  x1 = round(bbCenter(1)-scales(i)*pixels(2,c)/2);
  x2 = round(bbCenter(1)+scales(i)*pixels(2,c)/2);
  y1 = round(bbCenter(2)-scales(i)*pixels(1,c)/2);
  y2 = round(bbCenter(2)+scales(i)*pixels(1,c)/2);
  window1 = subarray(im, y1, y2, x1, x2, 1);
  warped{i}.im1 = imresize(window1, cropsize(:,c)', 'bilinear');
  pad = model.sbin * scales(i);
  cropsize2=2*cropsize(:,c)'-2*model.featPad*model.sbin;
  cropsize2=cropsize2+2*model.sbin;
  window2 = subarray(im, floor(y1-pad), ceil(y2+pad), floor(x1-pad), ceil(x2+pad), 1);
  warped{i}.im2 = imresize(window2, cropsize2, 'bilinear');
  warped{i}.component=pos(i).component;
%   imshow(uint8(warped{i}.im2));
end

end

