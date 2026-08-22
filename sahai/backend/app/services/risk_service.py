"""Risk prediction using trained XGBoost model + SHAP explanations."""

from pathlib import Path

import joblib
import numpy as np
import shap

MODEL_PATH = Path(__file__).resolve().parent.parent / "models" / "risk_model.pkl"

_bundle = None
_explainer = None


def _load_bundle():
    global _bundle, _explainer
    if _bundle is None:
        if not MODEL_PATH.exists():
            raise FileNotFoundError(
                f"Risk model not found at {MODEL_PATH}. "
                "Run: python -m app.models.train_classifier"
            )
        _bundle = joblib.load(MODEL_PATH)
        _explainer = shap.TreeExplainer(_bundle["model"])
    return _bundle, _explainer


def predict_risk(
    age: int,
    systolic_bp: int,
    diastolic_bp: int,
    blood_sugar: float,
    body_temp: float,
    heart_rate: int,
) -> dict:
    bundle, explainer = _load_bundle()
    model = bundle["model"]
    columns = bundle["feature_columns"]
    labels = bundle["feature_labels"]
    risk_labels = bundle["risk_labels"]

    row = np.array(
        [[age, systolic_bp, diastolic_bp, blood_sugar, body_temp, heart_rate]]
    )
    proba = model.predict_proba(row)[0]
    pred_idx = int(np.argmax(proba))
    risk_level = risk_labels[pred_idx]
    confidence = float(proba[pred_idx])

    shap_values = explainer.shap_values(row)
    if isinstance(shap_values, list):
        class_shap = shap_values[pred_idx][0]
    elif shap_values.ndim == 3:
        class_shap = shap_values[0, :, pred_idx]
    else:
        class_shap = shap_values[0]

    factors = []
    for i, col in enumerate(columns):
        factors.append(
            {
                "feature": labels.get(col, col),
                "impact": float(class_shap[i]),
            }
        )
    factors.sort(key=lambda f: abs(f["impact"]), reverse=True)
    top_factors = factors[:2]

    return {
        "risk_level": risk_level,
        "confidence": confidence,
        "top_factors": top_factors,
    }
