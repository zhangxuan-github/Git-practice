function L = infpl(R,lambda,speed)
%fspl     INF  path loss and shadow fading( 距离 1<=R<=600m）
%   L = infpl(R,LAMBDA) returns the InF path loss L (in dB) suffered
%   by a signal with wavelength LAMBDA (in meters) when it is propagated in
%   InF for a distance of R (in meters). R can be a length-M vector
%   and LAMBDA is a length-N vector. L is an MxN matrix whose elements are
%   the free space path loss for the corresponding propagation distance
%   specified in R at the wavelength specified in LAMBDA. When LAMBDA is a
%   scalar, L has the same dimensions as R.
%
%   Note that the best case is lossless so the loss is always greater than
%   or equal to 0 dB.
%
%   See also cranerainpl, fogpl, gaspl, rainpl.


validateattributes(R, {'double'}, {'nonnan','nonempty','real', ...
    'vector','nonnegative'}, 'infpl', 'R');
validateattributes(lambda, {'double'}, {'nonnan','nonempty','real', ...
    'vector','positive'}, 'infpl', 'LAMBDA');
shadowfading = normrnd(0,4.3);
switch speed
    case 5
        fastfading=6.0607224;
    case 10
        fastfading=5.4125104;
    case 15
        fastfading=6.1249886;
    case 20
        fastfading=3.0333443;
    otherwise
        fastfading=3.0706782;
end
if isscalar(lambda)
    fc=physconst('LightSpeed')/lambda * 10e-9;
    L = 31.84+21.5*log10(R)+19*log10(fc)+shadowfading + fastfading;
else
    printf('R OR LAMDA IS NOT SACALAR')
%     fc=physconst('LightSpeed')*(1./(lambda(:).'));
%     L = 31.84+21.5*log10(R:)+19*log10(fc:)+shadowfading;  
end

end

% [EOF]