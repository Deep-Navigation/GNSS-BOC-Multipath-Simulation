function writeTextFile(filePath, lines)
%WRITETEXTFILE 将文本行写入文件
%
%   helpers.writeTextFile(filePath, lines)
%
%   输入:
%       filePath - 目标文本文件路径
%       lines    - 字符串元胞数组 / 字符串数组 / 单个字符串
%
%   功能:
%       逐行写入文本文件，适合保存摘要、日志和结果说明。

    if nargin < 2
        error('helpers.writeTextFile:InvalidInput', ...
            '必须提供 filePath 和 lines。');
    end

    if isstring(lines)
        lines = cellstr(lines);
    elseif ischar(lines)
        lines = {lines};
    end

    if ~iscell(lines)
        error('helpers.writeTextFile:InvalidLines', ...
            'lines 必须是元胞数组、字符串数组或字符向量。');
    end

    filePath = char(filePath);

    fid = fopen(filePath, 'w');
    if fid == -1
        error('helpers.writeTextFile:OpenFailed', ...
            '无法写入文本文件：%s', filePath);
    end

    cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>

    for i = 1:numel(lines)
        lineStr = lines{i};
        if isstring(lineStr)
            lineStr = char(lineStr);
        end
        fprintf(fid, '%s\n', lineStr);
    end
end