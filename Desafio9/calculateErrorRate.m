function errorRate = calculateErrorRate(I1, gt)
    tot = 0;
    err = 0;
    for i = 1:length(I1(:,1))
        for j = 1:length(I1)
            if I1(i,j) ~= 0
                if abs(I1(i,j) - gt(i,j)) > 1
                    err = err + 1;
                end
                tot = tot + 1;
            end
        end
    end
    errorRate = (err / tot) * 100;
end
