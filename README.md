# Orange Pi Zero / Zero Plus — OpenWrt 自动云编译

基于 [LEDE](https://github.com/coolsnowwolf/lede) 源码（内核 6.18），通过 GitHub Actions 自动编译香橙派 **Orange Pi Zero** 和 **Orange Pi Zero Plus** 两个型号的 OpenWrt 固件。每 18 小时自动跟随上游更新重新编译，固件发布在 [Releases](https://github.com/7noemo/Orange-Pi-Zero-ZeroPlus-Openwrt/releases)。

> 🆕 **Orange Pi Zero 3 (H618) 用户请移步新仓库**：[Orange-Pi-Zero-3-Openwrt](https://github.com/7noemo/Orange-Pi-Zero-3-Openwrt)（基于 ImmortalWrt，板载 AW859A Wi-Fi 开箱即用）

## 📦 支持设备

| 设备 | SoC | 架构 | 固件状态 | 板载 Wi-Fi |
|---|---|---|---|---|
| Orange Pi Zero | Allwinner H2+ | armv7 (cortex-a7) | ✅ 正常发布 | XR819 ❌ 无可用主线驱动，建议插 USB Wi-Fi 网卡 |
| Orange Pi Zero Plus | Allwinner H5 | aarch64 (cortex-a53) | ✅ 正常发布 | RTL8189FTV ✅ **已内置驱动，刷机即用** |

## ✨ 固件特性

- **内核 6.18**，LEDE master 最新源码
- **Zero Plus 内置 RTL8189FTV Wi-Fi 驱动**：自打包 `kmod-rtl8189fs`（源码钉死 commit + OpenWrt 6.18 适配补丁），配 `wpad` + `iw-full`，刷完 LuCI 直接配置无线
- 编译失败时不发布空 Release（固件完整性有保障）
- 插件清单（两个型号略有差异）：

  | 类别 | 插件 |
  |---|---|
  | 科学上网 | OpenClash、PassWall / PassWall2（Zero）、SSR Plus+（Zero） |
  | 存储/服务 | Docker（含 Compose + LuCI 管理）、Samba、aria2 + AriaNg、硬盘休眠（hd-idle） |
  | 工具 | 广告过滤（adbyby）、磁盘管理（DiskMan）、USB 打印服务 |
  | 主题 | Argonne、Material |

## 📥 下载与刷机

1. 前往 [**Releases**](https://github.com/7noemo/Orange-Pi-Zero-ZeroPlus-Openwrt/releases) 下载对应型号的 `*squashfs-sdcard.img.gz`
2. 解压后用 **balenaEtcher / Rufus** 写入 TF 卡（或 `sudo dd if=xxx.img of=/dev/sdX bs=4M conv=fsync`）
3. 插卡上电，网线连接，浏览器访问 `192.168.1.1`
4. 默认用户 `root`，密码为空，登录后请立即设置密码

## 🔧 自定义

想加/减插件：fork 本仓库，修改对应型号的 `.config` 文件（`orange-pi-zero.config` / `orange-pi-zero-plus.config`），在 Actions 页面手动触发 `Build OpenWrt` workflow 即可。

仓库结构：

```
├── .github/workflows/        # GitHub Actions 云编译流程
│   ├── build-openwrt-zero.yml
│   ├── build-openwrt-zero-plus.yml
│   └── update-checker.yml    # 每 18h 检查上游更新并触发编译
├── orange-pi-zero.config     # Zero 固件配置
├── orange-pi-zero-plus.config# Zero Plus 固件配置
├── rtl8189fs/                # 自打包 RTL8189FTV Wi-Fi 驱动（含 6.18 内核适配补丁）
├── diy-part1.sh              # 构建前置脚本（拉取插件 feed / 驱动包）
└── diy-part2.sh              # 构建后置脚本
```

## ⚠️ 已知限制

- **Orange Pi Zero 板载 XR819 Wi-Fi 无解**：该芯片无稳定 Linux 驱动（OpenWrt 官方 wontfix），需要无线请插 USB Wi-Fi 网卡（RTL8188EU / MT7601U 等主线驱动齐全的型号）
- 因 node v24 无法在 arm 上交叉编译，固件不含依赖 node 的插件（如网易云音乐解锁）

## 🙏 致谢

- [P3TERX/Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt) — workflow 原型
- [coolsnowwolf/lede](https://github.com/coolsnowwolf/lede) — LEDE 源码
- [kenzok8](https://github.com/kenzok8/openwrt-packages) — 插件 feed
- [EvilOlaf/rtl8189ES_linux](https://github.com/EvilOlaf/rtl8189ES_linux) — RTL8189FS 驱动源码

## 📜 License

[MIT](./LICENSE)
