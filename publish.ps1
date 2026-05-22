<#
.SYNOPSIS
  一键将 .docx 笔记发布到 Hexo 博客
.DESCRIPTION
  把 Word 文档转为 HTML，添加 front matter，放入 source/_posts/，可选自动 git push
.PARAMETER DocxPath
  .docx 文件的路径（支持拖拽）
.PARAMETER AutoPush
  加上 -AutoPush 则在生成后自动 git commit & push
.EXAMPLE
  .\publish.ps1 "D:\笔记\因子研究.docx"
  .\publish.ps1 "D:\笔记\因子研究.docx" -AutoPush
#>

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$DocxPath,
    [switch]$AutoPush
)

$ErrorActionPreference = "Stop"

# ============ 1. 检查 pandoc ============
$pandoc = Get-Command pandoc -ErrorAction SilentlyContinue
if (-not $pandoc) {
    Write-Host "❌ 未找到 pandoc，请先安装：" -ForegroundColor Red
    Write-Host "   winget install --id JohnMacFarlane.Pandoc" -ForegroundColor Yellow
    exit 1
}

# ============ 2. 检查文件 ============
if (-not (Test-Path $DocxPath)) {
    Write-Host "❌ 文件不存在: $DocxPath" -ForegroundColor Red
    exit 1
}

$docxName = [System.IO.Path]::GetFileNameWithoutExtension($DocxPath)

# ============ 3. 收集元数据 ============
Write-Host "`n📄 文档: $docxName" -ForegroundColor Cyan
Write-Host "========================================`n"

$title = Read-Host "文章标题 (回车默认: $docxName)"
if ([string]::IsNullOrWhiteSpace($title)) { $title = $docxName }

$categoriesInput = Read-Host "分类，逗号分隔 (如: 笔记, 量化)"
$categories = if ($categoriesInput) { 
    ($categoriesInput -split ',' | ForEach-Object { "  - $_".Trim() }) -join "`n"
} else { "  - 笔记" }

$tagsInput = Read-Host "标签，逗号分隔 (如: 因子, Alpha)"
$tags = if ($tagsInput) {
    ($tagsInput -split ',' | ForEach-Object { "  - $_".Trim() }) -join "`n"
} else { "" }

$description = Read-Host "文章摘要 (可选)"

$permalink = Read-Host "自定义链接 (如 my-post/，回车自动生成)"
if ([string]::IsNullOrWhiteSpace($permalink)) {
    $permalink = ""
}

$today = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.000+08:00"
$dateSlug = Get-Date -Format "yyyy-MM-dd"

# 生成文件名
$fileName = "$dateSlug-$title.md"
$fileName = $fileName -replace '[\\/:*?"<>|]', '-'

$postDir = Join-Path $PSScriptRoot "source\_posts"
if (-not (Test-Path $postDir)) {
    New-Item -ItemType Directory -Path $postDir -Force | Out-Null
}

$outputPath = Join-Path $postDir $fileName

# ============ 4. pandoc 转换 ============
Write-Host "`n🔄 正在转换 .docx → HTML ..." -ForegroundColor Yellow
$htmlBody = & pandoc $DocxPath -f docx -t html --wrap=none 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ pandoc 转换失败: $htmlBody" -ForegroundColor Red
    exit 1
}

# ============ 5. 组装 Hexo 文章 ============
$permalinkLine = if ($permalink) { "permalink: $permalink/" } else { "" }
$tagsBlock = if ($tags) { "tags:`n$tags" } else { "tags:" }

$frontMatter = @"
---
title: $title
date: $today
categories:
$categories
$tagsBlock
description: $description
top: false
$permalinkLine
published: true
---
"@

$frontMatter = ($frontMatter -replace '\n{3,}', "`n`n").TrimEnd() + "`n`n"

$fullPost = $frontMatter + $htmlBody
$fullPost | Out-File -FilePath $outputPath -Encoding UTF8

Write-Host "✅ 文章已生成: $outputPath" -ForegroundColor Green

# ============ 6. 可选：自动 git push ============
if ($AutoPush) {
    Write-Host "`n🚀 正在提交到 GitHub ..." -ForegroundColor Yellow
    Set-Location $PSScriptRoot
    git add .
    git commit -m "新文章: $title"
    git push
    Write-Host "✅ 已推送！Vercel 将自动部署。" -ForegroundColor Green
} else {
    Write-Host "`n💡 提示: 运行以下命令发布到 Vercel:" -ForegroundColor Cyan
    Write-Host "   cd $PSScriptRoot" -ForegroundColor White
    Write-Host "   git add . && git commit -m '新文章: $title' && git push" -ForegroundColor White
}
