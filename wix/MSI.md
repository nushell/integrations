## 使用说明

1. 准备工作 ：

   - 确保已安装 Wix Toolset 6.0: `dotnet tool install --global wix --version 6.0.0`

2. 构建 MSI ：

   - 对于 x64 架构： `dotnet build -c Release -p:Platform=x64`
   - 对于 ARM64 架构： `dotnet build -c Release -p:Platform=arm64`

3. 安装选项 ：

   - 用户范围安装： `winget install Nushell.Nushell --scope user`
   - 机器范围安装： `winget install Nushell.Nushell --scope machine` （需要管理员权限）

   # For Per-User Installation
   `msiexec /i bin\x64\Release\nu-x64.msi MSIINSTALLPERUSER=1`

   # For Per-Machine Installation (Requires Admin Privileges)
   `msiexec /i bin\x64\Release\nu-x64.msi ALLUSERS=1`

   # MSI Install with Logs
   `msiexec /i bin\x64\Release\nu-x64.msi ALLUSERS=1 /l*v log.txt`

## 特性说明

1. 双重安装范围 ：支持用户和机器范围安装
2. `PATH` 环境变量 ：自动将安装目录添加到系统 `PATH`
3. 升级保留 ：升级时保留原安装路径
4. 多架构支持 ：支持 `x86_64` 和 `ARM64` 架构
5. 系统兼容性 ：兼容 Windows 7/10/11

## Test Case

- 为当前用户安装 Nushell
- 为所有用户安装 Nushell

## REF

- https://docs.firegiant.com/quick-start/

I believe the issue will be resolved in the pull request at https://github.com/nushell/nushell/pull/15690. I've tested it using the command `msiexec /i nu-0.104.1-aarch64-pc-windows-msvc.msi MSIINSTALLPERUSER=1`, and it's working as expected.

Would you mind downloading the MSI from the **latest nightly build**: https://github.com/nushell/nightly/releases/tag/v0.104.1 and giving it a try? If you encounter any unexpected behavior, please let me know.
