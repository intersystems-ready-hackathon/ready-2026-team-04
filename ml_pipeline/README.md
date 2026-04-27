# Hepatitis Mortality Prediction - MLP Regression Model

This directory contains a Multi-Layer Perceptron (MLP) regression model for predicting **mortality probability** for hepatitis patients.

**Important**: This is a regression model that outputs continuous probability values from 0 to 1, NOT a binary classifier.
- **0.0** = Very low mortality risk (patient likely to live)
- **0.5** = Moderate mortality risk
- **1.0** = Very high mortality risk (patient likely to die)

## Setup

1. **Install dependencies:**
   ```bash
   pip install -r requirements_ml.txt
   ```

2. **Train the model:**
   ```bash
   python model.py
   ```

## What the Model Does

- **Data**: Uses `hepatitis.csv` with patient features (age, sex, lab values, symptoms)
- **Target**: Predicts mortality outcome (0=live, 1=die)
- **Preprocessing**: 
  - Handles missing values
  - Encodes categorical features (sex, boolean fields)
  - Standardizes numerical features
- **Model**: Multi-Layer Perceptron Regressor with grid search hyperparameter tuning
- **Grid Search Tests**: 60 different configurations across:
  - Hidden layer architectures: (50,), (100,), (50,25), (100,50), (100,50,25)
  - Activation functions: relu, tanh
  - Regularization (alpha): 0.0001, 0.001, 0.01
  - Learning rates: constant, adaptive

## Output

The model will:
1. Print grid search progress
2. Display best hyperparameters
3. Show training and test metrics (MSE, RMSE, MAE, R²)
4. Report classification accuracy
5. Save the best model to `best_hepatitis_mlp_model.pkl`

## Using the Trained Model

```python
from model import HepatitisMLPModel
import pandas as pd

# Load the saved model
model = HepatitisMLPModel()
model.load_model('best_hepatitis_mlp_model.pkl')

# Make predictions on new patient data
# X should be a DataFrame with the same features as training data
mortality_probabilities = model.predict_mortality_probability(X)

# Example output interpretation:
# mortality_probabilities = [0.15, 0.82, 0.43]
# Patient 1: 15% mortality risk (low risk)
# Patient 2: 82% mortality risk (high risk)
# Patient 3: 43% mortality risk (moderate risk)

print(f"Patient mortality probabilities: {mortality_probabilities}")
```

## Model Performance

The model outputs comprehensive regression metrics:
- **MSE/RMSE**: Measures prediction error in probability units
- **MAE**: Average absolute error in probability predictions
- **R²**: Proportion of variance explained (how well the model fits the data)
- **Probability Range**: Shows the distribution of predicted mortality probabilities

Lower MSE/RMSE/MAE and higher R² indicate better model performance.
