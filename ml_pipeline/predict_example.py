"""
Example script showing how to use the trained hepatitis mortality prediction model
on new patient data.
"""

import pandas as pd
import numpy as np
from model_optimized import OptimizedHepatitisModel

# Example: Load the trained model
model = OptimizedHepatitisModel()
model.load_model('best_hepatitis_optimized.pkl')

# Example 1: Single patient prediction
# Create a DataFrame with patient features (must match training data columns)
new_patient = pd.DataFrame({
    'age': [45],
    'sex': [1],  # 0=female, 1=male (after encoding)
    'steroid': [1],  # 0=False, 1=True
    'antivirals': [0],
    'fatigue': [1],
    'malaise': [0],
    'anorexia': [1],
    'liverbig': [1],
    'liverfirm': [0],
    'spleenpalpable': [0],
    'spiders': [0],
    'ascites': [0],
    'varices': [0],
    'bilirubin': [1.2],
    'alkphosphate': [85],
    'sgot': [45],
    'albumin': [4.0],
    'protime': [70],
    'histology': [0]
})

# Get mortality probability
mortality_prob = model.predict_mortality_probability(new_patient)
print("="*60)
print("SINGLE PATIENT PREDICTION")
print("="*60)
print(f"Patient mortality probability: {mortality_prob[0]:.4f} ({mortality_prob[0]*100:.2f}%)")
print(f"Risk level: {'HIGH RISK' if mortality_prob[0] > 0.5 else 'LOW RISK'}")
print()

# Example 2: Multiple patients prediction
multiple_patients = pd.DataFrame({
    'age': [30, 55, 70],
    'sex': [0, 1, 0],
    'steroid': [0, 1, 1],
    'antivirals': [1, 0, 0],
    'fatigue': [0, 1, 1],
    'malaise': [0, 1, 1],
    'anorexia': [0, 1, 1],
    'liverbig': [1, 1, 1],
    'liverfirm': [0, 1, 1],
    'spleenpalpable': [0, 0, 1],
    'spiders': [0, 1, 1],
    'ascites': [0, 0, 1],
    'varices': [0, 0, 0],
    'bilirubin': [0.8, 1.5, 2.3],
    'alkphosphate': [75, 120, 180],
    'sgot': [30, 80, 150],
    'albumin': [4.2, 3.5, 2.8],
    'protime': [85, 60, 40],
    'histology': [0, 0, 1]
})

mortality_probs = model.predict_mortality_probability(multiple_patients)

print("="*60)
print("MULTIPLE PATIENTS PREDICTION")
print("="*60)
for i, prob in enumerate(mortality_probs):
    risk_level = "HIGH" if prob > 0.5 else "MODERATE" if prob > 0.3 else "LOW"
    print(f"Patient {i+1}: {prob:.4f} ({prob*100:.2f}%) - {risk_level} RISK")
print()

# Example 3: Loading data from CSV and making predictions
print("="*60)
print("BATCH PREDICTION FROM CSV")
print("="*60)
print("To predict on a CSV file with new patient data:")
print()
print("# Load your CSV")
print("new_data = pd.read_csv('new_patients.csv')")
print()
print("# Make sure columns match training data")
print("# The CSV should have these columns:")
print(f"# {model.feature_names}")
print()
print("# Get predictions")
print("predictions = model.predict_mortality_probability(new_data)")
print()
print("# Add predictions to dataframe")
print("new_data['mortality_probability'] = predictions")
print("new_data['risk_level'] = new_data['mortality_probability'].apply(")
print("    lambda x: 'HIGH' if x > 0.5 else 'MODERATE' if x > 0.3 else 'LOW'")
print(")")
print()
print("# Save results")
print("new_data.to_csv('predictions_output.csv', index=False)")
print()

# Example 4: Integration with IRIS database (for hackathon)
print("="*60)
print("INTEGRATION WITH IRIS DATABASE")
print("="*60)
print("""
# Example: Query patient data from IRIS and make predictions

import iris

# Connect to IRIS and query patient data
query = '''
    SELECT age, sex, steroid, antivirals, fatigue, malaise, anorexia,
           liverbig, liverfirm, spleenpalpable, spiders, ascites, varices,
           bilirubin, alkphosphate, sgot, albumin, protime, histology
    FROM hepatitis_patients
    WHERE prediction_needed = 1
'''

# Execute query and get results as DataFrame
patient_data = pd.read_sql(query, connection)

# Make predictions
mortality_predictions = model.predict_mortality_probability(patient_data)

# Update IRIS database with predictions
for idx, prob in enumerate(mortality_predictions):
    patient_id = patient_data.iloc[idx]['patient_id']
    # Update IRIS with prediction
    iris.sql.exec(f'''
        UPDATE hepatitis_patients 
        SET mortality_probability = {prob},
            risk_level = '{"HIGH" if prob > 0.5 else "LOW"}'
        WHERE patient_id = {patient_id}
    ''')
""")

print("\n" + "="*60)
print("FEATURE REQUIREMENTS")
print("="*60)
print("\nYour input data MUST have these columns:")
for i, feature in enumerate(model.feature_names, 1):
    print(f"  {i:2d}. {feature}")
print("\nNote: Categorical features (sex, boolean values) must be encoded as integers")
print("      Use the same encoding as the training data:")
print("      - sex: 0=female, 1=male")
print("      - boolean fields: 0=False, 1=True")
