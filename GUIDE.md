# mqjtools 构建指南

这份文档记录本包的构建约定、技术步骤与踩过的坑。目标只有一个：**你只需要往 `R/` 里加函数，其余部分照着规矩走就不会坏。**

当前状态：`R CMD check` 通过（0 error / 0 warning / 0 note），17 个导出函数，2 个导出数据集，1 个内部查找表，6 个测试文件。

---

## 0. 心智模型

一个 R 包不是什么神秘容器，它就是**一个有强制文件约定的目录**：

| 文件/目录 | 是否必需 | 谁生成 | 作用 |
|---|---|---|---|
| `DESCRIPTION` | 必需 | 你 | 包的身份证：名字、版本、依赖、许可证 |
| `NAMESPACE` | 必需 | **roxygen2 生成** | 导出哪些函数、导入哪些外部函数 |
| `R/*.R` | 必需 | 你 | 所有代码 |
| `man/*.Rd` | 建议 | **roxygen2 生成** | 帮助页，F1 就是读它 |
| `data/*.rda` | 可选 | `data-raw/` 脚本 | 导出数据集（用户 `data()` 可见） |
| `R/sysdata.rda` | 可选 | `data-raw/` 脚本 | 内部数据（用户不可见） |
| `inst/extdata/` | 可选 | 你 | 原样随包分发的文件（csv/tsv/gmt） |
| `tests/` | 建议 | 你 | 单元测试 |
| `vignettes/` | 可选 | 你 | 长文教程（需要 pandoc） |

**两条铁律**：

1. `NAMESPACE` 和 `man/` **永远不要手改**。改 `R/` 里的 roxygen 注释，然后跑 `devtools::document()`。手改的内容下一次 `document()` 会被覆盖。
2. 装包时 `R/` 里所有文件会被**依次 source**，所以函数之间可以互相调用，**不需要** `source()`，也**不要**在包里写 `library()` 或 `setwd()`。

---

## 1. 从零到可安装：完整命令序列

只列一次，以后你只需重复第 5 步之后的循环。

```r
# 1 建骨架（本项目已建好，仅供参考）
usethis::create_package("E:/BaiduSyncdisk/01_R/11_Rpackages/mqjtools")

# 2 许可证
usethis::use_mit_license("QJ Meng")

# 3 git
usethis::use_git()
usethis::use_github(private = TRUE)   # 需先 gh::gh_token() 或 GITHUB_PAT

# 4 依赖声明（不要手改 DESCRIPTION 的 Imports/Suggests）
usethis::use_package("survival", "Suggests")
usethis::use_package("stats")          # base 包也要声明

# 5 日常循环 —— 这才是你 99% 的时间
usethis::use_r("my-new-function")      # 建 R/my-new-function.R
#   ...写函数 + roxygen 注释...
devtools::document()                   # 生成 man/ 与 NAMESPACE
devtools::load_all()                   # 等价 Ctrl+Shift+L，不装包直接加载
devtools::test()                       # 跑测试
devtools::check()                      # 提交前必跑
devtools::install()                    # 装进本机库，F1 才能稳定工作
```

RStudio 快捷键：`Ctrl+Shift+L` 加载、`Ctrl+Shift+D` 文档、`Ctrl+Shift+T` 测试、`Ctrl+Shift+E` 检查、`Ctrl+Shift+B` 构建。

---

## 2. DESCRIPTION 逐字段

```dcf
Package: mqjtools
Title: Personal Toolkit for Clinical and Bioinformatics Analysis
Version: 0.1.0
Authors@R:
    person(given = "QJ", family = "Meng",
           email = "you@example.com", role = c("aut", "cre"))
Description: A personal collection of helper functions for routine clinical
    data cleaning, regression reporting, figure styling, and lightweight
    access to large reference resources that are kept outside the package.
License: MIT + file LICENSE
Encoding: UTF-8
LazyData: true
Depends:
    R (>= 4.1.0)
Imports:
    stats,
    tools,
    utils
Suggests:
    openxlsx,
    readxl,
    survival,
    testthat (>= 3.0.0)
Config/testthat/edition: 3
Roxygen: list(markdown = TRUE)
```

要点与常见误填：

- **Package 名**：只能含字母、数字、点，必须以字母开头，不能有连字符和下划线。装包时它就是命名空间名，改名的代价极大（见第 10 节）。
- **Title**：Title Case，结尾不加句号，长度 ≤ 65 字符。
- **Description**：至少一句完整的话；续行**缩进 4 个空格**，否则 DCF 解析失败。
- **Authors@R**：必须是**可被 `parse()` 的 R 代码**。`role` 里必须有人是 `"cre"`，且 `cre` 必须有 `email`。`R CMD check` 会用子进程验证这一点。
- **License**：`MIT + file LICENSE`，同时 `LICENSE` 文件里写两行：
  ```
  YEAR: 2026
  COPYRIGHT HOLDER: QJ Meng
  ```
- **Imports vs Suggests**：函数里**必用**的包写 `Imports`（装包时强制安装）；只在部分功能里用、且已用 `requireNamespace()` 兜底的写 `Suggests`。本包的 `survival`/`readxl`/`openxlsx` 都在 `Suggests`，所以**裸 R 也能装上**——这对自用包很重要，换机器时不至于因为一个冷门依赖装不上而卡住。
- **Depends: R (>= 4.1.0)**：4.1 起有原生管道 `|>` 和 `\(x)` 简写，值得作为下限。
- **LazyData: true**：有 `data/` 就必须写，否则 `data()` 读不到、check 会 NOTE。
- **Roxygen: list(markdown = TRUE)**：允许在注释里用 markdown（`**粗体**`、`` `代码` ``、`[fmt_p()]` 自动变成帮助页链接）。这是让文档"好读"的关键开关。

---

## 3. 目录约定：新东西该放哪

| 你想放的东西 | 放这里 | 理由 |
|---|---|---|
| 一个工具函数 | `R/utils-*.R` | 按主题分文件，一个文件一类事 |
| 一个统计分析函数 | `R/stats-*.R` | 同上 |
| 只用一次的内部小函数 | 同文件的底部，`@noRd` | 不必单独成文 |
| 用户会 `data()` 查看的表 | `data/` + `data-raw/` 脚本 | 懒加载，`?数据集名` 有帮助页 |
| 函数内部用的常量/字典 | `R/sysdata.rda` | 不污染用户空间，不可被覆盖 |
| 原样分发的参考文件 | `inst/extdata/` | 用 `mqj_extdata()` 取路径 |
| 大数据库 | 远程 + `mqj_fetch()` 缓存 | 见第 5 节 |
| 探索性脚本 | **不要放包里** | 放项目目录，包只装"定型"的代码 |

`R/` 里的文件按**字母顺序**加载，所以**不要**依赖"文件 A 先于文件 B 执行"来定义对象。函数体在调用时才求值，通常没问题；但**顶层的 `<-` 赋值会在加载时立刻执行**，跨文件依赖会随机失败。需要共享常量就放 `R/sysdata.rda` 或写成函数。

---

## 4. 文档标准化：让 F1 真的能用

### 4.1 一个完整的 roxygen 块

```r
#' 一行标题（会变成帮助页标题）
#'
#' 详细描述。可以多段。可用 **markdown** 与 `代码`。
#'
#' @param x 数值向量。写清类型、是否可缺失、长度要求。
#' @param digits 保留小数位。
#'
#' @return 字符向量，长度与 `x` 相同；`NA` 输入返回 `NA_character_`。
#'
#' @family formatting helpers
#' @seealso [fmt_num()]
#'
#' @export
#' @examples
#' fmt_p(c(0.032, 1e-06))
fmt_p <- function(x, digits = 3) { ... }
```

### 4.2 标签速查

| 标签 | 何时用 | 备注 |
|---|---|---|
| 首行 `#'` | 必有 | 帮助页标题 |
| `@param` | 每个参数 | 一个 `@param` 可写多个参数名：`@param x,y` |
| `@return` | 每个导出函数 | 写清类型 + 特殊情况 |
| `@examples` | 每个导出函数 | **必须能离线跑通**，check 会执行 |
| `@export` | 给用户用 | 漏了就不会出现在 NAMESPACE |
| `@family xxx` | 一组相关函数 | 自动生成 "See also" 互链 |
| `@inheritParams` | 复用参数说明 | `@inheritParams fmt_p` |
| `@keywords internal` + `@noRd` | 内部函数 | 不生成帮助页，但仍有注释 |
| `@section 名称:` | 自定义小节 | 可写"设计取舍""注意事项" |
| `@source` | 数据集 | 写数据来源 |
| `@format` | 数据集 | 用 `\describe{}` 逐列说明 |
| `@importFrom pkg fn` | 需要导入时 | 集中写在 `*-package.R` 更清爽 |

### 4.3 F1 生效的三个前提

这是最常被误解的一点。F1 本质上等于执行 `?函数名`，它需要：

1. **`man/*.Rd` 存在** —— 跑过 `devtools::document()`；
2. **函数已 `@export`** —— `NAMESPACE` 里有它；
3. **包处于"已加载"状态** —— 要么 `library(mqjtools)`（需先 `devtools::install()`），要么用 `devtools::load_all()`。

实践建议：

- 开发期用 `load_all()`，F1 一般可用（RStudio 会接管帮助服务器）；
- **如果 F1 只弹出 "No documentation for 'xxx' in specified packages and libraries"，先 `devtools::install()` 再 `library()`，几乎必然解决**；
- 光标停在函数名上按 F1 才会跳转；停在变量名上不会。

### 4.4 帮助页里怎么写数学、列表、表格

markdown 模式下：

```r
#' @details
#' 计算方式：
#'
#' * 第一项
#' * 第二项
#'
#' 公式写作 `$HR = e^{\beta}$`，行间公式用 `$$...$$`。
```

### 4.5 三类文档警告与修法（本包真实踩过）

| 警告 | 原因 | 修法 |
|---|---|---|
| `Codoc mismatches ... Mismatches in argument default values` | 默认值里有非 ASCII 字符（如 `sep = "–"`），代码里是转义、Rd 里是字面字符，比对失败 | **默认值改 `NULL`，函数内部再解析**（本包 `fmt_est_ci(sep = NULL)` 就是这么改的） |
| `Undocumented arguments in Rd file` | 函数有某参数但 `@param` 没写 | 补 `@param`；多个参数共用一行时名字必须全部列出 |
| `Documented arguments not in \usage` | `@param` 写了不存在的参数（如把 `size` 写成 `sizes`） | 参数名逐字对齐 |

**通用原则**：`R/` 下的代码与注释**全用 ASCII**。中文写进 `README`、`GUIDE.md`、`vignettes`（这些不参与代码检查），代码里的破折号写 `"\u2013"`。否则 check 会报 `found non-ASCII strings`。

---

## 5. 数据封装：能不能把自己的数据库塞进包里

可以，但要选对容器。**四种方案，按体积和用途分工**。

### 5.1 四种容器

| 方案 | 位置 | 用户可见 | 加载时机 | 适用体积 | 典型用途 |
|---|---|---|---|---|---|
| 导出数据 | `data/*.rda` | `data()` 可见，有 `?名字` | **懒加载**（用到才读入） | < 1–2 MB | 示例数据、小型参考表 |
| 内部数据 | `R/sysdata.rda` | 不可见 | **随命名空间立刻加载** | < 1–2 MB | 常量、字典、阈值表 |
| 随包文件 | `inst/extdata/` | 通过 `system.file()` | **不加载**，用时才读 | < 5 MB | gmt、注释 tsv、模板 |
| 远程缓存 | 用户缓存目录 | 通过 `mqj_fetch()` | 用时才下载 | 不限 | 大型数据库、受许可限制的数据 |

**关键区别（很多人搞错）**：

- `data/` 是**懒加载**，`LazyData: true` 时只在第一次访问该对象时读入内存 → 适合"大一点的表"；
- `R/sysdata.rda` 是**饿加载**，`library(mqjtools)` 的瞬间整份进内存 → 只适合小常量。把 500 MB 字典放这里是灾难。

生成方式：

```r
# 导出数据（放 data/）
save(demo_clinical, file = "data/demo_clinical.rda", compress = "xz", version = 2)
# 或 usethis::use_data(demo_clinical, overwrite = TRUE)   # 内部会用 xz 压缩

# 内部数据（放 R/sysdata.rda）
save(lab_ref, file = "R/sysdata.rda", compress = "xz", version = 2)
# 或 usethis::use_data(lab_ref, internal = TRUE, overwrite = TRUE)
```

`version = 2` 是兼容性保险（R ≥ 3.5 都能读；`version = 3` 只有 R ≥ 3.5 能读，没必要冒险）。`compress = "xz"` 对这种表通常能把体积压到 1/5–1/10。压完可以用 `tools::checkRdaFiles("data")` 复查，它会告诉你哪些文件还能再压。

### 5.2 体积红线（针对 GitHub 分发）

| 阈值 | 后果 |
|---|---|
| 单文件 > 50 MB | GitHub 警告 |
| 单文件 > 100 MB | **GitHub 直接拒绝推送** |
| 仓库 > 1 GB | 克隆变慢，且历史无法瘦身 |
| 包源码 > 5 MB | CRAN 上限（你不上 CRAN，但这是"合理体积"的经验线） |

所以：**超过 5 MB 的东西不要进 `data/` 或 `inst/extdata/`**，走远程缓存。

### 5.3 远程缓存怎么用

本包已经把这层封好了：

```r
# 第一次：下载到缓存；之后：直接命中，不再联网
path <- mqj_fetch("https://example.org/msigdb/h.all.v2024.1.symbols.gmt",
                  md5 = "可选，校验失败会删文件报错")
gmt <- readLines(path)

mqj_cache_list()   # 看缓存里有什么、多大
mqj_cache_dir()    # 缓存目录的真实位置
```

缓存目录由 `tools::R_user_dir("mqjtools", "cache")` 决定，Windows 下大致是
`C:/Users/<你>/AppData/Local/R/cache/R/mqjtools`。**升级包不会清空它**，这是关键——否则每次 `install_github()` 都要重下几个 G。

更成熟的三条替代路线，按需升级：

- **`BiocFileCache`**：Bioconductor 官方缓存方案，支持资源 ID、过期、校验，功能最全；
- **`piggyback`**：把大文件挂到 **GitHub Releases** 而不是仓库里，`piggyback::pb_download()` 拉取。适合"想跟着包一起版本化"的数据；
- **`pins`**：通用制品仓库（本地/Posit Connect/S3 都行）。

### 5.4 三条红线

1. **许可证**。很多数据库不允许再分发副本：KEGG 明确禁止镜像，MSigDB 要求引用且部分集合受限，TCGA/GTEx 有受控访问层级。**判据很简单：如果官网有 "download" 页面且没有明确允许再分发，就走远程 + 首次下载，不要打包**。
2. **隐私**。临床原始数据、含 PHI 的表，**任何形式都不要进包**——包括"脱敏后"的，除非伦理批件明确覆盖。包一旦推到 GitHub，历史就很难彻底删除。
3. **可复现性**。远程数据必须**钉住版本**（URL 里带版本号 + `md5`）。否则半年后同一段代码跑出不同结果。

### 5.5 决策树

```
这份数据能否直接依赖一个现成的包？
├─ 能（org.Hs.eg.db / msigdbr / TFutils ...）→ 加进 Imports，别复制
└─ 不能
   ├─ 是不是患者/受控数据？ → 是 → 绝不入包
   └─ 否
      ├─ 体积 < 1 MB 且用户想看 → data/
      ├─ 体积 < 2 MB 且只是函数内部用 → R/sysdata.rda
      ├─ 体积 < 5 MB 且希望保持原格式（gmt/tsv）→ inst/extdata/
      └─ 超过以上 / 受许可限制 → 远程 + mqj_fetch() 缓存（钉版本 + md5）
```

### 5.6 针对"固定数据库"的实际建议

你反复用到的那几张表，按这个方式落地最省事：

1. **能用包解决的，一律用包**。基因注释用 `org.Hs.eg.db`/`AnnotationDbi`，通路用 `msigdbr`，别自己存一份——它们随版本更新，你自己存的那份半年后就过时了。
2. **自己整理的字典**（比如你常用的基因集、变量映射表、参考区间）放 `R/sysdata.rda`，几十 KB 而已，还能避免用户误改。
3. **大的表达矩阵 / 单细胞参考集**放远程，函数里用 `mqj_fetch()` 取，并在文档的 `@source` 里写清来源与版本。
4. **中间结果不要入包**。包是"代码 + 小常量"，不是数据仓库。

---

## 6. 测试

```r
usethis::use_test("fmt")     # 建 tests/testthat/test-fmt.R
```

规矩：

- 一个导出函数至少一个 `test_that()`；
- 测试**不联网**、**不写包目录**，临时文件一律 `tempfile()` + `on.exit(unlink(...))`；
- 依赖 `Suggests` 的测试开头写 `skip_if_not_installed("survival")`；
- 断言用 `expect_equal()`（精确）、`expect_match()`（正则）、`expect_error(..., "关键词")`（错误信息要匹配关键词，不要只写 `expect_error(x)`）。

跑：`devtools::test()`，或 `testthat::test_file("tests/testthat/test-fmt.R")` 单跑一个。

---

## 7. R CMD check：怎么读、怎么修

`devtools::check()` 会做：装包 → 跑所有 examples → 跑所有 tests → 检查文档完整性 → 检查命名空间。

**目标：0 error / 0 warning / 0 note。** 自用包不必强求 `--as-cran`，但 `devtools::check()` 默认会加 `--as-cran`，见 7.2。

### 7.1 高频问题速查

| 提示 | 含义 | 修法 |
|---|---|---|
| `no visible binding for global variable 'x'` | 在 `dplyr`/`data.table` 里用了裸列名 | `@importFrom rlang .data` 后写 `.data$x`，或 `utils::globalVariables("x")` |
| `found non-ASCII strings` | 代码/注释里有中文或 `–` | 换 `\u2013`，中文挪出 `R/` |
| `Undocumented arguments` | 缺 `@param` | 补 |
| `object 'foo' is not exported` | 忘了 `@export` | 补 + `document()` |
| `Namespace in Imports field not imported from` | `Imports` 里声明了但代码里没用到 | 删掉，或改用 `pkg::fun()` |
| `Examples with CPU time > 5s` | 例子太慢 | 包进 `\donttest{}`（仍会被 `--as-cran` 跑）或 `\dontrun{}`（完全不跑） |
| `S3 method not registered` | 写了 `print.myclass` 但没注册 | `@exportS3Method print.myclass` 或 `NAMESPACE` 里 `S3method()` |
| `LazyData specified but no data directory` | 反过来的情形 | 删 `LazyData` 或补 `data/` |

### 7.2 本机真实踩到的坑：locale 导致的假 ERROR

现象：`R CMD check` 在 "checking DESCRIPTION meta-information" 处直接 ERROR 并中止，日志里只有：

```
During startup - Warning messages:
1: Setting LC_COLLATE=C.UTF-8 failed
...
 ERROR
```

原因不在包。R 的 check 会用**子进程**跑
`tools:::.check_package_description("DESCRIPTION", TRUE)`，并把子进程的任何输出当成"问题"。而本机环境变量 `LC_ALL=C.UTF-8` 在 Windows 上不存在，R 每次启动都打印 4 条 locale 警告 → 被 check 误判为 ERROR 并 `do_exit(1)`。

修法（任选）：

```bash
# Git Bash / 终端里临时覆盖
LC_ALL=C LANG=C "C:/Program Files/R/R-4.5.3/bin/R.exe" CMD check mqjtools_0.1.0.tar.gz --no-manual

# 或者在 R 里先清掉，再调用 devtools
Sys.unsetenv("LC_ALL"); devtools::check()
```

**结论**：看到"莫名其妙的启动警告 + ERROR"，先怀疑环境变量，别改代码。用 `LC_ALL=C` 重跑一次就能确认。

### 7.3 手动跑（比 devtools 更透明）

```bash
cd E:/BaiduSyncdisk/01_R/11_Rpackages
"$R" CMD build mqjtools --no-build-vignettes --no-manual
"$R" CMD check mqjtools_0.1.0.tar.gz --no-manual
```

好处：日志完整留在 `mqjtools.Rcheck/00check.log`，出问题能逐行看。`--no-manual` 跳过 PDF 手册（没装 LaTeX 时必需）。

---

## 8. 发布到 GitHub

### 8.1 一次性配置

```r
usethis::use_git()                      # git init + 首次提交
usethis::use_github(private = TRUE)     # 建远端并 push
```

**推之前检查两件事**：

1. `DESCRIPTION` 里的 `URL:` 和 `BugReports:` 换成真实地址（现在是 `<your-account>` 占位符）。`--as-cran` 会检查它们，填错是 NOTE。
2. `.gitignore` 里**不要**忽略 `*.Rproj`，否则换机的你打开时没有项目文件。本项目已把 `*.Rproj` 从忽略列表移除，`mqjtools.Rproj` 会正常入库。

### 8.2 安装

```r
# 公开仓库
devtools::install_github("your-account/mqjtools")

# 私有仓库：需要一个有 repo 权限的 PAT
usethis::create_github_token()          # 浏览器里生成，复制
gitcreds::gitcreds_set()                # 粘进去，存到系统凭据
devtools::install_github("your-account/mqjtools")   # 自动复用凭据
```

私有库最常见的坑：`install_github()` 报 404。几乎总是 **token 没设**或**没有该仓库权限**，而不是仓库不存在。

### 8.3 自动化检查

`.github/workflows/R-CMD-check.yaml` 已就位：每次 push 在 Windows + Ubuntu 上各跑一遍 check，`error-on: warning`——有 warning 就红灯。这样你换机器后"我这能跑"的侥幸会被提前打掉。

---

## 9. 版本号与变更记录

语义化版本 `MAJOR.MINOR.PATCH`：

- `PATCH`（0.1.0 → 0.1.1）：改 bug、改文档、加函数参数默认值；
- `MINOR`（0.1 → 0.2）：加新函数、加新数据；
- `MAJOR`（0.x → 1.0）：**改已有函数的参数或返回值**（会破坏旧脚本）。

每次改版本号，同步在 `NEWS.md` 加一段：

```md
# mqjtools 0.2.0

## Added
* `fmt_ratio()` for ratio measures.

## Changed
* `describe_by_group()` now returns percentages with fixed decimals.
```

改了已有函数的行为却不改版本号，三个月后的你会恨现在的你。

---

## 10. 反模式清单

| # | 别这么干 | 后果 / 正确做法 |
|---|---|---|
| 1 | 手改 `NAMESPACE`、`man/` | 下次 `document()` 全被覆盖 |
| 2 | 函数里写 `library(dplyr)` | 污染用户环境；用 `dplyr::filter()` 或在包级 `@importFrom` |
| 3 | 函数里写 `setwd()` | 改变用户工作目录，且不可预测；用参数传路径 |
| 4 | 用 `T`/`F` 当 TRUE/FALSE | 可被用户变量覆盖 |
| 5 | `1:length(x)` | `x` 为空时得到 `1:0` 的诡异序列；用 `seq_along(x)` |
| 6 | `sapply()` 返回值类型不定 | 用 `vapply(x, fun, numeric(1))` |
| 7 | 在 `R/` 里写中文注释 | check 报 non-ASCII；中文放 `GUIDE.md` |
| 8 | 顶层写 `x <- read.csv("data.csv")` | 装包时就执行，路径必然不存在；要读数据就写进函数体 |
| 9 | 例子联网 / 写用户目录 | check 会失败或在别人机器上失败；用 `tempfile()` 或 `\dontrun{}` |
| 10 | 一个函数干五件事 | 拆开；包的价值就在于可复用的小积木 |
| 11 | 参数名用 `data` 又同时 `library(data)` | 遮蔽；本包用 `data` 作形参但从不 attach 同名包，安全 |
| 12 | 返回 `invisible()` 的东西却文档写"返回路径" | 文档与实现不符；要么别 invisible，要么文档写清 |
| 13 | 把 500 MB 字典塞 `sysdata.rda` | 每次 `library()` 都吃内存；走远程缓存 |
| 14 | 患者数据进 `data/` | 不可撤销的隐私事故 |
| 15 | 改函数行为不升版本 | 旧脚本静默出错 |
| 16 | 提交 `*.tar.gz`、`.Rcheck/` | 仓库膨胀；已在 `.gitignore` 里 |
| 17 | 依赖不写进 DESCRIPTION 直接用 `::` | check 报 "unstated dependencies" |
| 18 | 用 `stop("错了")` 不给上下文 | 用 `stop("Column not found: ", nm, call. = FALSE)`，`call. = FALSE` 去掉无用调用栈 |
| 19 | 一个 `utils.R` 塞 3000 行 | 按主题分文件，文件名即目录 |
| 20 | 改包名 | 需同步改 `DESCRIPTION`、`*-package.R` 的 `"_PACKAGE"` 文档、`mqj_extdata()` 里的 `package =`、测试、`.Rproj` 名；代价极高，**起名时想清楚** |

---

## 11. 可选增强（按需再上）

| 需求 | 做法 | 代价 |
|---|---|---|
| 网站在线文档 | `usethis::use_pkgdown()` + `pkgdown::build_site()`，推 `gh-pages` | 需 pkgdown |
| 长文教程 | `usethis::use_vignette("intro")` | **需 pandoc**（RStudio 自带，命令行没有） |
| 代码风格统一 | `styler::style_pkg()` | 会改动所有文件，建议一开始就上 |
| 静态检查 | `lintr::lint_package()` | 噪音较多，选规则 |
| 提交前自动检查 | `precommit` 包 | 需 Python |
| 依赖版本锁定 | `renv::init()` | 适合"三年后还能复现"，自用包可选 |

---

## 12. 你现在该做的三件事

1. 把 `DESCRIPTION` 里的 `email`、`URL`、`BugReports` 换成真实信息；
2. `usethis::use_git()` 之后 `usethis::use_github(private = TRUE)`；
3. 从 `R/utils-format.R` 挑一个函数照抄结构，写你第一个真正要用的函数——然后 `document()` → `load_all()` → F1 验证。

剩下的事，都是重复第 3 步。
