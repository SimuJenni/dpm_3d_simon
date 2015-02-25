function [ loss ] = loss(y, ybar, factor, trunc, occl )
% Computes a loss/penalty term for latent positive detections.
% Incorrect viewpoint assignment and low bb overlap for untrancated and
% un-occluded examples are penalized.

if nargin<3
    factor=1;
end
if nargin<4
    trunc=true;
    occl=true;
end

x1 = max(y(1), ybar(1));
y1 = max(y(2), ybar(2));
x2 = min(y(3), ybar(3));
y2 = min(y(4), ybar(4));
w = (x2-x1+1);
h = (y2-y1+1);
if w > 0 && h > 0
  % check overlap with bbox
  inter = w*h;
  a = (y(3)-y(1)+1) * (y(4)-y(2)+1);
  b = (ybar(3)-ybar(1)+1) * (ybar(4)-ybar(2)+1);
  o = inter / (a+b-inter);
else
    o=0;
end
lbox=1-o;
if(y(end)==0)
    lview=0;
else
    lview=y(end)~=ybar(end);
end

if ~occl&&~trunc
    loss=0.5*lbox+0.5*lview;
    factor=factor*2;
else
    loss=lview;
end
loss=loss*factor;
end

