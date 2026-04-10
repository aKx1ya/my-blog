---
title: "论文解读： OneTrans: Unified Feature Interaction and Sequence Modeling with
  One Transformer in Industrial Recommender"
date: 2026-04-10T14:58:00.000+08:00
categories:
  - 笔记
tags:
  - 论文
description: TAAC&KDD2026参考论文第二篇OneTrans
top: false
permalink: OneTrans/
published: true
series: "论文解读：HyFormer: Revisiting the Roles of Sequence Modeling and Feature
  Interaction in CTR Prediction"
---
解决的核心痛点是和HyFormer同样的，即“序列建模”和“特征交叉”的融合。
但是解法完全不同。

*HyFormer指出了OneTrans的局限性

OneTrans将静态特征和动态序列强行拼接成一条完整的序列，用一个纯粹的单项Transformer一步到位。有点“万物皆可Token”暴力解决的意思。

相比之下HyFormer则是采用了“交替”的架构，先用Query Decoding交叉注意力机制，让全局特征去阅读长序列提取信息，然后再用Query Boosting让这些特征互相进行交叉。然后再一层一层交替下去。

## 特征交叉的底层算子区别：
* **OneTrans** 完全依赖Transformer的Self-Attention自注意力机制来计算各种商品属性、用户画像之间的特征交叉。
* **HyFormer** 论文中说对于非序列特征的交叉，使用Self-Attention不仅AUC下降、计算效率也低。因此其使用了专门针对工业化优化的MLP-Mixer技术（类似RankMixer的技术）。

## 多序列的处理方式：
* **OneTrans** 面对用户不同行为序列的做法是插入[SEP]分隔符，强行吧不同语义序列连城一条超长线进行联合建模。
* **HyFormer** 批判了上面的这个做法（服了），认为强行合并不同序列的特征维度会抹杀不同序列的独特性，导致性能下降。HyFormer的做法是保持不同序列完全独立，为每个序列分配专属的全局Token分别读取，互不干扰。


官网说了Baseline模板是包含Transformer架构、RankMixer风格的分词和SwiGLU激活函数。基于此baseline和这个论文我们可以有以下一点思考：

### ① Mixed Parameterization混合参数化：
**输入层**
* 序列特征可以共享一套Q/K/V和FNN权重（同质化高的话）
* 而对于用户画像、当前上下文等静态特征则需要为每一个Token分配专属的参数（同质化低的话）

所以我们不能用一个简单的全连接层把所有的特征一视同仁地映射，我们需要修改输入层，让长序列特征共享投影矩阵，而静态属性则保留独立的特征变换矩阵，来提升AUC。
所以我们需要对多行为序列进行解耦处理，解耦方式参考HyFormer的全局Query。

### ② Pyramid Stack金字塔序列截断
**序列层**
模型越往深层走，需要的序列长度其实越短。OneTrans采用金字塔结构，在每一层逐步减少作为Query的序列Token数量，可以降低训练的内存开销。如果说正式的数据集中用户的行为序列极长，可以采用类似的机制再前两层完整捕捉，深层则捕捉20%的序列Query。省下来的内存用来开更大的Batch Size来跑并行或者增加深度之类的（尝试）
Batch Size太小会有问题的，这个用户误触广告也会被记录在序列里。

### ③ HyFormer - MLP-Mixer
HyFormer论文中已经证实了在特征深层交叉阶段英语基于MLP-Mixer的轻量级Token混合机制会更好。Baseline已经提供了类似Rankmixer的分词与交叉思路，我们就借鉴HyFormer的交叉架构，用Cross-Attention让目标广告去提取用户长序列中的兴趣，拿到结果后再到MLP-Mixer中与用户的静态画像去做深度交叉。
“提取-交叉-再提取-再交叉”循环堆叠，我觉得是一个不错的思路。

**特征稠密性和稀疏性要提前算一下，这样才知道哪里要限制Self-Attention**
