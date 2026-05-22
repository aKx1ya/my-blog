---
title: "论文解读：InterFormer: Effective Heterogeneous Interaction Learning for
  Click-Through Rate Prediction"
date: 2026-04-11T15:30:00.000+08:00
categories:
  - 笔记
tags:
  - 论文
description: TAAC&KDD2026参考论文第三篇
top: false
permalink: InterFormer/
published: true
series: "论文解读：HyFormer: Revisiting the Roles of Sequence Modeling and Feature
  Interaction in CTR Prediction"
---
<h1>InterFormer: Effective Heterogeneous Interaction Learning for Click-Through Rate Prediction</h1>

<p>解决推荐系统中"动态行为"与"静态画像"的融合。<br>
这论文是Meta基于在真实广告系统中的7000亿级样本和长度1000的序列里跑出的真实数据。证实了InterFormer很好用。</p>

{% mermaid %}
flowchart TB
  subgraph Static["🧩 静态特征端"]
    UP["用户画像"]
    CI["上下文信息"]
    IA["商品属性"]
  end

  subgraph Sequence["📜 序列特征端"]
    UB["用户行为序列<br/>点击/购买/浏览"]
  end

  subgraph Cross["🌉 Cross Arch 信息桥"]
    SG["Self-Gating 自门控<br/>脱水提纯非序列特征"]
    CLS["CLS Token"]
    PMA["PMA Token<br/>可学习探针"]
    RC["Recent 近期行为"]
    direction LR
    SG --> CLS
    SG --> PMA
    SG --> RC
  end

  subgraph Inter["🤝 Interaction Arch<br/>特征交叉网络"]
    SS["Sequence Summarization<br/>序列摘要"]
    FI["Feature Interaction<br/>特征交叉"]
  end

  subgraph SeqArch["🧠 Sequence Arch<br/>序列建模网络"]
    PFFN["PFFN 个性化前馈网络"]
    MHA["MHA 多头注意力"]
  end

  UP --> SG
  CI --> SG
  IA --> SG
  UB --> PFFN
  PFFN --> MHA
  CLS --> MHA
  PMA --> MHA
  RC --> MHA
  MHA -->|"感知上下文的序列特征"| SS
  SG -->|"提纯后的静态特征"| FI
  SS --> FI
  FI --> PRED["🎯 CTR 预测"]

  style Cross fill:#fff3e0,stroke:#f57c00
  style Inter fill:#e1f5fe,stroke:#0288d1
  style SeqArch fill:#e8f5e9,stroke:#388e3c
{% endmermaid %}

<hr>

<h2>核心架构拆解</h2>

<h3>1. Interaction Arch（特征交叉网络）</h3>
<ul>
  <li><strong>目标</strong>：静态画像学习"感知行为"的非序列特征。</li>
  <li><strong>机制</strong>：它不光计算用户画像、商品属性之间的交叉，还会把<strong>序列摘要（Sequence Summarization）</strong>也拉进来一起做特征交叉。这就好比，不仅看这个用户平时喜欢什么，还结合他刚刚疯狂点击了什么，来动态调整对他的画像认知。</li>
</ul>

<h3>2. Sequence Arch（序列建模网络）</h3>
<ul>
  <li><strong>目标</strong>：学习"感知上下文"的序列特征。</li>
  <li><strong>机制</strong>：它使用了个性化前馈网络（PFFN）和多头注意力（MHA）。在处理用户的行为序列之前，它会先把<strong>非序列摘要（Non-sequence Summarization）</strong>当作一个 CLS Token 塞到序列的最前面，作为 Query 去引导整条序列的注意力分配。</li>
</ul>

<h3>3. Cross Arch（信息桥）</h3>
<ul>
  <li><strong>目标</strong>：在不破坏原始高维信息的前提下，进行有效的信息筛选和浓缩。</li>
  <li><strong>机制</strong>：如果把原始的特征矩阵直接互相扔给对方，算力根本吃不消，而且噪音极大。因此，Cross Arch使用<strong>自门控（Self-gating）</strong>技术把非序列特征进行脱水提纯（过滤无效废话，提纯高密度向量）。同时，它使用 CLS Token、PMA Token 以及 recent 来精准概括序列信息。提纯后的双边信息再跨界交换，既保留了各自的完整度，又实现了高效沟通。</li>
</ul>

<hr>

{% hideToggle 📖 关键名词解释（点击展开） %}
<h2>关键名词解释</h2>

<ul>
  <li><strong>序列摘要 Sequence Summarization</strong>：过滤误触</li>
  <li><strong>非序列摘要 Non-sequence Summarization</strong>：高度概括标签</li>
  <li><strong>CLS Token（Classification）</strong>：直接把非序列摘要当作 CLS Token 插在用户序列的最前面，以此来帮助过滤。</li>
  <li><strong>PMA Token（Pooling by Multi-Head Attention）</strong>：和 CLS 不一样，不依赖静态画像，在训练过程中自己随机初始化并自学习出几个独立的 Learnable Queries（无偏见万能探针），纯粹从序列出发。</li>
</ul>
{% endhideToggle %}

<hr>

{% hideToggle 🎯 实战启发与应用策略（点击展开） %}
<h2>实战启发与应用策略</h2>

<p>① <strong>精细化提炼序列</strong>：用户行为序列如果很长，我们就尽量不要 Average Pooling 把序列拍扁，而是借鉴一下 InterFormer 用 CLS + PMA + Recent 结合一下来提炼序列。</p>

<p>② <strong>利用 PFFN 解决特征早衰</strong>：利用 PFFN 个性化前馈网络解决特征早衰问题。序列送入 Transformer 提取特征之前，先用一个线性层把用户静态特征映射成一个权重矩阵，然后再把它乘到序列特征上。论文中的机制。</p>

<p>③ <strong>降低显存换取大 Batch Size</strong>：用自控门 Self-Gating 机制降低显存，换取大的 batch size。把非序列特征送去和序列特征交互之前，先过一个 self-gating 先，提纯后再跑相关交互。省下来的内存去开 batch size，可以多睡一会。</p>

<p>④ <strong>交替式学习 (Interleaving learning style)</strong>：不要把序列建模和特征交叉做成上下级的流水线结构，而是做成交替式的 block。重构的思路要想好，block1 做什么 block2 做什么。（1是静态特征去序列里搜信息，然后过一遍 rankmixer，上一步更新后的静态特征再去拿深层信息，再过一遍 rankmixer）这种迭代的结构很好，meta证明过了我们无脑用就好了。看来字节也是抄袭的。</p>
{% endhideToggle %}
