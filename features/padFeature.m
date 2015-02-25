function feat=padFeature(feat, pady, padx, useMeanFeat)
% Adds padding to featuremaps during latent detections. 
% The amount of padding is specified by pady ad padx. The occlusion feature
% in the padded areas is set to 1.

if(nargin<4)
    useMeanFeat=false;
end

feat = padarray(feat, [pady padx 0], 0);
if(useMeanFeat)
    load('meanHog.mat');
    feat(1:pady, :, :) = repmat(meanHog,[pady,size(feat,2),1]);
    feat(end-pady+1:end, :, :) = repmat(meanHog,[pady,size(feat,2),1]);
    feat(:, 1:padx, :) = repmat(meanHog,[size(feat,1),padx,1]);
    feat(:, end-padx+1:end, :) = repmat(meanHog,[size(feat,1),padx,1]);
end

% write boundary occlusion feature
feat(1:pady, :, end) = 1;
feat(end-pady+1:end, :, end) = 1;
feat(:, 1:padx, end) = 1;
feat(:, end-padx+1:end, end) = 1;
end
