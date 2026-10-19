/* Translate display text only. Filtering, downloads and persisted log records stay original. */
(function (root) {
    const chinese = () => /^zh[-_](?:CN|Hans)(?:[-_].*)?$/i.test(root.document?.documentElement?.lang || '');
    const escape = text => String(text ?? '').replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
    function translate(value) {
        const text = String(value ?? '').trim();
        if (!chinese()) return text;
        if (text === 'settings applied') return '设置已应用';
        if (text === 'settings changed: reloading them') return '设置已更改：正在重新加载';
        let match;
        if ((match = text.match(/^blocklist aliases: (.+)$/))) return `黑名单别名：${match[1].replace(/\badded /g, '已添加 ').replace(/\bremoved /g, '已移除 ').replace(/\bupdated /g, '已更新 ')}`;
        if ((match = text.match(/^threat lists without a PF table are not used \(enable Maintain blocklist aliases or create the aliases\): (.+)$/))) return `以下威胁名单缺少 PF 表，未被使用（请启用“维护黑名单别名”或创建别名）：${match[1]}`;

        if ((match = text.match(/^geolocation download failed \((\d+) in a row\): next try in (\d+) min$/))) {
            return `地理库下载连续失败 ${match[1]} 次，将在 ${match[2]} 分钟后重试`;
        }
        if ((match = text.match(/^(GeoLite2-(?:City|ASN)):\s*(?:&lt;|<)urlopen error \[Errno 2\] Name could not be resolved at this time(?:&gt;|>) \(unreachable\)$/))) {
            return `${match[1]}：域名暂时无法解析，未能连接下载服务器（DNS 错误）`;
        }
        if ((match = text.match(/^(.+?) downloaded: (.+?), built (.+)$/))) {
            return `${match[1]} 下载成功：${match[2]}，数据库构建日期 ${match[3]}`;
        }
        if ((match = text.match(/^a map is open: sampling every (.+?) seconds$/))) return `地图已打开：每 ${match[1]} 秒采样`;
        if (text === 'no map open: recording threats in the background') return '地图未打开：正在后台记录威胁';
        if (text === 'collector started: a map is open') return '采集器已启动：地图已打开';
        if ((match = text.match(/^collector stopped \(signal (.+)\)$/))) return `采集器已停止（信号 ${match[1]}）`;
        if ((match = text.match(/^temporary DNS lookup failure: retry (\d+)\/2 in (\d+) s$/))) return `DNS 暂时解析失败：${match[2]} 秒后进行第 ${match[1]}/2 次重试`;
        return text;
    }
    root.FirewallMapLogDisplay = {
        translate,
        line(value) {
            const original = String(value ?? '');
            return `<span title="${escape(original)}">${escape(translate(original))}</span>`;
        },
        severity(value) {
            const names = {Emergency:'紧急', Alert:'警报', Critical:'严重', Error:'错误', Warning:'警告', Notice:'通知', Informational:'信息', Debug:'调试'};
            return escape(chinese() ? names[value] || value : value);
        }
    };
})(globalThis);
