import pandas as pd

def load_data(path="data/paysim.csv", nrows=200000):
    df = pd.read_csv(path, nrows=nrows)
    return df

if __name__ == "__main__":
    print("Loading dataset...")
    df = load_data()

    print("\nDataset loaded successfully")
    print("\nShape of dataset:")
    print(df.shape)
    print("\nFirst 5 rows:")
    print(df.head())
    print("\nColumn names:")
    print(df.columns)
    print("\nData types:")
    print(df.dtypes)
    print("\nMissing values:")
    print(df.isnull().sum())
    print("\nFraud label distribution:")
    print(df["isFraud"].value_counts())
    print("\nFraud percentage:")
    print(df["isFraud"].value_counts(normalize=True))