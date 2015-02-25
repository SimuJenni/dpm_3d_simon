function [pos, spos] = split(pos, numComp, numElev)
% Splits viewpoint annotated positive examples into different
% training sets and assigns them to mixture components.
% pos(i).component: Forces latent detections to use specified component.
%                   Value of 0 forces no specific component.
% pos(i).compCoarse: Penalizes score of latent detections not using this
%                    component via penalty term.
% pos(i).constrained: Enforces 3D constraints on these examples. (only used
%                     on CAD models with exact component viewpoint)
% Input:    pos - positive examples with viewpoint annotations
%           numComp - number of mixture components the model will have.
%                     numComp/numElevs should be even.
%           numElevs - number of different elevations the model will be
%                      trained on. 1<=numElev<=3
% Output:   pos - positive examples with annotations used during training 
%           spos{c} - Subsets of pos used to initialize component c

globals;

try
  load([cachedir 'car' '_pos_split_' num2str(numComp)]);
catch
fprintf('%s: splitting positives...', cls);

deltaAngle=min(floor(180/(numComp/numElev))-1,20);   % force viewpoint on angles +- deltaAngle
deltaElev=min(deltaAngle/numElev, 15);
deltaCoarse=floor(180/(numComp/numElev))-0.5;
numpos=size(pos,2);

[angles, elevs]=getViewpoints(numComp, numElev);

exactIdx=zeros(numpos,1);   % index to examples with exact component viewpoint
% assign positive examples to components based on angle and elevation.
for i=1:numpos
    if (isInRange(pos(i).angle, angles, pos(i).elev, elevs, deltaCoarse, 2*deltaCoarse/3))
        pos(i).compCoarse=getComponent(numComp, pos(i).angle, pos(i).elev, elevs, numElev);
    else
        pos(i).compCoarse=0;
    end
    if (isInRange(pos(i).angle, angles, pos(i).elev, elevs, deltaAngle, deltaElev))
        pos(i).component=getComponent(numComp, pos(i).angle, pos(i).elev, elevs, numElev);
    else
        pos(i).component=0;  % no forcing of component during latent detections
    end
    if (isInRange(pos(i).angle, angles, pos(i).elev, elevs, 8, 4))
        if(pos(i).modelID>0)
            pos(i).constrained=true; % these will be used for the 3d constraints
        else
            pos(i).constrained=false;
        end
        exactIdx(i)=1;
    else
        pos(i).constrained=false;
    end
end

M=[pos(:).compCoarse]'>0;
L=[pos(:).trunc]'<1;
pos_compInit=pos(M&L);  % examples used to initialise rootfilters.

% divide training set between components
for i=1:numComp
    I=[pos_compInit(:).compCoarse]'==i;
    spos{i}=pos_compInit(I);
end

save([cachedir 'car' '_pos_split_' num2str(numComp)], 'pos', 'spos');
fprintf('done');

end

end    

% Assign positive examples to mixture-component based on viewpoint
% annotations, number of components and number of different elevations the
% model will be trained on
function c=getComponent(numComp, angle, elev, elevs, numElev)
c=0;
[dElev,I]=min(abs(elevs-elev));
for i=1:numElev
    if(abs(elev-elevs(i))<=dElev)
            angleSector=2*pi/(numComp/numElev);
            c=mod(floor(((angle)+angleSector/2)/angleSector),numComp/numElev)+1+(i-1)*numComp/numElev;
    end
end
end

% check if the example is within deltaAngle of a component-viewpoint
function b=isInRange(angle, angles, elev, elevs, deltaAngle, deltaElev)
    b=false;
    dElev=min(abs(elevs-elev));
    if(dElev<deltaElev*pi/180)
        for i=1:size(angles,2)
            if(abs(angle*180/pi-angles(i))<=deltaAngle)
                b=true;
            end
        end
    end
end
