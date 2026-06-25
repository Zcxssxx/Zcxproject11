# MoonNinja 🥷🌙

![MoonBit Version](https://img.shields.io/badge/MoonBit-0.1.0-blue)
![License](https://img.shields.io/badge/license-Apache%202.0-green)

MoonNinja 是一款针对 MoonBit 与 WASM 生态的轻量级、超快速构建解决方案，语法上兼容标准的 `build.ninja` 文件。

## 🌟 核心特性 (Features)
- **极速解析**：纯 MoonBit 编写的无锁词法分析器与递归下降解析器。
- **精确增量**：支持基于文件 MTime 及内容哈希的 DAG 脏数据检测。
- **跨平台与零依赖**：得益于 MoonBit 的特性，MoonNinja 可以编译至 WASM 在任何平台执行，也可编译为 Native 机器码，无 Python 或 C++ 运行时依赖。

## 🏗 架构设计 (Architecture)
1. **Lexer & Parser**：使用有限状态机进行 Token 提取，支持 Ninja 的缩进与换行语义。
2. **DepGraph**：在内存中构建由 `BuildEdge` 组成的有向无环图 (DAG)，进行强连通分量 (SCC) 环路检测。
3. **Scheduler**：计算入度为 0 的任务，推入多核无锁队列并发执行。
4. **Executor**：通过 MoonBit FFI 调用系统 API 执行子进程。

## 🤝 贡献与大赛
本项目为 **2026 MoonBit 基础软件生态开源大赛** 的参赛作品。
欢迎提交 Issue 和 Pull Request！
