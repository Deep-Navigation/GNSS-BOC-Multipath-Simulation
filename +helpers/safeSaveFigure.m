function safeSaveFigure(figHandle, basePathNoExt)
%SAFESAVEFIGURE 安全保存 figure 为 FIG 和 PNG
%
%   helpers.safeSaveFigure(figHandle, basePathNoExt)
%
%   输入:
%       figHandle     - figure 句柄
%       basePathNoExt - 不带扩展名的完整保存路径
%
%   功能:
%       1. 优先保存 .fig
%       2. 再导出 .png
%       3. 对图窗句柄做基础校验
%       4. 尽量避免因 savefig/exportgraphics 失败导致主流程中断

    if nargin < 2 || isempty(basePathNoExt)
        error('helpers.safeSaveFigure:InvalidInput', ...
            'basePathNoExt 不能为空。');
    end

    if nargin < 1 || isempty(figHandle) || ~ishandle(figHandle) || ~strcmp(get(figHandle, 'Type'), 'figure')
        figHandle = gcf;
    end

    if isempty(figHandle) || ~ishandle(figHandle) || ~strcmp(get(figHandle, 'Type'), 'figure')
        error('helpers.safeSaveFigure:InvalidFigure', ...
            '未找到有效的 figure 句柄，无法保存图像。');
    end

    basePathNoExt = char(basePathNoExt);

    drawnow;

    % 保存 FIG
    try
        savefig(figHandle, [basePathNoExt, '.fig']);
    catch ME
        warning('helpers.safeSaveFigure:SaveFigFailed', ...
            'savefig 保存失败：%s', ME.message);
    end

    % 导出 PNG
    try
        exportgraphics(figHandle, [basePathNoExt, '.png'], 'Resolution', 300);
    catch
        try
            saveas(figHandle, [basePathNoExt, '.png']);
        catch ME
            warning('helpers.safeSaveFigure:SavePngFailed', ...
                'PNG 导出失败：%s', ME.message);
        end
    end
end