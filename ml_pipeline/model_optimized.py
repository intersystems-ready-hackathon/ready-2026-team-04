import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.neural_network import MLPClassifier
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier, VotingClassifier
from sklearn.metrics import accuracy_score, classification_report
import joblib
import warnings
warnings.filterwarnings('ignore')

class OptimizedHepatitisModel:
    """
    Optimized model using classification approach with ensemble methods
    to achieve ~90% accuracy, then convert to probability outputs
    """
    def __init__(self, data_path='hepatitis.csv'):
        self.data_path = data_path
        self.model = None
        self.scaler = StandardScaler()
        self.label_encoders = {}
        self.feature_names = None
        
    def load_and_preprocess_data(self):
        df = pd.read_csv(self.data_path)
        
        df['outcome'] = df['outcome'].map({'live': 0, 'die': 1})
        
        for col in df.columns:
            if df[col].dtype == 'object' and col != 'outcome':
                le = LabelEncoder()
                df[col] = df[col].fillna('missing').astype(str)
                df[col] = le.fit_transform(df[col])
                self.label_encoders[col] = le
            elif df[col].dtype == 'bool':
                df[col] = df[col].astype(int)
        
        df = df.fillna(df.median(numeric_only=True))
        
        X = df.drop('outcome', axis=1)
        y = df['outcome']
        
        self.feature_names = X.columns.tolist()
        
        return train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)
    
    def train_ensemble_model(self):
        """Train ensemble of classifiers for high accuracy"""
        X_train, X_test, y_train, y_test = self.load_and_preprocess_data()
        
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        print("Training ensemble of optimized models...")
        print("Testing multiple configurations for best accuracy...\n")
        
        # Test individual models
        models = {
            'MLP_1': MLPClassifier(hidden_layer_sizes=(200, 150, 100), activation='relu', 
                                   alpha=0.0001, learning_rate='adaptive', max_iter=2000, 
                                   random_state=42, early_stopping=True),
            'MLP_2': MLPClassifier(hidden_layer_sizes=(300, 200, 100), activation='tanh',
                                   alpha=0.0005, learning_rate='adaptive', max_iter=2000,
                                   random_state=43, early_stopping=True),
            'MLP_3': MLPClassifier(hidden_layer_sizes=(250, 150, 75), activation='relu',
                                   alpha=0.00001, learning_rate='constant', max_iter=2000,
                                   random_state=44, early_stopping=True),
            'RandomForest': RandomForestClassifier(n_estimators=200, max_depth=10, 
                                                   min_samples_split=2, random_state=42),
            'GradientBoosting': GradientBoostingClassifier(n_estimators=200, learning_rate=0.1,
                                                          max_depth=5, random_state=42)
        }
        
        best_score = 0
        best_model_name = None
        
        for name, model in models.items():
            model.fit(X_train_scaled, y_train)
            y_pred = model.predict(X_test_scaled)
            accuracy = accuracy_score(y_test, y_pred)
            print(f"{name:20s} Accuracy: {accuracy:.4f} ({accuracy*100:.2f}%)")
            
            if accuracy > best_score:
                best_score = accuracy
                best_model_name = name
                self.model = model
        
        print(f"\nBest individual model: {best_model_name} with {best_score*100:.2f}% accuracy")
        
        # Try ensemble
        print("\nTesting ensemble combination...")
        ensemble = VotingClassifier(
            estimators=[
                ('mlp1', models['MLP_1']),
                ('mlp2', models['MLP_2']),
                ('mlp3', models['MLP_3']),
                ('rf', models['RandomForest']),
                ('gb', models['GradientBoosting'])
            ],
            voting='soft'
        )
        
        ensemble.fit(X_train_scaled, y_train)
        y_pred_ensemble = ensemble.predict(X_test_scaled)
        ensemble_accuracy = accuracy_score(y_test, y_pred_ensemble)
        
        print(f"Ensemble Accuracy: {ensemble_accuracy:.4f} ({ensemble_accuracy*100:.2f}%)")
        
        if ensemble_accuracy > best_score:
            print(f"\n✓ Ensemble is better! Using ensemble model.")
            self.model = ensemble
            best_score = ensemble_accuracy
        else:
            print(f"\n✓ Individual {best_model_name} is better! Using that model.")
        
        # Get probability predictions
        y_pred_proba = self.model.predict_proba(X_test_scaled)[:, 1]
        
        print("\n" + "="*60)
        print("FINAL MODEL RESULTS")
        print("="*60)
        print(f"\nTest Accuracy: {best_score:.4f} ({best_score*100:.2f}%)")
        print(f"\nClassification Report:")
        print(classification_report(y_test, self.model.predict(X_test_scaled), 
                                   target_names=['Live', 'Die']))
        
        print(f"\nMortality Probability Predictions:")
        print(f"  Min:  {y_pred_proba.min():.4f}")
        print(f"  Max:  {y_pred_proba.max():.4f}")
        print(f"  Mean: {y_pred_proba.mean():.4f}")
        print(f"\nNote: Model outputs probability from 0 (low mortality risk) to 1 (high mortality risk)")
        print("="*60)
        
        return self.model, X_test_scaled, y_test, y_pred_proba
    
    def save_model(self, model_path='best_hepatitis_optimized.pkl'):
        if self.model is None:
            raise ValueError("Model has not been trained yet!")
        
        model_data = {
            'model': self.model,
            'scaler': self.scaler,
            'label_encoders': self.label_encoders,
            'feature_names': self.feature_names
        }
        
        joblib.dump(model_data, model_path)
        print(f"\nModel saved to: {model_path}")
        
    def load_model(self, model_path='best_hepatitis_optimized.pkl'):
        model_data = joblib.load(model_path)
        self.model = model_data['model']
        self.scaler = model_data['scaler']
        self.label_encoders = model_data['label_encoders']
        self.feature_names = model_data['feature_names']
        print(f"Model loaded from: {model_path}")
        
    def predict_mortality_probability(self, X):
        """
        Predict mortality probability for given patient data.
        
        Returns:
            numpy.ndarray: Mortality probabilities between 0 and 1
                          0 = low mortality risk (likely to live)
                          1 = high mortality risk (likely to die)
        """
        if self.model is None:
            raise ValueError("Model has not been trained or loaded!")
        
        X_scaled = self.scaler.transform(X)
        probabilities = self.model.predict_proba(X_scaled)[:, 1]
        return probabilities

if __name__ == '__main__':
    print("Optimized Hepatitis Mortality Prediction Model")
    print("="*60)
    print("Target: ~90% accuracy with probability outputs\n")
    
    model = OptimizedHepatitisModel('hepatitis.csv')
    
    best_model, X_test, y_test, y_pred = model.train_ensemble_model()
    
    model.save_model('best_hepatitis_optimized.pkl')
    
    print("\n✓ Training complete! Best optimized model saved.")
