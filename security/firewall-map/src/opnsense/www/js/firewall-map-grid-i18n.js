/* Plugin-scoped adapters for OPNsense's Tabulator-backed UIBootgrid. */
(function (root) {
    const chinese = () => /^zh(?:[-_](?:cn|hans)(?:[-_].*)?)?$/i.test(root.document?.documentElement?.lang || 'en');
    root.FirewallMapGridI18n = {
        tableOptions() {
            return chinese() ? {locale: 'zh-cn', langs: {'zh-cn': {pagination: {
                first: '首页', first_title: '首页', last: '末页', last_title: '末页',
                prev: '上一页', prev_title: '上一页', next: '下一页', next_title: '下一页',
                page_title: '显示页码', page_size: '每页条数', counter: {showing: '显示', of: '共', rows: '条', pages: '页'}
            }}}} : {};
        },
        apply(grid) {
            if (!chinese()) return;
            const instance = grid.data('UIBootgrid');
            if (instance?.translations) {
                Object.assign(instance.translations, {
                    infos: '显示第 {{ctx.start}} 至 {{ctx.end}} 条',
                    infosTotal: '显示第 {{ctx.start}} 至 {{ctx.end}} 条，共 {{ctx.totalRows}} 条',
                    noresultsfound: '没有找到结果', search: '搜索', all: '全部'
                });
            }
        }
    };
})(globalThis);
