---
title: IS Summary 回测结果
date: 2026-03-28T21:07:00.000+08:00
categories:
  - 笔记
tags:
  - 回测
description: WorldQuant Brain平台的回测result中主要内容是IS Summary
top: false
permalink: issummary/
published: true
---
## In-Sample Summary 样本内总结
这是 WorldQuant Brain 的回测结果的一部分，其中包括 **6 个指标**：

1. **Sharpe 夏普比率**  
   衡量 Alpha 策略的超额回报（或风险溢价）与其波动性之间的比率。  
   - Sharpe 越高，Alpha 策略潜在的回报越稳定。  
   - Brain 平台要求 Sharpe Ratio > **1.25** 才能通过。

2. **Turnover 换手率**  
   衡量模拟每日交易活动的指标，即 Alpha 策略交易的频率。  
   - Turnover 越高，交易次数越多，交易成本也越高。  
   - Brain 平台要求 Turnover 在 **1% - 70%** 之间才能通过。

3. **Fitness 稳健性分数**  
   综合分数，由 Return、Turnover、Sharpe 组成。  
   - 好的 Alpha 策略通常具有高的 Fitness。  
   - 提升方法：增加 Sharpe（或收益），降低 Turnover。  
   - Brain 平台要求 Fitness > **1.0**。

4. **Return 年化收益率**  
   赚的钱 / 投入资金，直观易懂。

5. **Drawdown 回撤**  
   整个测试期间出现的最严重的一次下跌。

6. **Margin 单位利润率**  
   Alpha 策略模拟计算出的每一美元交易额的利润。

---

## 回测结果相关链接
[WorldQuant Brain - IS Test Results](https://support.worldquantbrain.com/hc/en-us/sections/20251188772119-IS-test-results)
