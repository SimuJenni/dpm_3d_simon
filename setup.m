setUpGlobals;

% local path
addpath(genpath('./'));

% 3rd party libraries
run([Datadir '/3rd_party/vlfeat-0.9.19/toolbox/vl_setup']); % vlfeat
run([Datadir '/3rd_party/matconvnet/matlab/vl_setupnn']); % matconvnet