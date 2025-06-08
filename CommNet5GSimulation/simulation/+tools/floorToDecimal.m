function result = floorToDecimal(X, N)
    % X 是需要处理的数字
    % N 是小数位数
    result = floor(X * 10^N) / 10^N;
end