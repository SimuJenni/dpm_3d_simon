function [ feat ] = featuresVL( im, sbin )
% Wrapper for vl_hog. Extends HOG features with occlusion bias.
feat=double(vl_hog(im2single(im), sbin));
feat(:, :, end+1) = 0;
end

