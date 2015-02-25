function pos = pascal3Dpos(cls, VOCopts, Pascal3D, pos, count, flippedpos)
% Reads positive training images from Pascal3D+ including annotations and
% stores them in the structure defined in data3D.m

% initialize the PASCAL development kit 
tmp = pwd;
cd([Pascal3D '/PASCAL/VOCdevkit/']);
addpath([cd '/VOCcode']);
VOCinit;
cd(tmp);

% Get training examples
ids = textread(sprintf(VOCopts.imgsetpath, 'train'), '%s');
N = length(ids);
path_image = sprintf([Pascal3D '/Images/%s_pascal'], cls);
path_anno = sprintf([Pascal3D '/Annotations/%s_pascal'], cls);

for i = 1:N        
    file_ann = sprintf('%s/%s.mat', path_anno, char(ids(i)));
    if mod(i, 100) == 0
        fprintf('%s: parsing positives Pascal3D+: %d/%d\n', cls, i, length(ids));
    end    
    try
        image = load(file_ann);
    catch
        continue;
    end
    record = image.record;
    objects = record.objects;
    numInstances=0;
    for j = 1:length(objects)
        numInstances=numInstances+strcmp(cls, objects(j).class);
    end
    for j = 1:length(objects)
        if isfield(objects(j), 'viewpoint') == 0 || ~strcmp(cls, objects(j).class) %|| objects(j).difficult == 1
            continue;
        end
        viewpoint = objects(j).viewpoint;
        if isempty(viewpoint)
            continue;
        end
        bbox = objects(j).bbox;
        file_img = sprintf('%s/%s.jpg', path_image, char(ids(i)));
        count = count + 1;
        pos(count).im = file_img;
        pos(count).x1 = bbox(1);
        pos(count).y1 = bbox(2);
        pos(count).x2 = bbox(3);
        pos(count).y2 = bbox(4);
        pos(count).trunc = objects(j).truncated;
        pos(count).occluded = objects(j).occluded;
        pos(count).flip = false;
        pos(count).numInstances=numInstances;
        if viewpoint.distance == 0
            azimuth = 360-viewpoint.azimuth_coarse;
        else
            azimuth = 360-viewpoint.azimuth;
        end
        if azimuth >= 360
            azimuth = 360 - azimuth;
        end
        elevation=viewpoint.elevation;
        pos(count).angle = azimuth*pi/180;     
        pos(count).elev=elevation*pi/180;
        pos(count).modelID=NaN;
        % flip the positive example
        if flippedpos
            oldx1 = bbox(1);
            oldx2 = bbox(3);
            bbox(1) = record.imgsize(1) - oldx2 + 1;
            bbox(3) = record.imgsize(1) - oldx1 + 1;
            count = count + 1;
            pos(count).im = file_img;
            pos(count).x1 = bbox(1);
            pos(count).y1 = bbox(2);
            pos(count).x2 = bbox(3);
            pos(count).y2 = bbox(4);
            pos(count).trunc = objects(j).truncated;
            pos(count).occluded = objects(j).occluded;
            pos(count).flip = true;
            pos(count).numInstances=numInstances;
            % flip viewpoint
            azimuth = 360 - azimuth;
            if azimuth >= 360
                azimuth = 360 - azimuth;
            end
            pos(count).angle = azimuth*pi/180;     
            pos(count).elev=elevation*pi/180;
            pos(count).modelID=NaN;
        end
    end
end