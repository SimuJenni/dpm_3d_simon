function [dets, boxes, info] = detect(pyra, model, thresh, bbox, ...
                          overlap, component, getInfo, maxnum, label, id,...
                          compCoarse, trunc, occl)
% Detect objects in feature pyramid using a model and a score threshold.
% Higher threshold leads to fewer detections. 
%
% Input:   pyra - Featurepyramid of image computed with featurepyramid.m,
%                 where interval=model.interval
%          thresh - threshold for detections
%          bbox - Bounding box of positive example used for latent detections. 
%                 If bbox is not empty, we pick best detection with 
%                 significant overlap. 
%          overlap - minimum overlap for latent detections
%          component - If component>0, only detections from this 
%                      mixture-component are considered
%          getInfo - boolean value, if true info will be written
%          maxnum - maximum number of detections
%          label - 1:positive example, -1:negative example
%          compCoarse - Mixture component that is related to this viewpoint.
%                       Other components will be considered too but
%                       penalized by -0.5 in score.
%          trunc - indicates truncated examples
%          occl - indicates occluded examples 
% Output:  dets - Matrix where each row corresponds to a detection.
%                 det(:,1:4) are detected bounding boxes
%                 det(:,5) are the components used. (viewpoint)
%                 det(:,6) the scores of the detections.
%          boxes - Cell array where boxes{c} is a matrix that corresponds 
%                  to detections of component c.
%                  Each row of the matrix contains coordinates of root and 
%                  part bounding boxes, the mixture component used and the
%                  score.
%          info - contains informations used to write examples to file

if nargin<4
    bbox=[];
end

if ~isempty(bbox)&&label==1
  latent = true;
else
  if ~isempty(bbox)
      cnn=true;
  else
      cnn=false;
  end
  latent = false;
end

if nargin<5
    overlap=0;
end

if nargin<6
    component=0;
end

if nargin < 7
  getInfo = false;
end

if nargin < 8
  maxnum = 20000;
end

if nargin < 11
  compCoarse = 0;
end

if nargin < 12
  trunc = true;
end

if nargin < 12
  occl = true;
end

% cache some data
for c = 1:model.numcomponents
  ridx{c} = model.components{c}.rootindex;
  oidx{c} = model.components{c}.offsetindex;                
  root{c} = model.rootfilters{ridx{c}}.w;
  rsize{c} = [size(root{c},1) size(root{c},2)];
  numparts{c} = length(model.components{c}.parts);
  for j = 1:numparts{c}
    pidx{c,j} = model.components{c}.parts{j}.partindex;
    didx{c,j} = model.components{c}.parts{j}.defindex;
    part{c,j} = model.partfilters{pidx{c,j}}.w;
    psize{c,j} = [size(part{c,j},1) size(part{c,j},2)];
    % reverse map from partfilter index to (component, part#)
    rpidx{pidx{c,j}} = [c j];
  end
end

if(component==0)          % no specified component...
    startComp=1;
    endComp=model.numcomponents;
    % prepare model for convolutions
    rootfilters = [];
    partfilters = [];
    for i = 1:length(model.rootfilters)
      rootfilters{i} = model.rootfilters{i}.w;
    end
    for i = 1:length(model.partfilters)
      partfilters{i} = model.partfilters{i}.w;
    end
else  % only search for given model component
    startComp=component;
    endComp=component;
    rootfilters = [];
    partfilters = [];
    rootfilters{1}=root{component};
    for i=1:numparts{component}
        partfilters{i} = part{component,i};
    end
end

% we pad the feature maps to detect partially visible objects
padx = ceil(model.maxsize(2)/2+1);
pady = ceil(model.maxsize(1)/2+1);

% detect at each scale
bestLoss = -inf;
dets = [];
boxes = cell(1,endComp-startComp+1);
numDetect=0;
info=[];
interval = model.interval;
info.interval = interval;
info.padx=padx;
info.pady=pady;
for level = interval+1:length(pyra.feat)
  scale = model.sbin/pyra.scales(level);    
  if size(pyra.feat{level}, 1)+2*(pady) < model.maxsize(1) || ...   % stop if featuremap to small
     size(pyra.feat{level}, 2)+2*(padx) < model.maxsize(2) 
    continue;
  end
  
  % check for componenets with significant overlap and skip if none found
  if latent&&~trunc
    skip = true;
    if(component==0)
        for c = 1:model.numcomponents       
          root_area = (rsize{c}(1)*scale) * (rsize{c}(2)*scale);
          box_area = (bbox(3)-bbox(1)+1) * (bbox(4)-bbox(2)+1);
          if (root_area/box_area) >= overlap && (box_area/root_area) >= overlap   
            skip = false;
          end
        end
    else
        root_area = (rsize{component}(1)*scale) * (rsize{component}(2)*scale);
        box_area = (bbox(3)-bbox(1)+1) * (bbox(4)-bbox(2)+1);
        if (root_area/box_area) >= overlap && (box_area/root_area) >= overlap   
          skip = false;
        end
    end
    if skip
      continue;
    end
  end
    
  % convolve feature maps with filters 
  featPad=model.featPad;
  featr=padFeature(pyra.feat{level},pady-1+featPad,padx-1+featPad);
  rootmatch = fconv(featr, rootfilters, 1, length(rootfilters));
  if ~isempty(partfilters)
    featp = padFeature(pyra.feat{level-interval}, 2*pady-1+featPad, 2*padx-1+featPad);
    partmatch = fconv(featp, partfilters, 1, length(partfilters));
    tmpPartMatch=partmatch;
  end
  
  if(component~=0)          
      rootmatch{ridx{component}}=rootmatch{1};
      for j = 1:numparts{component}
          partmatch{pidx{component,j}}=tmpPartMatch{j};
      end
  end
  
  for c = startComp:endComp  
      
    % root score + offset
    score = rootmatch{ridx{c}} + model.offsets{oidx{c}}.w;  
    
    % add in parts
    for j = 1:numparts{c}
      def = model.defs{didx{c,j}}.w;
      anchor = model.defs{didx{c,j}}.anchor;
      anchVec=[anchor 1];
      anchorProj=model.defs{didx{c,j}}.projectMat*anchVec';  
      ax{c,j} = round(anchorProj(1)+2);
      ay{c,j} = round(anchorProj(2)+2);
      match = partmatch{pidx{c,j}};
      [M, INDEXES{c,j}] = vl_imdisttf(-match,def); 
      [Iy{c,j},Ix{c,j}] = ind2sub(size(INDEXES{c,j}),INDEXES{c,j});
      score = score - M(ay{c,j}:2:ay{c,j}+2*(size(score,1)-1), ...
                        ax{c,j}:2:ax{c,j}+2*(size(score,2)-1)); 
    end

    if ~latent
      % get all good matches
      I = find(score > thresh);
      [Y, X] = ind2sub(size(score), I);        
      tmpB = zeros(length(I), 4*(1+numparts{c})+2);
      tmpD = zeros(length(I), 4+2);
      for i = 1:length(I)
        x = X(i);
        y = Y(i);
        [x1, y1, x2, y2] = rootbox(x, y, scale, padx, pady, rsize{c});
        if(cnn && (compCoarse==c||compCoarse==0))
            o=box_overlap([max(x1,1), max(y1,1), min(x2,pyra.imsize(2)),...
                            min(y2,pyra.imsize(1))],bbox);
            if(o>0.3)
                continue;
            end
        end
        numDetect=numDetect+1;
        d = [x1 y1 x2 y2];
        b = [x1 y1 x2 y2];
        if getInfo
          rblocklabel = model.rootfilters{ridx{c}}.blocklabel;
          oblocklabel = model.offsets{oidx{c}}.blocklabel;      
          xc = round(x + rsize{c}(2)/2 - padx);
          yc = round(y + rsize{c}(1)/2 - pady);
          info(numDetect).level = level;
          info(numDetect).header = [label; id; level; xc; yc; ...
                       model.components{c}.numblocks; ...
                       model.components{c}.dim];
          info(numDetect).offset.bl = oblocklabel;
          info(numDetect).offset.w = 1;
          info(numDetect).root.bl = rblocklabel;
          info(numDetect).root.rsize=rsize{c};
          info(numDetect).root.x=x;
          info(numDetect).root.y=y;
          info(numDetect).part = [];
        end
        for j = 1:numparts{c}
          [probex, probey, px, py, px1, py1, px2, py2] = ...
              partbox(x, y, ax{c,j}, ay{c,j}, scale, padx, pady, ...
                      psize{c,j}, Ix{c,j}, Iy{c,j});
          b = [b px1 py1 px2 py2];
          if getInfo
            pblocklabel = model.partfilters{pidx{c,j}}.blocklabel;
            dblocklabel = model.defs{didx{c,j}}.blocklabel;
            def = -[(probex-px)^2; probex-px; (probey-py)^2; probey-py];
            info(numDetect).part(j).bl = pblocklabel;
            info(numDetect).part(j).psize = psize{c,j};
            info(numDetect).part(j).py = py;
            info(numDetect).part(j).px=px;
            info(numDetect).def(j).bl = dblocklabel;
            info(numDetect).def(j).w = def;
          end
        end
        tmpB(i,:) = [b c score(I(i))];
        tmpD(i,:) = [d c score(I(i))];
      end
      valid=[tmpD(:,end-1)]>0;
      tmpD=tmpD(valid,:);
      tmpB=tmpB(valid,:);
      boxes{c} = [boxes{c}; tmpB];
      dets = [dets; tmpD];
    end

    if latent
      % get best match
      for x = 1:size(score,2)
        for y = 1:size(score,1)
          scoreLoss=score(y, x);
          [x1, y1, x2, y2] = rootbox(x, y, scale, padx, pady, rsize{c});
          if trunc
              clipx1=max(x1,1);
              clipx2=min(x2,pyra.imsize(2));
              clipy1=max(y1,1);
              clipy2=min(y2,pyra.imsize(1));
          else
              clipx1=x1;
              clipx2=x2;
              clipy1=y1;
              clipy2=y2;
          end 
          yhat=[clipx1, clipy1, clipx2, clipy2,c];
          ybox=[bbox(1),bbox(2),bbox(3),bbox(4),compCoarse];
          l=loss(ybox,yhat, max(1,scoreLoss/4), trunc, occl);
          scoreLoss=scoreLoss-l;
          if scoreLoss > bestLoss
            % intesection with bbox
            xx1 = max(x1, bbox(1));
            yy1 = max(y1, bbox(2));
            xx2 = min(x2, bbox(3));
            yy2 = min(y2, bbox(4));
            w = (xx2-xx1+1);
            h = (yy2-yy1+1);
            if w > 0 && h > 0
              % check overlap with bbox
              inter = w*h;
              a = (clipx2-clipx1+1) * (clipy2-clipy1+1);
              b = (bbox(3)-bbox(1)+1) * (bbox(4)-bbox(2)+1);
              o = inter / (a+b-inter);
              if (o >= overlap)
                bestLoss=scoreLoss;
                best = score(y, x);
                boxes{1} = [x1 y1 x2 y2];
                dets = [x1 y1 x2 y2];
                if getInfo
                  rblocklabel = model.rootfilters{ridx{c}}.blocklabel;
                  oblocklabel = model.offsets{oidx{c}}.blocklabel;      
                  xc = round(x + rsize{c}(2)/2 - padx);
                  yc = round(y + rsize{c}(1)/2 - pady);          
                  info.level = level;
                  info.header = [label; id; level; xc; yc; ...
                               model.components{c}.numblocks; ...
                               model.components{c}.dim];
                  info.offset.bl = oblocklabel;
                  info.offset.w = 1;
                  info.root.bl = rblocklabel;
                  info.root.rsize=rsize{c};
                  info.root.x=x;
                  info.root.y=y;
                  info.part = [];
                end
                for j = 1:numparts{c}
                  [probex, probey, px, py, px1, py1, px2, py2] = ...
                      partbox(x, y, ax{c,j}, ay{c,j}, scale, ...
                              padx, pady, psize{c,j}, Ix{c,j}, Iy{c,j});
                  boxes{1} = [boxes{1} px1 py1 px2 py2];
                  if getInfo
                    def = -[(probex-px)^2; probex-px; (probey-py)^2; probey-py];
                    pblocklabel = model.partfilters{pidx{c,j}}.blocklabel;
                    dblocklabel = model.defs{didx{c,j}}.blocklabel;
                    info.part(j).bl = pblocklabel;
                    info.part(j).psize = psize{c,j};
                    info.part(j).py = py;
                    info.part(j).px=px;
                    info.def(j).bl = dblocklabel;
                    info.def(j).w = def;
                  end
                end
                boxes{1} = [boxes{1} c best];
                dets = [dets c best];
              end
            end
          end
        end
      end
    end
    if(numDetect>=maxnum)
        break;
    end
  end
end


% The functions below compute a bounding box for a root or part 
% template placed in the feature hierarchy.
%
% coordinates need to be transformed to take into account:
% 1. padding from convolution
% 2. scaling due to sbin & image subsampling
% 3. offset from feature computation    

function [x1, y1, x2, y2] = rootbox(x, y, scale, padx, pady, rsize)
x1 = (x-padx)*scale+1;
y1 = (y-pady)*scale+1;
x2 = x1 + rsize(2)*scale - 1;
y2 = y1 + rsize(1)*scale - 1;

function [probex, probey, px, py, px1, py1, px2, py2] = ...
    partbox(x, y, ax, ay, scale, padx, pady, psize, Ix, Iy)
probex = (x-1)*2+ax;
probey = (y-1)*2+ay;
px = double(Ix(probey, probex));
py = double(Iy(probey, probex));
px1 = ((px-2)/2+1-padx)*scale+1;
py1 = ((py-2)/2+1-pady)*scale+1;
px2 = px1 + psize(2)*scale/2 - 1;
py2 = py1 + psize(1)*scale/2 - 1;