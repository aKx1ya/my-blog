---
title: Introduction to Alphas
date: 2026-03-28T19:40:00.000+08:00
categories:
  - 笔记
tags:
  - Alpha
description: 介绍Alphas，以及其在Brain平台上的意义。
top: false
permalink: alpha/
published: true
---
**Alpha** 是一种具体的交易想法，可以在历史上进行回测。\
在 **WorldQuant 的 Brain 平台**中，Alpha 指一个数学模型或策略，以表达式的形式书写，对不同的股票进行不同的权重投注，并计算长期盈利。\
Alpha 表达式由 **数据、运算符和常数**组成。

- - -

## Alpha 的 Lifecycle

### ① idea → expression

* 通过浏览互联网上的博客、期刊和研究论文中获取 idea。  
* 将这个 idea 转换为可计算的公式或表达式 expression。

### ② raw data → operations

* 使用市场数据（价格、成交量、财务指标等）通过数学运算、统计方法或逻辑组合，把数据加工成信号。  
* 对原始 Alpha 进行截断（truncation）、中性化、衰减（decay）等操作。

### ③ position → stats

* 在 Setting 页面选择股票池、做空/做多等设置。  
* Brain 平台会根据 Alpha 表达式生成的信号决定买入/卖出仓位。

### ④ PNL → Analyze

* 平台会回测观察这个 Alpha 带来的盈亏情况，计算绩效（夏普、换手率、收益率）。  
* 分析它在不同市场环境下的稳定性和有效性。

### ⑤ Performance

* 分析绩效指标如 IR、Sharpe、TVR，判断 Alpha 的好坏。  
* 根据结果修正或淘汰 Alpha。

- - -

## 权重

在 Brain 平台中，Alpha 会被用来生成一个 **权重向量**。  

* 向量里的每一个元素对应股票池中的一只股票。  
* 权重大小表示该股票在 portfolio 中的仓位比例。  
* 回测期间，每一天都会根据权重向量生成一个新的 portfolio，并计算 PnL 来评估 Alpha 的表现。

### 中性化 Neutralization

中性化的目的：**消除整体因素影响，保留个股差异**，避免 Alpha 只是跟随大盘或行业走势。

* **市场中性化**：去除市场整体涨跌的影响。  
* **行业中性化**：去除行业整体趋势的影响。  
* **子行业中性化**：更细颗粒度，例如“半导体”子行业。  
* **不做中性化**：Alpha 信号混合了市场趋势 + 行业趋势 + 个股差异。

- - -

## Alpha 如何在回测中被转换为 Portfolio 权重

假设我们输入：

**`1/close`**

* 意思是用股票收盘价的倒数作为信号，收盘价越低，值越大。  
* 在 Setting 中选择 **TOP3000（美股市值前3000）**作为股票池。  
* 回测期的每一天，系统都会对这 3000 支股票计算 `1/close`，得到一个包含 3000 个数值的向量。  
* 接下来进行 **归一化处理 normalization**：每一个值除以向量中所有值的总和，使所有权重加起来为 1。  
* 得到的“权重向量”表示每只股票的资金比例。  
* 系统根据 portfolio 的权重和股票涨跌，计算当天整体盈亏。

⚠️ 注意：  

* 权重可以为负数。  
* **正权重** → 股票多头仓位。  
* **负权重** → 股票空头仓位。
