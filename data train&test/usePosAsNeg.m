function [ neg ] = usePosAsNeg( pos, neg )
% Adds positive examples to the negative examples. Used for 3D-DPM CNN PN.
    uniquePos=[pos(:).numInstances]==1;
    tmpneg=pos(uniquePos);
    numneg=length(neg);
    for i=1:numneg
        neg(i).compCoarse=0;
        neg(i).component=0;
        neg(i).constrained=false;
    end
    tmpneg(end+1:end+numneg)=neg;
    neg=tmpneg;
end

