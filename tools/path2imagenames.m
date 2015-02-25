function [ names ] = path2imagenames( path )
% Extracts image file names (the full path) in a folder
%
% input: path: the folder path
%
% output: names: cell list of strings containing the image paths

names = {};
fileList = dir(path);
for k = 1:numel(fileList)
    [~, name, ext] = fileparts(fileList(k).name);
    if fileList(k).isdir
        continue;
    end
    if strcmp(ext,'.JPEG') || strcmp(ext,'.jpeg') || strcmp(ext,'.png') || ...
            strcmp(ext,'.JPG') || strcmp(ext,'.jpg') || strcmp(ext,'.tif')
        names{end+1} = sprintf('%s/%s%s',path,name,ext);
    end
end


end

