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
<h2>In-Sample Summary 样本内总结</h2>
<p>这是 WorldQuant Brain 的回测结果的一部分，其中包括 <strong>6 个指标</strong>：</p>

<ol>
  <li><strong>Sharpe 夏普比率</strong><br>
    衡量 Alpha 策略的超额回报（或风险溢价）与其波动性之间的比率。
    <ul>
      <li>Sharpe 越高，Alpha 策略潜在的回报越稳定。</li>
      <li>Brain 平台要求 Sharpe Ratio &gt; <strong>1.25</strong> 才能通过。</li>
      <li>delay 0 Alpha的Sharpe大于2.0，delay1 Alpha的Sharpe大于1.25</li>
    </ul>
  </li>
  <li><strong>Turnover 换手率</strong><br>
    衡量模拟每日交易活动的指标，即 Alpha 策略交易的频率。
    <ul>
      <li>Turnover 越高，交易次数越多，交易成本也越高。</li>
      <li>Brain 平台要求 Turnover 在 <strong>1% - 70%</strong> 之间才能通过。</li>
    </ul>
  </li>
  <li><strong>Fitness 稳健性分数</strong><br>
    综合分数，由 Return、Turnover、Sharpe 组成。
    <ul>
      <li>好的 Alpha 策略通常具有高的 Fitness。</li>
      <li>提升方法：增加 Sharpe（或收益），降低 Turnover。</li>
      <li>Brain 平台要求 Fitness &gt; <strong>1.0</strong>。</li>
    </ul>
  </li>
  <li><strong>Return 年化收益率</strong><br>
    赚的钱 / 投入资金，直观易懂。</li>
  <li><strong>Drawdown 回撤</strong><br>
    整个测试期间出现的最严重的一次下跌。</li>
  <li><strong>Margin 单位利润率</strong><br>
    Alpha 策略模拟计算出的每一美元交易额的利润。</li>
</ol>

<hr>

<h2>回测结果相关链接</h2>
<p><a href="https://support.worldquantbrain.com/hc/en-us/sections/20251188772119-IS-test-results" target="_blank">WorldQuant Brain - IS Test Results</a></p>
