# MoonNinja 🥷🌙

[![MoonBit Version](https://img.shields.io/badge/MoonBit-0.1.0-blue)](https://www.moonbitlang.cn/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](LICENSE)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)]()

**MoonNinja** 是一款采用 MoonBit 语言纯原生编写的**超快速构建系统**，高度兼容谷歌 `build.ninja` 规范。得益于 MoonBit 语言的轻量级与多后端编译优势，MoonNinja 实现了**跨平台、零依赖**，不仅能在 Native 环境下通过子进程并发构建，更能在沙盒化 WASM 浏览器中执行高效的虚拟构建任务。

---

## 🌟 核心特性 (Features)

- ⚡ **纯原生解析**：纯 MoonBit 编写的无锁状态机词法分析器 (Lexer) 与递归下降解析器 (Parser)，具有极高的文本吞吐量。
- 🕸 **精确依赖图**：在内存中构建由输入/输出文件作为顶点的**有向无环图 (DAG)**，支持深度优先搜索 (DFS) 和拓扑排序，能够完美进行循环依赖检测。
- 🧩 **多后端适配 (Target Gating)**：
  - **Native 后端**：通过 C 语言 FFI 桥接原生系统调用，并发拉起子进程执行真正的编译器任务。
  - **WASM 后端**：为 WASM/JS 平台提供轻量级的 Mock 虚拟化构建执行器，在无操作系统调用权限的浏览器沙箱中也能演示完整的构建链路。
- 🔄 **Ninja 变量插值**：支持构建规则中 `$in` (输入文件) 与 `$out` (输出文件) 的动态模板插值。

---

## 🏗 架构设计 (Architecture)

```
        +----------------------------------------+
        |             build.ninja                |
        +-------------------+--------------------+
                            | Lexical Scan
                            v
        +-------------------+--------------------+
        |            Lexer & Parser              |
        +-------------------+--------------------+
                            | AST Manifest
                            v
        +-------------------+--------------------+
        |               DepGraph                 | (DAG Topological Sort)
        +-------------------+--------------------+
                            | Sorted BuildEdges
                            v
        +-------------------+--------------------+
        |         Scheduler & Executor           | (Native C FFI / WASM Sandbox)
        +-------------------+--------------------+
```

1. **Parser & Lexer**：处理 Ninja 文本结构，识别 `rule`（命令模板）与 `build`（具体构建边缘），解析依赖关系。
2. **DepGraph**：整理生成构建任务关系网，自动找出各个构建目标的依赖关系，并生成无环拓扑排序队列。
3. **Scheduler**：负责按照拓扑排序，驱动 Executor 顺序地或并发地执行规则命令。
4. **Executor**：通过 Native 端的系统调用或 WASM 虚拟化环境执行生成出的 shell 命令。

---

## 🚀 快速上手 (Quick Start)

### 编译与测试
```powershell
# 1. 检查语法与类型约束
moon check

# 2. 运行自动化单元测试
moon test

# 3. 运行本地命令行 Demo 示例
moon run src/main
```

### 编写 Ninja 文件进行构建解析
```moonbit
fn main {
  // 定义 Ninja 构建任务脚本
  let ninja_input =
    #|rule cc
    #|  command = echo Compile $in to $out
    #|build main.o: cc main.c
    #|

  let parser = @src.Parser::new(ninja_input)
  try {
    let manifest = parser.parse()
    println("Manifest parsed successfully.")
    
    // 构建 DAG 图
    let graph = @src.DepGraph::build(manifest)
    let executor = @src.LocalExecutor::{}
    let scheduler = @src.Scheduler::{ graph, executor }
    
    // 运行拓扑排序构建目标 "main.o"
    match scheduler.run_all("main.o") {
      Ok(_) => println("Build successful!")
      Err(e) => println("Build failed: " + e)
    }
  } catch {
    @src.ParseError::SyntaxError(msg, line~, col~) => println("Syntax error: " + msg + " at " + line.to_string() + ":" + col.to_string())
    @src.ParseError::UnexpectedToken(tok, expected~) => println("Unexpected token: \{tok}, expected: \{expected}")
  }
}
```

---

## 📂 项目结构 (Directory Structure)

```
moon_ninja/
├── .github/                # GitHub CI/CD Actions 工作流
├── LICENSE                 # Apache 2.0 开源证书
├── README.md               # 本项目技术说明文档
├── moon.mod.json           # 模块配置信息
└── src/
    ├── manifest.mbt        # AST Manifest 节点定义
    ├── token.mbt           # 词法 Token 定义及 Show 接口实现
    ├── error.mbt           # 解析器语法异常定义
    ├── lexer.mbt           # 状态机词法分析器 (Lexer)
    ├── parser.mbt          # 递归下降语法解析器 (Parser)
    ├── graph.mbt           # 拓扑排序及有环依赖检测器 (DAG)
    ├── executor.mbt        # 任务执行器抽象 (Executor Trait)
    ├── local_executor.mbt  # 环境变量插值及执行适配
    ├── scheduler.mbt       # 任务调度引擎 (Scheduler)
    ├── ffi_native.mbt      # [native 独占] FFI 真实系统执行适配
    ├── ffi_wasm.mbt        # [wasm/js 独占] 虚拟化沙箱执行器
    ├── moon.pkg.json       # 包配置及多后端 Target Gating 网闸配置
    ├── parser_test.mbt     # 完整词法、语法与依赖排序测试集
    └── main/
        ├── main.mbt        # 编译后 CLI 执行入口
        └── moon.pkg.json   # 入口包设置
```

---

## 🤝 参与贡献
本项目是 **2026 MoonBit 基础软件生态开源大赛** 的参赛作品。
欢迎随时提交 Issue 与 Pull Request 帮助我们完善它！
