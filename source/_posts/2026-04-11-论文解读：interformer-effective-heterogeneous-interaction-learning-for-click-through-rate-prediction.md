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
# InterFormer: Effective Heterogeneous Interaction Learning for Click-Through Rate Prediction

解决推荐系统中“动态行为”与“静态画像”的融合。
这论文是Meta基于在真实广告系统中的700亿级样本和长度1000的序列里跑出的真实数据。证实了InterFormer很好用。

---

## 核心架构拆解

### 1. Interaction Arch（特征交叉网络）
* **目标**：静态画像学习“感知行为”的非序列特征。
* **机制**：它不光计算用户画像、商品属性之间的交叉，还会把**序列摘要（Sequence Summarization）**也拉进来一起做特征交叉。这就好比，不仅看这个用户平时喜欢什么，还结合他刚刚疯狂点击了什么，来动态调整对他的画像认知。

### 2. Sequence Arch（序列建模网络）
* **目标**：学习“感知上下文”的序列特征。
* **机制**：它使用了个性化前馈网络（PFFN）和多头注意力（MHA）。在处理用户的行为序列之前，它会先把**非序列摘要（Non-sequence Summarization）**当作一个 CLS Token 塞到序列的最前面，作为 Query 去引导整条序列的注意力分配。

### 3. Cross Arch（信息桥）
* **目标**：在不破坏原始高维信息的前提下，进行有效的信息筛选和浓缩。
* **机制**：如果把原始的特征矩阵直接互相扔给对方，算力根本吃不消，而且噪音极大。因此，Cross Arch使用**自门控（Self-gating）**技术把非序列特征进行脱水提纯（过滤无效废话，提纯高密度向量）。同时，它使用 CLS Token、PMA Token 以及 recent 来精准概括序列信息。提纯后的双边信息再跨界交换，既保留了各自的完整度，又实现了高效沟通。

---

## 关键名词解释

* **序列摘要 Sequence Summarization**：过滤误触
* **非序列摘要 Non-sequence Summarization**：高度概括标签
* **CLS Token（Classification）**：直接把非序列摘要当作 CLS Token 插在用户序列的最前面，以此来帮助过滤。
* **PMA Token（Pooling by Multi-Head Attention）**：和 CLS 不一样，不依赖静态画像，在训练过程中自己随机初始化并自学习出几个独立的 Learnable Queries（无偏见万能探针），纯粹从序列出发。

---

## 实战启发与应用策略

① **精细化提炼序列**：用户行为序列如果很长，我们就尽量不要 Average Pooling 把序列拍扁，而是借鉴一下 InterFormer 用 CLS + PMA + Recent 结合一下来提炼序列。

② **利用 PFFN 解决特征早衰**：利用 PFFN 个性化前馈网络解决特征早衰问题。序列送入 Transformer 提取特征之前，先用一个线性层把用户静态特征映射成一个权重矩阵，然后再把它乘到序列特征上。论文中的机制。

③ **降低显存换取大 Batch Size**：用自控门 Self-Gating 机制降低显存，换取大的 batch size。把非序列特征送去和序列特征交互之前，先过一个 self-gating 先，提纯后再跑相关交互。省下来的内存去开 batch size，可以多睡一会。

④ **交替式学习 (Interleaving learning style)**：不要把序列建模和特征交叉做成上下级的流水线结构，而是做成交替式的 block。重构的思路要想好，block1 做什么 block2 做什么。（1是静态特征去序列里搜信息，然后过一遍 rankmixer，上一步更新后的静态特征再去拿深层信息，再过一遍 rankmixer）这种迭代的结构很好，meta证明过了我们无脑用就好了。看来字节也是抄袭的。
