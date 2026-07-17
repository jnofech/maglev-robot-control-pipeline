function n_decimals = numdecpoints(x)
    [rows, cols] = size(x);
    n_decimals = 0;
    for ii=1:rows
        for jj=1:cols
            i = -1;
            X = 0;
            while X ~= x(ii,jj)
                i = i + 1;
                X = round(x(ii,jj), i);
            end
            n_decimals = max(n_decimals, i);
        end
    end
end