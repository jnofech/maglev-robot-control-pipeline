function plot_highlight_regions(times,boolarray,colour,displayname)
    switch nargin
        case 2
            % No colour or displayname
            showlegend = false;
            colour = [1 0 0 0.5];
        case 3
            if class(colour)=="double"
                % Third input is probably colours+alpha.
                % No displayname
                showlegend = false;
            elseif class(colour)=="string"
                % Third input is probably display name.
                % No colour
                showlegend = true;
                displayname = colour;
                colour = [1 0 0 0.5];
            end
        case 4
            % All inputs specified
            showlegend = true;
            assert(class(colour)=="double");
            assert(class(displayname)=="string");
        otherwise
            error("Invalid number of arguments")
    end
    if showlegend
        handlevisibility = 'on';
    else
        handlevisibility = 'off';
        displayname = "";
    end

    % Get window range; draw bars accordingly
    xl = xlim; xmin=xl(1); xmax=xl(2);
    yl = ylim; ymin=yl(1); ymax=yl(2);
    hold on
    p = area(times, ymin + (ymax-ymin)*boolarray,'DisplayName',displayname,'HandleVisibility', handlevisibility);
    p.EdgeAlpha = 0;
    p.FaceAlpha = colour(4);
    p.FaceColor = colour(1:3);
    p.BaseLine.BaseValue = ymin;
    p.BaseLine.Visible = 'off';
    xlim([xmin,xmax]);
    ylim([ymin,ymax]);
    hold off
end