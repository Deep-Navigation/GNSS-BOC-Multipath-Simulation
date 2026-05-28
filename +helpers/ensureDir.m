function ensureDir(folderPath)
%ENSUREDIR 若目录不存在则创建
%
%   helpers.ensureDir(folderPath)
%
%   输入:
%       folderPath - 目标目录路径（字符串或字符向量）

    if nargin < 1 || isempty(folderPath)
        error('helpers.ensureDir:InvalidInput', ...
            'folderPath 不能为空。');
    end

    if ~(ischar(folderPath) || isstring(folderPath))
        error('helpers.ensureDir:InvalidInputType', ...
            'folderPath 必须是字符向量或字符串。');
    end

    folderPath = char(folderPath);

    if ~exist(folderPath, 'dir')
        mkdir(folderPath);
    end
end