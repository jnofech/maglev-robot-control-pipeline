function [filename_index] = parse_mf4_number(fullpath)
%Given the path of an .mf4 file (e.g. "D:\Folder\Subfolder\rec1_0018.mf4"),
% extracts the number before the ".mf4" bit and returns it as an integer.
    expression = '(\d+)\.mf4$';
    filename_index_str = regexp(fullpath, expression, 'tokens', 'once');

    if ~isempty(filename_index_str)
        filename_index = str2double(filename_index_str);
    else
        filename_index = nan;
    end
end