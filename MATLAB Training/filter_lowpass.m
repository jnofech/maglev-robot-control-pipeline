function [yy_filtered,filter1] = filter_lowpass(ix,iy,icenter,iwidth,ishape,imode,ifilt)
% (jnofech, 03-12-24)
% Given a time-series signal (xx) in milliseconds, applies a low-pass
% filter to it as specified (using parameters in 'ifilter.m').
% 
% Fixes tailing ends by padding before filtering, and cropping afterwards.
center_freq = 0;
mode = 1;
filtermode = 'Low-pass';

switch nargin    
    % 'nargin' is the number of arguments
    case 3
        datasize=size(ix);
        if isvector(ix)
            xx=1:length(ix); % Use this only to create an x vector if needed
            yy=ix;
        else
            if datasize(1)<datasize(2),ix=ix';end
            xx=ix(:,1);
            yy=ix(:,2);
        end
        filterwidth = iy;
        filtershape = icenter;
    case 4
        datasize=size(ix);
        xx = ix;
        yy = iy;
        filterwidth = icenter;
        filtershape = iwidth;
    case 6
        datasize=size(ix);
        xx = ix;
        yy = iy;
        center_freq = icenter;
        filterwidth = iwidth;
        filtershape = ishape;
        mode = imode;
    case 7
        datasize=size(ix);
        xx = ix;
        yy = iy;
        center_freq = icenter;
        filterwidth = iwidth;
        filtershape = ishape;
        mode = imode;
        filtermode = ifilt;
    otherwise
        disp('Invalid number of arguments')

end
    % Inaccurate region width?
    inacc_width_ms = 1/filterwidth * 6;     % Calibrated empirically
    pad_width = ceil(inacc_width_ms);

    % PAD arrays!
    % xx
    dt = median(xx - circshift(xx,1,1));
    xx_padding = xx(end)+(dt:dt:(dt*pad_width*2))';
    xx_padded = cat(1,xx,xx_padding);
    % yy
    yy_padded = padarray(yy,pad_width,'symmetric');

    % ~~ Filter as specified ~~
    [yy_padded_filtered,filter1] = ifilter_noplot(xx_padded,yy_padded,center_freq,filterwidth,filtershape,mode,filtermode);
    yy_padded_filtered = yy_padded_filtered';

    % CROP array!
    yy_filtered = yy_padded_filtered(1+pad_width:end-pad_width);   

    % plot(xx,yy_filtered)
end
