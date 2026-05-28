function info = list_experiment_types(returnStruct)
%LIST_EXPERIMENT_TYPES
% 列出当前支持的实验类型。
%
% 使用方式：
%   list_experiment_types()
%   info = list_experiment_types(true)
%
% 输出：
%   info.keys
%   info.displayNames
%   info.aliases

    if nargin < 1 || isempty(returnStruct)
        returnStruct = false;
    end

    registry = get_experiment_registry();

    keys = cell(1, numel(registry));
    displayNames = cell(1, numel(registry));
    aliases = cell(1, numel(registry));

    for i = 1:numel(registry)
        keys{i} = registry(i).key;
        displayNames{i} = registry(i).displayName;
        aliases{i} = registry(i).aliases;
    end

    info = struct();
    info.keys = keys;
    info.displayNames = displayNames;
    info.aliases = aliases;

    if ~returnStruct
        fprintf('\nSupported experiment types:\n');
        fprintf('---------------------------------------------\n');
        for i = 1:numel(registry)
            fprintf('%d) %-22s  %s\n', i, keys{i}, displayNames{i});
        end
        fprintf('---------------------------------------------\n');
    end
end