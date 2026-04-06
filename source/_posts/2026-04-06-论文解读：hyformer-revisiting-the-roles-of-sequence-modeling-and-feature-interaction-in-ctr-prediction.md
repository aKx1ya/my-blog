---
title: "论文解读：HyFormer: Revisiting the Roles of Sequence Modeling and Feature
  Interaction in CTR Prediction"
date: 2026-04-06T22:38:00.000+08:00
categories:
  - 笔记
tags:
  - 论文
description: TAAC&KDD2026参考论文第一篇解读。
top: false
permalink: HyFormer/
published: true
---
# HyFormer: Revisiting the Roles of Sequence Modeling and Feature Interaction in CTR Prediction
> 《重新审视序列建模与特征交互在点击率预测中的作用》

本文提出了 **HyFormer** 统一混合 Transformer 架构，用以融合以下两个核心步骤：
- **序列建模 (Sequence Modeling)**：用于处理用户历史行为。
- **特征交叉 (Feature Interaction)**：用于处理用户画像、上下文等非序列特征。

HyFormer 是由多个 HyFormer Layer 堆叠而成，每一个 Layer 包含两个关键模块：
1. **查询解码 (Query Decoding)**
2. **查询增强 (Query Boosting)**

---

## 核心步骤解析

### 第一步：查询生成 (Query Generation)
首先，模型会对输入进行分词 (Tokenization)。将用户的静态属性、上下文等“非序列特征 (NS Tokens)”以及全局序列汇总信息，通过一个轻量级的全连接层 (MLP)，转化为一组 **全局 Token (Global Tokens)**，作为后续的 Query。

* **MLP 全连接层**：输入拼接好的非序列特征（用户的静态属性）以及从用户行为序列中提取的“全局序列汇总信息”，输出全局 Token。
* **Global Tokens**：即序列查询 (Sequence Queries)，融合了用户全局画像，是用来去长序列中精准提取历史行为的 **“超级探针”**！

### 第二步：查询解码 (Query Decoding) —— 提取序列信息
对于超长的用户行为序列，模型支持采用标准 Transformer、LONGER 或极简的 SwiGLU 进行编码，生成每一层的 Key 和 Value (即 KV 编码)。

接着用第一步中生成的全局上下文探针 Query，去和长序列的 KV 对进行多头交叉注意力计算 (Cross-Attention)：

$Q_{decoded} = \text{CrossAttn}(Q, K, V)$

探针会把关键历史信号吸收进自己的向量中（根据搜索到的信息迭代更新自己的全局 Token）。

> **💡 关于多头交叉注意力计算：**
> - **交叉注意力**：在查询解码 Decoding 模块中，模型拿上面做好的全局 Query 作为查询词，去 KV 对进行注意力分数计算。相当于让全局特征直接去关注长序列里的每一个历史行为，看看哪个历史行为对当前的全局特征最有价值，从而注入并更新 Query。
> - **多头**：注意力计算是分成多个平行的“头”同时进行的。

这一步就是让全局的上下文信息带着“目的”去长序列里反照有用的历史行为，实现了**全局信息 (Global Context) 对序列信息的介入**。

### 第三步：查询增强 (Query Boosting) —— 深度特征交叉
融合序列信息和非序列特征。对刚刚解码得到的 Query 和非序列 Tokens 进行 **Token-mixing (跨 Token 混合)**。

这是让各个维度的特征在内部进行充分的“交流讨论”，从而丰富 Query 的语义表示。增强后的 Query 会被送入下一层，带着更丰富的知识去继续提取长序列。

### 第四步：多序列建模 (Multi-Sequence Modeling)
现实中用户有不同类型的序列（比如“看过的视频”和“买过的商品”）。HyFormer 的做法是：
1. 为每一个独立的序列分配**专属的 Query Tokens**，各自独立进行 Query Decoding。
2. 它们互不干扰，各自在各自的特征空间里进行交叉注意力计算。
3. 这既保留了序列的独特性，又能在随后的 Query Boosting 模块里，通过 Token-mixing 实现跨序列的全局融合。

### 第五步：系统层面的工程优化
* **长序列 GPU 池化 (GPU Pooling)**：解决数据搬运的瓶颈。由于长序列里存在大量重复的 ID，模型会在底层去重后压缩传输，大幅降低了数据在 GPU 和 CPU 之间的传输成本和内存占用。HyFormer 底层做了一个“去重压缩包”，在数据传进 GPU 之前建立一个去重后的压缩特征表；数据传到 GPU 后，再通过一个高性能前向算子，在 GPU 内部解压并重构出原始的长序列。
* **异步 AllReduce**：解决多卡通信等候瓶颈。在分布式训练时，让前向/反向传播和梯度同步异步进行，消除了通信气泡，极大提升了 GPU 利用率。

---

## 与 TAAC 的联系及应用建议

1. **构建共享语义接口**：可以参考论文，利用全局 Token 作为共享语义接口的思路来构建模型。
2. **构建 Tokenizer**：借鉴 HyFormer 的语义分组策略来构建 Tokenizer，按内在含义（用户、上下文、行为）对输入特征进行分区整合。
3. **稀疏维度拼接**：处理长序列时，参考 HyFormer 将各种辅助信息（时间戳、行为类型等）拼接到序列的稀疏维度 (Sparse Dim) 中。
4. **控制推理时延 (Latency)**：比赛不仅看重 AUC，还设置了严格的推理时延限制。HyFormer 在取得最高 AUC (0.6489) 时，计算开销 FLOPs 仅为 3.9T。可以借鉴 HyFormer 中灵活的**序列表示编码 (Sequence Representation Encoding) 替换策略**：
    * 算力充足时：使用 Full Transformer。
    * 需要平衡时：使用类似 LONGER 机制。
    * 严重超时时：使用 SwiGLU 激活层进行无注意力映射。
5. **丰富序列特征输入**：在 HyFormer 这种双向流动（信息在序列建模和特征交叉来回穿梭）的架构下，序列输入特征越丰富，模型获得的 AUC 收益比传统模型越大。

---

### 🚀 实战核心指南 (Baseline 改造策略)
**不要急着推翻 Baseline**（因为其已包含 SwiGLU 和 RankMixer 等前沿技术）。

建议以现有的 Baseline 为底座，把 HyFormer 论文中**“引入 Global Tokens 交替进行 Decoding 和 Boosting”**以及**“多序列独立建模”**的局部代码编辑一下，改写并融合进去。
