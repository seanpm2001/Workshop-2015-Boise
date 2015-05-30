--input: cone inputCone, fan F such that inputCone is contained in a face of F
--output: a cone, the smallest cone of F containing C
needsPackage("Polyhedra");
smallestContainingCone = (F,inputCone) -> (
    recurser := (bigCone,checkCone) -> (
        for C in faces(1,bigCone) do (
            if contains(C,checkCone) then (
                return recurser(C,checkCone);
            );
        );
        --checkCone is not in any of the smaller cones
        return bigCone; 
    );
    for C in maxCones(F) do (
        if contains(C,inputCone) then (
            return recurser(C,inputCone);
        );
    );
    {*  if we've gotten this far, then inputCone isn't contained
        in any of the maximal cones of F, i.e. bad input  *}
    error "-- input cone is not contained in any cone of fan";
);

-- EXAMPLE
F = normalFan hypercube 2;
C = posHull matrix {{1,0},{1,1}};
C2 = posHull matrix {{1,-1},{1,1}};
--smallestContainingCone(F,C)
--smallestContainingCone(F,C2)

--input: fan1, source fan; fan2, target fan; M, matrix map of lattices
--output: list of tuples {c,imC} where imC is the smallest cone in fan2
--        containing the image of c (a cone in fan1) under the map M
minImageCones = (fan2,fan1,M) -> (
    return apply(maxCones(fan1),c->{c,smallestContainingCone(fan2,posHull(M*rays(c)))})
);


maxContainingCone = (F,inputCone) -> (
    for C in maxCones(F) do (
        if contains(C,inputCone) then (
            return C;
        );
    );
    {*  if we've gotten this far, then inputCone isn't contained
        in any of the maximal cones of F, i.e. bad input  *}
    error "-- input cone is not contained in any cone of fan";
);


--For each maximal cone C of fan1, returns a maximal cone from fan2
--that contains the image of C under M
maxImageCones =  (fan2,fan1,M) -> (
    return apply(maxCones(fan1),c->maxContainingCone(fan2,posHull(M*rays(c))))
);


--input: M, a matrix; X and Y, source and target normal toric varieties
--output: b, a boolean value, true iff M respects the fans of X and Y
isCompatible = (Y,X,M) -> (
    local xConeContained;
    local imCx;
    for Cx in maxCones(fan(X)) do (
        xConeContained = false;
        imCx = posHull(M*rays(Cx));
        for Cy in maxCones(fan(Y)) do (
            if contains(Cy,imCx) then (
                xConeContained = true;
                break;
            );
        );
        if not xConeContained then return false;
    );
    return true;
);

--input: M, a matrix; X and Y, source and target normal toric varieties
--output: b, a boolean value, true iff M is a proper map from X to Y
--The symmdiff idea, with Lfaces, comes directly from the method isComplete
--from the Polyhedra package. 
isProper = (Y,X,M) -> (
    if not isCompatible(Y,X,M) then return false;  --unnecessary?
    if dim X != dim Y then return false;
    imageFan := fan(apply(maxCones(fan(X)),c->posHull(M*rays(c))));

    --finds cones of fan F inside cone C
    findInteriorCones := (C,F) -> (
        n:=dim C;
        return select(cones(n,F),c->contains(C,c));
    );

    --make a hash table of maxcones in target => equal dimensional 
    --cones mapped from source it contains
    h = hashTable(toList(apply(maxCones(fan(Y)),c -> (c,interiorCones(c,imageFan)))));

    symmDiff := (x,y) -> ((x,y) = (set x,set y); toList ((x-y)+(y-x)));

    for bigCone in maxCones(fan(Y)) do (
        interiorCones := findInteriorCones(bigCone,imageFan);
        if interiorCones == {} then return false;
        Lfaces := {};
        scan(interiors, C -> if dim C == n then Lfaces = symmDiff(Lfaces,faces(1,C)));
        for inside in Lfaces do (
            isContained := false;
            for outer in faces(1,bigCone) do (
                if contains(outer,inner) then (
                    isContained = true;
                    break;
                );
            );
            if not isContained then return false;
        );
    );
    return true;
)
