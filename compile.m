mex -O resize.cc -output ./bin/resize
% mulththreaded convolution without blas
mex -O fconvMT.cc -output ./bin/fconv

% Compile the learning code
unix('make');
unix('mv learn ./bin/learn');

