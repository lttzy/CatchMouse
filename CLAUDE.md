# CLAUDE.md

这个文件为 Claude Code (claude.ai/code) 在此仓库工作时提供指导。

## 项目构建命令

这是一个使用 Rojo 进行同步的 Roblox 项目。开发时使用以下命令：

- **同步到 Studio**: `rojo serve` (然后从 Roblox Studio 连接)
- **构建项目**: `rojo build default.project.json -o CatchMouse.rbxl`
- **Lua 代码检查**: `selene src/` (需要 Selene 代码检查器)

工具由 Aftman 管理。运行 `aftman install` 安装所有必需的工具。

## 架构概览

这是一个 Roblox 躲猫猫游戏，采用复杂的模块化架构和服务定位器模式。代码库遵循面向对象设计，从基类继承（服务器端使用 BaseManager，客户端使用 BaseController）。

### 核心架构模式

**服务器端架构（ManagerService 模式）**：
- `ManagerService` (ServerStorage/ManagerService.lua): 服务器端管理器的中央服务定位器
- `BaseManager` (ReplicatedStorage.Source.CommonFunctions.BaseManager): 具有生命周期管理的基类 (Initialize → Start → Stop → Destroy)
- 管理器按优先级注册并按顺序初始化
- 主游戏逻辑在 `GameService.server.lua` 中，协调所有管理器

**客户端架构（ControllerService 模式）**：
- `ControllerService` (ReplicatedStorage.Source.ControllerService): 客户端控制器的中央服务定位器
- `BaseController` (ReplicatedStorage.Source.CommonFunctions.BaseController): 具有生命周期和更新循环的基类
- 控制器处理 UI、输入、渲染和客户端游戏逻辑
- 主入口点是 `ClientMain.client.lua` (StarterPlayerScripts)

**通信系统**：
- `Communication` 模块提供统一的远程事件/函数处理
- 支持可靠和不可靠（高频）的网络通信
- 管理器和控制器都使用它进行服务器-客户端通信

### 躲猫猫游戏结构

**游戏流程**：
1. `GameManager` (ServerStorage/HideAndSeek/GameManager.lua) - 主游戏状态机
2. 状态流转：等待中(Waiting) → 开始中(Starting) → 准备中(Preparing) → 进行中(InProgress) → 结束中(Ending)
3. 队伍分配、出生点管理、胜利条件检查
4. 由 `GameConfig` (ReplicatedStorage.Source.HideAndSeek.Config.GameConfig) 驱动配置

**核心管理器**：
- `GameManager`: 核心游戏逻辑、状态管理、队伍分配
- `PlayerDataManager`: 玩家进度和数据持久化
- `CharacterManager`: 角色能力和变身
- `ItemManager`: 游戏内道具生成和交互
- `SkillManager`: 玩家技能和冷却时间

**关键数据文件**：
- `GameConfig.lua`: 全面的游戏设置（计时器、队伍、经济、地图）
- `HideAndSeekCharacters.lua`: 角色定义和能力
- `HideAndSeekItems.lua`: 道具类型和属性

### 重要工具模块

**通用系统** (在 ReplicatedStorage.Source.CommonFunctions 中)：
- `Signal`: 自定义事件系统
- `Maid`: 内存管理和清理
- `Zone`: 3D 区域检测和监控
- `Communication`: 远程事件/函数包装器
- `Promise`: 异步操作处理
- `TableUtil`: 表操作工具

**UI 系统** (ReplicatedStorage.Source.MyUIManager)：
- 基于模板的 UI 创建和管理
- 动画效果系统
- 与控制器架构集成

## 开发指南

**创建新管理器时**：
1. 继承 `BaseManager` 类
2. 使用适当的优先级注册到 `ManagerService`
3. 实现生命周期方法：`OnInitialize()`、`OnStart()`、`OnDestroy()`
4. 使用 `Maid` 清理连接和对象

**创建新控制器时**：
1. 继承 `BaseController` 类
2. 使用适当的优先级注册到 `ControllerService`
3. 使用 `OnUpdate()`、`OnRender()` 或 `OnPhysics()` 进行帧更新
4. 使用通信方法与服务器交互

**文件组织结构**：
- 仅服务器代码：`src/ServerScriptService/` 和 `src/ServerStorage/`
- 仅客户端代码：`src/StarterPlayerScripts/`
- 共享代码：`src/ReplicatedStorage/`
- 游戏特定代码组织在 `HideAndSeek/` 文件夹下

**通信模式**：
- 使用 `Communication.FireServer()` / `Communication.OnServerEvent()` 处理事件
- 使用 `Communication.InvokeServer()` / `Communication.OnServerInvoke()` 处理请求-响应
- 对高频更新（玩家移动）使用不可靠变体
- 服务器方法通过 `ManagerService` 快速访问方法公开

**测试与调试**：
- 在 Studio 中可通过聊天或热键（F1-F3）使用调试命令
- 在管理器/控制器上使用 `SetDebug(true)` 启用详细日志
- 使用 `PrintStatus()` 方法调试服务状态