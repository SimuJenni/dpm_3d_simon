function evaluateModel( numComp )
globals;
load([cachedir cls '_final_' num2str(numComp)]);
n=numComp;

% On VOC 2007
if(useVOC2007)
    testVOC2007(cls, n);
    [ recall, precision, ap ] = evalVOC2007( cls, n );
end

% On Pascal 3D+
if usePascal3D
    testPascal3D(cls, n);
    [recall, precision, accuracy, ap, aa] = evalPascal3D(cls, n, n);
end

if(n==8)
    if use3DDataset
        % On 3D object Dataset
        test3DDataset(cls, n);
        [ recall, precision, accuracy, ap, aa, MPPE ] = eval3DDataset( cls, n );
    end
end

end

