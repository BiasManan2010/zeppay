"""Train XGBoost maternal health risk classifier and save SHAP summary."""

from pathlib import Path

import joblib
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import shap
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, f1_score
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier

ROOT = Path(__file__).resolve().parents[3]
DATA_PATH = ROOT / "data" / "maternal_risk.csv"
MODEL_PATH = Path(__file__).resolve().parent / "risk_model.pkl"
SHAP_PATH = ROOT / "data" / "shap_summary.png"

FEATURE_COLUMNS = [
    "Age",
    "SystolicBP",
    "DiastolicBP",
    "BS",
    "BodyTemp",
    "HeartRate",
]
FEATURE_LABELS = {
    "Age": "age",
    "SystolicBP": "systolic_bp",
    "DiastolicBP": "diastolic_bp",
    "BS": "blood_sugar",
    "BodyTemp": "body_temp",
    "HeartRate": "heart_rate",
}
RISK_MAP = {"low risk": 0, "mid risk": 1, "high risk": 2}
RISK_LABELS = ["low", "mid", "high"]


def main() -> None:
    df = pd.read_csv(DATA_PATH)
    df = df.dropna()
    df["RiskLevel"] = df["RiskLevel"].str.strip().str.lower()
    df["risk_encoded"] = df["RiskLevel"].map(RISK_MAP)
    if df["risk_encoded"].isna().any():
        raise ValueError("Unknown risk labels in dataset")

    X = df[FEATURE_COLUMNS]
    y = df["risk_encoded"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    model = XGBClassifier(
        n_estimators=100,
        max_depth=4,
        learning_rate=0.1,
        random_state=42,
        eval_metric="mlogloss",
    )
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    print("Accuracy:", accuracy_score(y_test, y_pred))
    print("F1 (macro):", f1_score(y_test, y_pred, average="macro"))
    print("Confusion matrix:\n", confusion_matrix(y_test, y_pred))
    print(classification_report(y_test, y_pred, target_names=RISK_LABELS))

    explainer = shap.TreeExplainer(model)
    shap_values = explainer.shap_values(X_test)
    if isinstance(shap_values, list):
        shap_values = np.array(shap_values)

    plt.figure(figsize=(10, 6))
    shap.summary_plot(shap_values, X_test, show=False)
    SHAP_PATH.parent.mkdir(parents=True, exist_ok=True)
    plt.tight_layout()
    plt.savefig(SHAP_PATH, dpi=120)
    plt.close()
    print(f"SHAP summary saved to {SHAP_PATH}")

    joblib.dump(
        {
            "model": model,
            "feature_columns": FEATURE_COLUMNS,
            "feature_labels": FEATURE_LABELS,
            "risk_labels": RISK_LABELS,
        },
        MODEL_PATH,
    )
    print(f"Model saved to {MODEL_PATH}")


if __name__ == "__main__":
    main()
