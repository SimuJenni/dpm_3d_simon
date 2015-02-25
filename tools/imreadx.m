function im = imreadx(ex)

% Read a training example image.
%
% ex  an example returned by pascal_data.m

im = color(imread(ex.im));
if isfield(ex,'flip')
    if ex.flip
      im = im(:,end:-1:1,:);
    end
end
