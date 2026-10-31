# MoonCue: CSV 公式风险检查原型

MoonCue 是用 MoonBit 编写的 CSV 检查库。它检查单元格是否以电子表格公式相关的字符开头，并输出逻辑行号、列号和原因，不执行公式，也不输出单元格内容。Node.js 命令行适配层从标准输入读取文件，不修改源文件。

## 快速使用

需要 MoonBit 和 Node.js；以下命令从项目根目录执行：

```powershell
moon test --target wasm-gc
moon test --target js
moon run cmd/main --target wasm-gc
moon build --target js
node tests/cli.cjs
Get-Content -Raw -Encoding utf8 sample.csv | node _build/js/debug/build/cmd/scan/scan.js
```

Node 标准输入必须是 UTF-8；保留原始字节时，可用 Node 子进程读取文件并送入标准输入。示例：

```powershell
node -e "const c=require('child_process').spawnSync('node',['_build/js/debug/build/cmd/scan/scan.js'],{input:require('fs').readFileSync('sample.csv'),stdio:['pipe','inherit','inherit']}); process.exit(c.status ?? 2)"
```

结果示例（位置从 1 开始，包括标题行）：

```text
row 3, column 2: formula marker, possibly after spaces
Review 1 flagged cell(s); this is not a guarantee of safety.
```

返回码：0 表示本规则未发现可疑单元格；1 表示有需复核的单元格；2 表示输入、UTF-8、语法或限制错误。

## 检查范围和限制

- 仅支持逗号分隔 CSV，处理双引号包围字段、双引号转义、CRLF/LF/CR、字段内换行及开头的 BOM。格式不完整或引号后追加字符会报错；不猜测错误文件的结构。
- 标记开头是 `=`、`+`、`-`、`@` 的值，以及前导空格后的这些字符；也标记开头或前导空格后出现的制表符、回车或换行。负数等正常数据可能触发提示，须人工判断。
- 检查并不覆盖所有表格程序、区域设置、编码、分隔符和公式注入技巧，也不对文件进行修复或消毒。未提示不代表安全；在可信的导出端和导入端仍需使用相应防护。
- 默认最多处理 100 万 Unicode 字符、10 万行、每行 1000 列、每格 10 万字符；Node 入口先限制输入不超过 400 万字节。适合有界文件，不是流式大文件扫描器。
- 数据在本地进程内处理，源码不包含网络传输。不要在公开 Issue、日志或演示中粘贴私密 CSV 内容。

## 库接口

`scan_csv(input, limits~)` 返回 `Result[Array[Finding], CsvError]`。可使用 `Limits::default()` 或显式设置限制。`cell_reason` 可单独用于已解析的单元格。行号是逻辑记录号；包含换行的带引号字段仍属于同一记录。

## 使用 AI 与许可

项目于北京时间 2026 年 10 月 31 日赛事报名之前开始开发，由 Codex 辅助编写；是否符合比赛工作量及资格由主办方判断。参赛者需理解并复核功能、测试、许可及参赛诚信要求。源码按 Apache-2.0 授权，详见 LICENSE。
