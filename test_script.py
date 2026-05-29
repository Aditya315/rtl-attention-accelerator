#!/usr/bin/env python3

import numpy as np

INPUT_DIR = "./inputs"


def load_matrix(filename):
    path = f"{INPUT_DIR}/{filename}"
    return np.loadtxt(path)


def softmax(x):
    x = x - np.max(x, axis=1, keepdims=True)
    exp_x = np.exp(x)
    return exp_x / np.sum(exp_x, axis=1, keepdims=True)

# -------------------------------------------------
# Read Input Matrices
# -------------------------------------------------
XQ = load_matrix("XQ.txt")
WQ = load_matrix("WQ.txt")

XK = load_matrix("XK.txt")
WK = load_matrix("WK.txt")

XV = load_matrix("XV.txt")
WV = load_matrix("WV.txt")

# -------------------------------------------------
# Calculate Q, K, V
# -------------------------------------------------
Q = np.matmul(XQ, WQ)
K = np.matmul(XK, WK)
V = np.matmul(XV, WV)

# -------------------------------------------------
# Calculate S = QK^T / sqrt(dk)
# -------------------------------------------------
dk = K.shape[1]

S = np.matmul(Q, K.T) / np.sqrt(dk)

# -------------------------------------------------
# Attention(Q,K,V) = softmax(QK^T / sqrt(dk)) * V
# -------------------------------------------------
attention_score = softmax(S)

Attention = np.matmul(attention_score, V)

# -------------------------------------------------
# Store output
# -------------------------------------------------
with open("./output/attention_script.txt", "w") as f:
    for row in Attention:
        f.write(" ".join(f"{val:.6f}" for val in row))
        f.write("\n")



print("\nAttention(Q,K,V) =")
print(Attention)

print("\nStored output to ./output/attention_script.txt")