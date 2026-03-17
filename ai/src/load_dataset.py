import warnings
from pathlib import Path
from typing import Optional, Tuple

import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split


warnings.filterwarnings("ignore", category=FutureWarning)

# -------------------------------------------------------------------
# Configuration
# -------------------------------------------------------------------
REQUIRED_COLUMNS = [
    "step",
    "type",
    "amount",
    "nameOrig",
    "oldbalanceOrg",
    "newbalanceOrig",
    "nameDest",
    "oldbalanceDest",
    "newbalanceDest",
    "isFraud",
    "isFlaggedFraud",
]

NUMERIC_BASE_COLUMNS = [
    "step",
    "amount",
    "oldbalanceOrg",
    "newbalanceOrig",
    "oldbalanceDest",
    "newbalanceDest",
    "isFlaggedFraud",
]

CATEGORICAL_COLUMNS = ["type"]

DEFAULT_DATA_PATH = "data/paysim.csv"
DEFAULT_NROWS = 200000
DEFAULT_TEST_SIZE = 0.2
DEFAULT_RANDOM_STATE = 42


# -------------------------------------------------------------------
# Core data loading
# -------------------------------------------------------------------
def load_data(path: str = DEFAULT_DATA_PATH, nrows: Optional[int] = DEFAULT_NROWS) -> pd.DataFrame:
    """
    Load PaySim dataset and validate required columns.

    Args:
        path: Path to CSV file.
        nrows: Number of rows to load. Use None to load all rows.

    Returns:
        DataFrame containing raw dataset.
    """
    csv_path = Path(path)
    if not csv_path.exists():
        raise FileNotFoundError(f"Dataset file not found: {csv_path}")

    df = pd.read_csv(csv_path, nrows=nrows)

    missing_cols = [col for col in REQUIRED_COLUMNS if col not in df.columns]
    if missing_cols:
        raise ValueError(f"Missing required columns: {missing_cols}")

    return df


# -------------------------------------------------------------------
# Cleaning
# -------------------------------------------------------------------
def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Clean raw PaySim dataset.

    Steps:
    - remove exact duplicates
    - standardize transaction type
    - coerce numeric columns
    - fill missing values safely
    - clip negative balances to zero (defensive cleaning)
    """
    df = df.copy()

    initial_rows = len(df)
    df = df.drop_duplicates()
    removed_duplicates = initial_rows - len(df)

    if removed_duplicates > 0:
        print(f"Removed duplicate rows: {removed_duplicates}")

    # Standardize transaction type
    df["type"] = (
        df["type"]
        .astype(str)
        .str.strip()
        .str.upper()
        .replace({"NAN": "UNKNOWN"})
    )

    # Coerce numeric columns
    numeric_cols = [
        "step",
        "amount",
        "oldbalanceOrg",
        "newbalanceOrig",
        "oldbalanceDest",
        "newbalanceDest",
        "isFraud",
        "isFlaggedFraud",
    ]

    for col in numeric_cols:
        df[col] = pd.to_numeric(df[col], errors="coerce")

    # Fill missing values
    df[numeric_cols] = df[numeric_cols].fillna(0)
    df["type"] = df["type"].fillna("UNKNOWN")

    # Defensive cleanup for impossible negatives in balances / amounts
    balance_cols = [
        "amount",
        "oldbalanceOrg",
        "newbalanceOrig",
        "oldbalanceDest",
        "newbalanceDest",
    ]
    for col in balance_cols:
        df[col] = df[col].clip(lower=0)

    # Force fraud labels to integer 0/1
    df["isFraud"] = df["isFraud"].astype(int)
    df["isFlaggedFraud"] = df["isFlaggedFraud"].astype(int)

    return df


# -------------------------------------------------------------------
# Feature engineering
# -------------------------------------------------------------------
def add_behavioral_features(df: pd.DataFrame) -> pd.DataFrame:
    """
    Create fraud-relevant behavioral features.

    Feature themes:
    - balance consistency
    - suspicious zero-balance behavior
    - amount ratios
    - temporal behavior proxies
    - transaction structure / account flow signals
    """
    df = df.copy()
    eps = 1e-6

    # ---------------------------------------------------------------
    # Balance movement features
    # ---------------------------------------------------------------
    df["org_balance_change"] = df["oldbalanceOrg"] - df["newbalanceOrig"]
    df["dest_balance_change"] = df["newbalanceDest"] - df["oldbalanceDest"]

    df["org_amount_diff"] = df["org_balance_change"] - df["amount"]
    df["dest_amount_diff"] = df["dest_balance_change"] - df["amount"]

    df["abs_org_amount_diff"] = df["org_amount_diff"].abs()
    df["abs_dest_amount_diff"] = df["dest_amount_diff"].abs()

    # ---------------------------------------------------------------
    # Ratio features
    # ---------------------------------------------------------------
    df["amount_to_oldbalanceOrg_ratio"] = df["amount"] / (df["oldbalanceOrg"] + eps)
    df["amount_to_oldbalanceDest_ratio"] = df["amount"] / (df["oldbalanceDest"] + eps)
    df["newbalanceOrig_to_oldbalanceOrg_ratio"] = df["newbalanceOrig"] / (df["oldbalanceOrg"] + eps)
    df["newbalanceDest_to_oldbalanceDest_ratio"] = df["newbalanceDest"] / (df["oldbalanceDest"] + eps)

    df["org_balance_change_ratio"] = df["org_balance_change"] / (df["oldbalanceOrg"] + eps)
    df["dest_balance_change_ratio"] = df["dest_balance_change"] / (df["oldbalanceDest"] + eps)

    # ---------------------------------------------------------------
    # Zero-balance and sparsity signals
    # ---------------------------------------------------------------
    df["is_zero_oldbalanceOrg"] = (df["oldbalanceOrg"] == 0).astype(int)
    df["is_zero_newbalanceOrig"] = (df["newbalanceOrig"] == 0).astype(int)
    df["is_zero_oldbalanceDest"] = (df["oldbalanceDest"] == 0).astype(int)
    df["is_zero_newbalanceDest"] = (df["newbalanceDest"] == 0).astype(int)

    df["both_orig_balances_zero"] = (
        (df["oldbalanceOrg"] == 0) & (df["newbalanceOrig"] == 0)
    ).astype(int)
    df["both_dest_balances_zero"] = (
        (df["oldbalanceDest"] == 0) & (df["newbalanceDest"] == 0)
    ).astype(int)

    # ---------------------------------------------------------------
    # Suspicious transaction consistency checks
    # ---------------------------------------------------------------
    df["is_full_balance_drain"] = (
        (df["oldbalanceOrg"] > 0) & (df["newbalanceOrig"] == 0)
    ).astype(int)

    df["amount_exceeds_oldbalanceOrg"] = (
        df["amount"] > df["oldbalanceOrg"]
    ).astype(int)

    df["amount_exceeds_oldbalanceDest"] = (
        df["amount"] > df["oldbalanceDest"]
    ).astype(int)

    df["balance_change_mismatch"] = (
        (df["abs_org_amount_diff"] > 1) | (df["abs_dest_amount_diff"] > 1)
    ).astype(int)

    # ---------------------------------------------------------------
    # Time-based proxy features
    # Note: PaySim step is hour-like progression
    # ---------------------------------------------------------------
    df["hour_of_day"] = df["step"] % 24
    df["day_index"] = df["step"] // 24
    df["is_night_transaction"] = df["hour_of_day"].isin([23, 0, 1, 2, 3, 4, 5]).astype(int)
    df["is_business_hours"] = df["hour_of_day"].between(9, 18).astype(int)
    df["is_week_boundary_proxy"] = ((df["day_index"] % 7).isin([5, 6])).astype(int)

    # ---------------------------------------------------------------
    # Amount scale features
    # ---------------------------------------------------------------
    df["log_amount"] = np.log1p(df["amount"])

    median_amount = df["amount"].median()
    p90_amount = df["amount"].quantile(0.90)
    p99_amount = df["amount"].quantile(0.99)

    df["is_large_transaction"] = (df["amount"] > median_amount).astype(int)
    df["is_very_large_transaction"] = (df["amount"] > p90_amount).astype(int)
    df["is_extreme_transaction"] = (df["amount"] > p99_amount).astype(int)

    # ---------------------------------------------------------------
    # Account-type proxy from IDs
    # In PaySim, destination often starts with M or C
    # We do not keep raw identifiers, only derived proxy patterns
    # ---------------------------------------------------------------
    df["dest_is_merchant"] = df["nameDest"].astype(str).str.startswith("M").astype(int)
    df["dest_is_customer"] = df["nameDest"].astype(str).str.startswith("C").astype(int)
    df["orig_is_customer"] = df["nameOrig"].astype(str).str.startswith("C").astype(int)

    return df


# -------------------------------------------------------------------
# Encoding
# -------------------------------------------------------------------
def encode_transaction_type(df: pd.DataFrame) -> pd.DataFrame:
    """
    One-hot encode transaction type using numeric 0/1 output.
    """
    df = df.copy()
    df = pd.get_dummies(
        df,
        columns=["type"],
        prefix="type",
        drop_first=False,
        dtype=int,
    )
    return df


# -------------------------------------------------------------------
# Full preprocessing
# -------------------------------------------------------------------
def preprocess_data(
    df: pd.DataFrame,
    drop_identifiers: bool = True,
) -> pd.DataFrame:
    """
    Full preprocessing pipeline.

    Steps:
    - clean raw data
    - feature engineering
    - encode categorical variables
    - optionally drop raw identifiers after deriving useful proxy features
    """
    df = clean_data(df)
    df = add_behavioral_features(df)
    df = encode_transaction_type(df)

    if drop_identifiers:
        cols_to_drop = [col for col in ["nameOrig", "nameDest"] if col in df.columns]
        if cols_to_drop:
            df = df.drop(columns=cols_to_drop)

    # Final defensive check: convert booleans to integers if any remain
    bool_cols = df.select_dtypes(include=["bool"]).columns.tolist()
    if bool_cols:
        df[bool_cols] = df[bool_cols].astype(int)

    return df


# -------------------------------------------------------------------
# Feature / target utilities
# -------------------------------------------------------------------
def get_feature_target_split(
    df: pd.DataFrame,
    target_col: str = "isFraud",
    drop_leakage_cols: bool = True,
) -> Tuple[pd.DataFrame, pd.Series]:
    """
    Split processed dataframe into X and y.

    Args:
        df: Preprocessed dataframe.
        target_col: Target column.
        drop_leakage_cols: Drop columns not intended for model training.

    Returns:
        X, y
    """
    if target_col not in df.columns:
        raise ValueError(f"Target column '{target_col}' not found.")

    cols_to_drop = [target_col]

    # This column is a labeled rule-style flag in dataset and can create unfair leakage
    if drop_leakage_cols and "isFlaggedFraud" in df.columns:
        cols_to_drop.append("isFlaggedFraud")

    X = df.drop(columns=cols_to_drop)
    y = df[target_col].astype(int)

    return X, y


def get_train_test_data(
    path: str = DEFAULT_DATA_PATH,
    nrows: Optional[int] = DEFAULT_NROWS,
    test_size: float = DEFAULT_TEST_SIZE,
    random_state: int = DEFAULT_RANDOM_STATE,
    stratify: bool = True,
    drop_leakage_cols: bool = True,
):
    """
    End-to-end helper:
    load -> preprocess -> split
    """
    raw_df = load_data(path=path, nrows=nrows)
    processed_df = preprocess_data(raw_df)
    X, y = get_feature_target_split(
        processed_df,
        target_col="isFraud",
        drop_leakage_cols=drop_leakage_cols,
    )

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=test_size,
        random_state=random_state,
        stratify=y if stratify else None,
    )

    return X_train, X_test, y_train, y_test


# -------------------------------------------------------------------
# Reporting
# -------------------------------------------------------------------
def basic_data_report(df: pd.DataFrame) -> None:
    """
    Print summary report for raw or processed dataframe.
    """
    print("Dataset loaded successfully")

    print("\nShape of dataset:")
    print(df.shape)

    print("\nFirst 5 rows:")
    print(df.head())

    print("\nColumn names:")
    print(df.columns.tolist())

    print("\nData types:")
    print(df.dtypes)

    print("\nMissing values:")
    print(df.isnull().sum())

    if "isFraud" in df.columns:
        print("\nFraud label distribution:")
        print(df["isFraud"].value_counts())

        print("\nFraud percentage:")
        print(df["isFraud"].value_counts(normalize=True))

    if "type" in df.columns:
        print("\nTransaction type distribution:")
        print(df["type"].value_counts())

    numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
    if numeric_cols:
        print("\nBasic numeric summary:")
        print(df[numeric_cols].describe().T)


def preprocessing_report(raw_df: pd.DataFrame, processed_df: pd.DataFrame) -> None:
    """
    Print preprocessing comparison summary.
    """
    print("\n" + "=" * 70)
    print("PREPROCESSING REPORT")
    print("=" * 70)

    print(f"Raw shape       : {raw_df.shape}")
    print(f"Processed shape : {processed_df.shape}")

    added_cols = [col for col in processed_df.columns if col not in raw_df.columns]
    removed_cols = [col for col in raw_df.columns if col not in processed_df.columns]

    print(f"\nAdded columns ({len(added_cols)}):")
    print(added_cols)

    print(f"\nRemoved columns ({len(removed_cols)}):")
    print(removed_cols)

    if "isFraud" in processed_df.columns:
        print("\nProcessed fraud distribution:")
        print(processed_df["isFraud"].value_counts(normalize=True))

    bool_cols = processed_df.select_dtypes(include=["bool"]).columns.tolist()
    if bool_cols:
        print("\nWarning: boolean columns still found after preprocessing:")
        print(bool_cols)
    else:
        print("\nAll engineered/encoded features are numeric-ready.")


def feature_summary_report(processed_df: pd.DataFrame) -> None:
    """
    Show a compact feature overview after preprocessing.
    """
    print("\n" + "=" * 70)
    print("FEATURE SUMMARY REPORT")
    print("=" * 70)

    numeric_cols = processed_df.select_dtypes(include=[np.number]).columns.tolist()
    print(f"Total numeric columns: {len(numeric_cols)}")

    suspicious_cols = [
        "org_balance_change",
        "dest_balance_change",
        "org_amount_diff",
        "dest_amount_diff",
        "amount_to_oldbalanceOrg_ratio",
        "amount_to_oldbalanceDest_ratio",
        "is_full_balance_drain",
        "balance_change_mismatch",
        "is_night_transaction",
        "is_extreme_transaction",
    ]
    existing_cols = [col for col in suspicious_cols if col in processed_df.columns]

    if existing_cols:
        print("\nSelected engineered features preview:")
        print(processed_df[existing_cols].head())


# -------------------------------------------------------------------
# Main
# -------------------------------------------------------------------
if __name__ == "__main__":
    try:
        print("Loading raw dataset...")
        raw_df = load_data()

        print("\nRAW DATA REPORT")
        print("=" * 70)
        basic_data_report(raw_df)

        print("\nApplying preprocessing pipeline...")
        processed_df = preprocess_data(raw_df)

        preprocessing_report(raw_df, processed_df)
        feature_summary_report(processed_df)

        print("\nPROCESSED DATA SAMPLE")
        print("=" * 70)
        print(processed_df.head())

        print("\nTesting train/test split...")
        X_train, X_test, y_train, y_test = get_train_test_data()

        print(f"\nX_train shape: {X_train.shape}")
        print(f"X_test shape : {X_test.shape}")
        print(f"y_train shape: {y_train.shape}")
        print(f"y_test shape : {y_test.shape}")

        print("\nTrain fraud ratio:")
        print(y_train.value_counts(normalize=True))

        print("\nTest fraud ratio:")
        print(y_test.value_counts(normalize=True))

        print("\nData pipeline check completed successfully.")

    except FileNotFoundError as e:
        print(f"Error: {e}")
    except Exception as e:
        print(f"Error while processing dataset: {e}")