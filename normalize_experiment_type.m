function normalizedType = normalize_experiment_type(experimentType)
%NORMALIZE_EXPERIMENT_TYPE
% 将实验类型字符串归一化为标准 key。
%
% 使用方式：
%   key = normalize_experiment_type('phase')
%   key = normalize_experiment_type("spacing_3d")

    if ~(ischar(experimentType) || isstring(experimentType))
        error('normalize_experiment_type: experimentType 必须是字符向量或字符串。');
    end

    typeStr = lower(strtrim(char(experimentType)));
    registry = get_experiment_registry();

    for i = 1:numel(registry)
        aliases = registry(i).aliases;
        if any(strcmp(typeStr, aliases))
            normalizedType = registry(i).key;
            return;
        end
    end

    validKeys = cell(1, numel(registry));
    for i = 1:numel(registry)
        validKeys{i} = registry(i).key;
    end

    error('normalize_experiment_type: 无法识别 experimentType = %s。支持类型：%s', ...
        typeStr, strjoin(validKeys, ', '));
end