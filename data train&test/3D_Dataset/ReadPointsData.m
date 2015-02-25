function [Data, Size] = ReadPointsData(path)
%%
%%  function [Data, Size] = ReadPointsData(path)
%%
%%  return a binary image containing the outline (silhouette) of the object 
%%
%%  path = file name (in .mask format)
%%  Data = binary image; 255-> object silhouette; 0-> background 
%%  Size = size of the binary image 
%%
%%  (c) October 2006

% check number and type of arguments
if nargin < 1
  error('Function requires one input argument');
elseif ~isstr(path)
  error('Input must be a string representing a filename');
end


fid = fopen(path);
if fid==-1
  error('File not found or permission denied');
end

frewind(fid);

Size = zeros(1,2);
Size = fscanf(fid,'%d %d',2)';
Data = zeros(Size(1,1),Size(1,2),'uint8');
Data = fscanf(fid,'%u ',[size(Data,1) size(Data,2)]);
fclose(fid);

return
