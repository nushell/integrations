## 使用说明

1. 准备工作 ：

   - 确保已安装 Wix Toolset 6
   - 创建一个简单的 license.rtf 文件作为许可协议

2. 构建 MSI ：

   - 对于 x64 架构： `dotnet build -c Release -p:Platform=x64`
   - 对于 ARM64 架构： `dotnet build -c Release -p:Platform=arm64`

3. 安装选项 ：

   - 用户范围安装： `winget install nushell.msi --scope user`
   - 机器范围安装： `winget install nushell.msi --scope machine` （需要管理员权限）

   # For per-user installation
   `msiexec /i bin\x64\Release\nushell-x64.msi MSIINSTALLPERUSER=1 ALLUSERS=""`

   # For per-machine installation (requires admin privileges)
   `msiexec /i bin\x64\Release\nushell-x64.msi ALLUSERS=1 MSIINSTALLPERUSER=""`

## 特性说明

1. 双重安装范围 ：支持用户和机器范围安装
2. `PATH` 环境变量 ：自动将安装目录添加到系统 `PATH`
3. 升级保留 ：升级时保留原安装路径
4. 多架构支持 ：支持 `x86_64` 和 `ARM64` 架构
5. 系统兼容性 ：兼容 Windows 7/10/11

## REF

- https://docs.firegiant.com/quick-start/
