# 自动发布 Firewall Map

工作流：[Firewall Map release](https://github.com/Opnwall/OPNsense-Firewall-Map/actions/workflows/firewall-map-release.yml)。目前目标固定为 OPNsense 26.7、FreeBSD 15.1 amd64，源中 ABI 为 `FreeBSD:15:amd64`。升级固件系列时需同时更新构建目标、框架固定提交及 `metadata.py`，重新实机验证。

## 发布新版本

1. 修改 `security/firewall-map/Makefile` 中的版本或修订号。每个公开版本都不可覆盖，修复需要增加 `PLUGIN_REVISION`。
2. 添加 `releases/firewall-map-VERSION.md`，只写本次变更、依赖和验证；版本、安装方法、源码提交和校验值由脚本统一追加。
3. 如修改前端，先运行 `sh tools/build-renderer.sh`，提交构建产物。将源码和说明推送到 `main`。
4. 给该提交创建并推送 `firewall-map-VERSION` 标签。例如 Makefile 为 `0.64`、修订号 `5` 时：

   ```sh
   git tag firewall-map-0.64_5
   git push origin firewall-map-0.64_5
   ```

标签必须与 Makefile 一致，提交必须属于 `main` 历史；不接受其他分支手动发布。也可在 Actions 的 Run workflow 选择 main：默认 `publish=false` 执行构建、签名、正确/错误公钥验证和产物一致性演练；选 true 才会公开发布。

## 单一构建产物

- Linux 检查前端构建一致性、Python/前端与发布脚本测试。
- GitHub 托管的 FreeBSD 15.1 VM 使用固定版本的官方插件框架编译 PF 采集器并打包。仅导出 Git 跟踪的文件。PF netlink 使用固定提交及 SHA256 的 OPNsense 26.7 官方头文件，防止误用标准 FreeBSD 的不同扩展接口。Python 3.13 的 YAML 依赖来自经过固定官方指纹验证的 OPNsense 源，不使用 FreeBSD 默认 Python 版本的替代包。
- 同一次构建生成安装包、SHA256SUMS、Release 更新说明和 release.json。签名任务保存其他插件，更新目标包和目录，并验证正确公钥成功、错误公钥失败。
- 最后一个任务再次验证包内部版本/ABI、源码提交、SHA256、Release/软件源包字节一致以及新旧目录后缀一致。
- 先准备 Release 草稿并回读资产校验，再提交签名源，最后公开 Release 并设为 Latest。发布采用并发锁和 Git 非强制推送，避免丢失他人发布。

GitHub Release 与分支提交无法跨 API 原子提交。如果中途失败，可能留下草稿，或已更新签名源但 Release 仍是草稿。请使用该运行的 **Re-run failed jobs** 复用相同签名产物恢复；不要重新构建并覆盖同一公开版本。已公开版本摘要不同会明确拒绝。签名任务后软件源若发生其他提交，应从签名任务重跑，重新包含新源内容。

## 签名密钥

环境 `signed-release` 的 `PKG_SIGNING_KEY` Secret 保存现有私钥。环境仅允许 main 分支及 firewall-map-* 标签，保留设备当前公钥信任。私钥只在签名步骤通过环境变量传入临时 VM，写入 `/tmp`、退出时删除；不放入工作区、缓存、产物或日志。工作流及第三方 Actions 固定提交 SHA。普通构建不接触该 Secret。

仓库只发布公钥。更换公钥必须先在设备完成信任迁移，不得关闭签名验证。更新私钥 Secret 可使用：

```sh
gh secret set PKG_SIGNING_KEY --repo Opnwall/OPNsense-Firewall-Map --env signed-release < /secure/path/repository.key
```

产物保留 30 天。工作流不登录或自动升级家庭设备；设备继续通过既有签名源的固件更新获取新版本。
