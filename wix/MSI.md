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

## User-Facing Changes

- Nushell should be possible to be installed via winget with both user and machine scope and The default should be user scope
  - User scope install by winget: `winget install Nushell.Nushell`
  - User scope install by msiexec: `msiexec /i nu-0.104.1-x86_64-pc-windows-msvc.msi /quiet /qn`
  - Machine scope install by winget: `winget install Nushell.Nushell --override 'ALLUSERS=1'`
  - Machine scope install by msiexec: `msiexec /i nu-0.104.1-x86_64-pc-windows-msvc.msi ALLUSERS=1`
  - Note that `--scope` flag for `winget install` does not work use `--override` instead
  - Default user scope install dir: `$'($nu.home-path)\AppData\Local\Programs\nu\'`
  - Default machine scope install dir: `C:\Program Files\nu\`
- When a standard user runs the installer and selects "Install for everyone" (per-machine installation), Windows will automatically trigger a UAC prompt, the user can enter admin credentials and the installation will proceed with elevated privileges

## Test Case

- 为当前用户安装 Nushell：
  - 检查默认安装路径是否正确
  - 检查静默安装: `msiexec /i $pkg MSIINSTALLPERUSER=1 /quiet /qn` 是否正常
  - 检查静默安装: `winget install --manifest manifests\n\Nushell\Nushell\0.104.1 --scope user` 是否正常
  - 安装过程中是否不会出现 UAC prompt
  - 检查安装完成后环境变量是否正确添加
  - 检查注册表变量是否正确设置
  - 检查 Window Terminal 配置文件是否添加
  - 如果没有选择 Window Terminal 配置 Feature 则不会被安装
  - 如果是升级安装是否保持原来的安装路径
  - 卸载 Nushell 并检查文件/环境变量/注册表/Windows Terminal 配置文件是否被清理掉

- 为所有用户安装 Nushell
  - 如果是普通用户安装过程中是否会出现 UAC prompt
  - 检查默认安装路径是否正确
  - 检查静默安装: `winget install --manifest manifests\n\Nushell\Nushell\0.104.1 --scope machine` 是否正常
  - 检查是否允许用户选择自定义安装路径
  - 选择自定义安装路径是否能成功安装
  - 如果是升级安装是否保持原来的安装路径
  - 检查安装完成后环境变量是否正确添加
  - 检查注册表变量是否正确设置
  - 检查 Window Terminal 配置文件是否添加
  - 如果没有选择 Window Terminal 配置 Feature 则不会被安装
  - 卸载 Nushell 并检查文件/环境变量/注册表/Windows Terminal 配置文件是否被清理掉

## 当前已知问题

- [x] 卸载的时候环境变量没有被清理掉;
- 支持通过 INSTALLDIR 属性指定安装路径
- `winget install --scope machine` 不支持
- [x] `winget install --override 'ALLUSERS=1'` 可以正常在全局范围安装应用
- [x] `msiexec /i $pkg MSIINSTALLPERUSER=1 /quiet /qn` 静默安装路径异常
- [x] 为所有用户安装的时候没有正确安装 WindowsTerminalProfileFeature
- [x] 为所有用户安装的时候默认安装路径是 C:\Program Files (x86)\nu 而不是 C:\Program Files\nu;
- [x] 安装 Scope 选择切换到为所有用户安装时默认选中的路径是 C:\Program Files (x86)\nu 而不是 C:\Program Files\nu;

## REF

- https://docs.firegiant.com/quick-start/
- https://docs.firegiant.com/wix/schema/wxs/package/
- https://learn.microsoft.com/en-ca/windows/win32/msi/formatted
- https://learn.microsoft.com/en-us/windows/win32/msi/single-package-authoring
- https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/msiexec
