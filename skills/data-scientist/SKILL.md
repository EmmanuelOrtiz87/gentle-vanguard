---
name: data-scientist
description: >
  Data Scientist: machine learning, statistical analysis, predictive modeling. Trigger: "machine
  learning", "ML model", "data science", "prediction", "classification", "regression", "pandas".
---

## When to Use

- Building machine learning models (classification, regression)
- Performing statistical analysis and hypothesis testing
- Creating data pipelines and feature engineering
- Evaluating model performance and tuning hyperparameters
- Deploying models to production (MLOps)

## 📋 Technical Deliverables

### ML Model Pipeline

```python
# model_pipeline.py
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, roc_auc_score

# 1. Load data
df = pd.read_csv('data/customers.csv')

# 2. Feature engineering
df['tenure_months'] = (pd.Today() - df['signup_date']).dt.days / 30
df['total_spend_per_month'] = df['total_spend'] / df['tenure_months']

# 3. Prepare features and target
X = df[['tenure_months', 'total_spend_per_month', 'support_tickets']]
y = df['churned']

# 4. Train-test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 5. Train model
model = RandomForestClassifier(n_estimators=100, max_depth=10)
model.fit(X_train, y_train)

# 6. Evaluate
y_pred = model.predict(X_test)
print(classification_report(y_test, y_pred))
print(f"AUC: {roc_auc_score(y_test, model.predict_proba(X_test)[:, 1])}")
```

### A/B Test Analysis

```python
# ab_test_analysis.py
import scipy.stats as stats
import pandas as pd

# Load experiment data
df = pd.read_csv('data/ab_test_results.csv')

# Control (A) vs Treatment (B)
group_a = df[df['group'] == 'control']['conversion']
group_b = df[df['group'] == 'treatment']['conversion']

# T-test
t_stat, p_value = stats.ttest_ind(group_a, group_b)
print(f"T-statistic: {t_stat:.3f}, P-value: {p_value:.4f}")

# Business impact
if p_value < 0.05:
    lift = (group_b.mean() - group_a.mean()) / group_a.mean() * 100
    print(f"Statistically significant! Lift: {lift:.1f}%")
```

## 🔄 Workflow Process

### Step1: Problem Definition & Data Collection

- Define the business problem (churn prediction, recommendation, etc.)
- Identify data sources (databases, APIs, logs)
- Collect and label data (if supervised learning)
- Document data dictionary and schema

### Step2: Exploratory Data Analysis (EDA)

- Analyze distributions, outliers, missing values
- Visualize relationships (correlation, scatter plots)
- Generate hypotheses to test
- Feature selection (what matters?)

### Step3: Model Development

- Split data (train/validation/test)
- Try multiple algorithms (Random Forest, XGBoost, Neural Nets)
- Feature engineering (create new predictive features)
- Hyperparameter tuning (GridSearch, RandomizedSearch)

### Step4: Evaluation & Deployment

- Evaluate on test set (not training!)
- Check for overfitting (train vs test performance)
- Deploy model (API, batch, or real-time)
- Monitor drift and retrain periodically

## 🎯 Success Metrics

---

> **Referencia detallada**: [ eferences/detail.md](references/detail.md)
