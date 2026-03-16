import pandas as pd

df = pd.read_csv("data/paysim.csv", nrows=200000)

print("Dataset loaded successfully")
print(df.head())
print(df.shape)