---
title: 第一次Alpha挖掘记录：从TRAIN Sharpe 0.09到PASS
date: 2026-05-22T16:00:00.000+08:00
categories:
  - 笔记
tags:
  - Alpha
  - WorldQuant
  - 回测
description: 记录WorldQuant Brain平台第一次Alpha挖掘的完整迭代过程，从失败到PASS的七次修改。
top: false
permalink: my-first-alpha/
published: true
series: "Alpha因子挖掘学习笔记"
---
<p>记录第一次在 WorldQuant Brain 平台上从一个想法到最终 PASS 的完整迭代过程，一共经历了 <strong>7 次修改</strong>。</p>

<hr>

<h2>🚀 Baseline：第一次尝试</h2>

<p><strong>参数：</strong>Delay = 3，Truncation = 0.05</p>

{% hideToggle 📝 Baseline Alpha 表达式（点击展开） %}
<pre>positive_days = ts_sum(returns &gt; 0 ? 1 : 0, 250);
trade_when(volume &gt; adv20, positive_days, -1)</pre>
{% endhideToggle %}

<h3>结果：TRAIN 亮眼，TEST 崩盘</h3>

<table>
<tr><th>阶段</th><th>Sharpe</th><th>Fitness</th><th>收益率</th></tr>
<tr><td>TRAIN</td><td style="color:green"><strong>1.15</strong></td><td style="color:green"><strong>1.44</strong></td><td style="color:green"><strong>19.69%</strong></td></tr>
<tr><td>TEST</td><td style="color:red"><strong>0.09</strong></td><td style="color:red"><strong>0.03</strong></td><td style="color:red"><strong>1.15%</strong></td></tr>
</table>

{% hideToggle 🔍 故障分析（点击展开） %}
<ul>
  <li><strong>2020 年疫情影响</strong>：当年 Sharpe = -2.0，收益率 = -22%，Drawdown 极高</li>
  <li><strong>exit = -1（永不主动平仓）</strong>：2019 年满仓了涨最猛的股票，遇到 2020 年暴跌来不及跑，毫无止损逻辑</li>
</ul>
{% endhideToggle %}

<hr>

<h2>🛠 第一次修改：加 exit 条件</h2>

<p>先把 exit 设好。尝试对称条件 <code>volume &lt; adv20</code>——</p>

{% hideToggle ❌ 踩坑记录（点击展开） %}
<p>对称条件导致进场和离场频繁切换，Turnover 极高，Slip 吃掉 Fitness。❌</p>
<blockquote>exit 条件需要好好构思，不能简单对称。</blockquote>
{% endhideToggle %}

<hr>

<h2>🛠 第二次修改：exit = 跌破 20 日均线</h2>

<p><strong>Alpha 表达式：</strong></p>
{% hideToggle 📝 第二次修改（点击展开） %}
<pre>positive_days = ts_sum(returns &gt; 0 ? 1 : 0, 250);
trade_when(volume &gt; adv20, positive_days, close &lt; ts_mean(close, 20))</pre>
{% endhideToggle %}

<table>
<tr><th>阶段</th><th>Sharpe</th><th>Turnover</th><th>Fitness</th><th>Returns</th><th>Drawdown</th></tr>
<tr><td>TRAIN</td><td>1.25</td><td>42.35%</td><td>0.74</td><td>14.83%</td><td>32.06%</td></tr>
<tr><td>TEST</td><td style="color:green"><strong>1.83</strong></td><td>41.00%</td><td><strong>1.36</strong></td><td>22.70%</td><td>8.28%</td></tr>
<tr><td>IS</td><td>1.37</td><td>42.07%</td><td>0.86</td><td>16.42%</td><td>32.06%</td></tr>
</table>

<p>TEST 很好，但 IS 的 Fitness = 0.86 &lt; 1.0 ❌。Turnover 还是太高，需要平滑。</p>

<hr>

<h2>🛠 第三次修改：delay returns 避开反转噪音</h2>

<p><strong>Alpha 表达式：</strong></p>
{% hideToggle 📝 第三次修改（点击展开） %}
<pre>positive_days = ts_sum(ts_delay(returns, 10) &gt; 0 ? 1 : 0, 250);
trade_when(volume &gt; adv20, positive_days, close &lt; ts_mean(close, 20))</pre>
{% endhideToggle %}

<p><strong>结果：Fitness = 0.95</strong> ✅ 已经接近成功了！但 Turnover 仍约 41%。</p>

<blockquote>下一步：降低换手率，平滑 exit 条件。</blockquote>

<hr>

<h2>🛠 第四次修改：调整 exit 均线长度</h2>

<p>把 <code>close &lt; ts_mean(close, 20)</code> 的均线改长——</p>

<table>
<tr><th>均线天数</th><th>结果</th></tr>
<tr><td>50</td><td>Sub-universe Sharpe 差 0.01，可惜！</td></tr>
<tr><td>60</td><td>Sharpe 跌破 ❌</td></tr>
<tr><td>45</td><td>Fitness = 0.99 &lt; 1.0；Sub-universe Sharpe 0.52 &lt; 0.59 ❌</td></tr>
</table>

<p>50 天为最佳值，需要在其他地方补 Sub-universe Sharpe。</p>

<hr>

<h2>🛠 第五次修改：优化 Sub-universe Sharpe</h2>

<p>从 <strong>Truncation</strong> 下手——从 0.05 改为 <strong>0.1</strong>。让小票不再被过紧的权重上限束缚，略微加大最强信号的暴露。</p>

<p><strong>Sub-universe Sharpe 0.66 ✅ &gt; 0.65</strong></p>

<p>但新问题：<code>Weight concentration 10.03% is above cutoff of 10% on 3/16/2020</code></p>

{% hideToggle 🔍 为什么权重会超限？（点击展开） %}
<p>不是代码逻辑错了，而是<strong>组合构建过程中的微小数值误差</strong>——例如四舍五入或市场冲击导致的细微偏差。</p>
{% endhideToggle %}

<hr>

<h2>🏆 最终修改：微调 Truncation</h2>

<p>把 Truncation 从 0.1 改为 <strong>0.095</strong>——稍微取巧但有效的方法。</p>

<h3>🎉 PASS！</h3>

<p><strong>最终 Alpha 表达式：</strong></p>

{% hideToggle 📝 最终通过的 Alpha（点击展开） %}
<pre>positive_days = ts_sum(ts_delay(returns, 10) &gt; 0 ? 1 : 0, 250);
trade_when(volume &gt; adv20, positive_days, close &lt; ts_mean(close, 50))

decay = 3
Truncation = 0.095</pre>
{% endhideToggle %}

<hr>

<h2>📌 Truncation 经验总结</h2>

<table>
<tr><th>Truncation</th><th>效果</th></tr>
<tr><td><strong>0.5</strong></td><td>最高 50% 资金重仓一只股票，赚得快亏得快</td></tr>
<tr><td><strong>0.1</strong></td><td>持仓分散，风险和收益平滑</td></tr>
<tr><td><strong>0.01</strong></td><td>极度分散，几乎买下整个市场，因子质量被淹没</td></tr>
</table>

<hr>

<h2>💡 小结</h2>

<p>从一个不带止损的 Alpha（TEST Sharpe 0.09）起步，经过 <strong>7 轮迭代</strong>：</p>

<ol>
  <li>加 exit 条件 → 止损逻辑</li>
  <li>换 Turnover → 对称条件踩坑</li>
  <li>delay returns → 避开短期反转噪音</li>
  <li>调均线长度 → 找到 50 天最优</li>
  <li>调 Truncation → 补 Sub-universe Sharpe</li>
  <li>微调数值 → Weight 微量超限修复</li>
</ol>

<p>最终成功 PASS ✅。量化因子挖掘没有银弹，核心是<strong>理解每一个参数的实际含义 + 系统性地试错</strong>。</p>
