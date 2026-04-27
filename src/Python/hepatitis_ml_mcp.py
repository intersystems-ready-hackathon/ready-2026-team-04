import logging
import sys
import pandas as pd
import os
from mcp.server.fastmcp import FastMCP

# ---- MCP STDIO RULE ----
# stdout MUST contain ONLY MCP protocol JSON
# so move everything else off it
logging.basicConfig(stream=sys.stderr, level=logging.INFO)

mcp = FastMCP('hepatitis_ml', log_level="ERROR")

# Global model variable
_model = None

def get_model():
    """Lazy load the ML model"""
    global _model
    if _model is None:
        # Import here to avoid issues if not in path
        sys.path.insert(0, '/home/irisowner/dev')
        from ml_pipeline.model_optimized import OptimizedHepatitisModel
        
        _model = OptimizedHepatitisModel()
        model_path = '/home/irisowner/dev/ml_pipeline/best_hepatitis_optimized.pkl'
        _model.load_model(model_path)
        logging.info(f"ML Model loaded from {model_path}")
    return _model

@mcp.tool()
async def predict_hepatitis_mortality(
    age: int,
    sex: int,
    steroid: int,
    antivirals: int,
    fatigue: int,
    malaise: int,
    anorexia: int,
    liverbig: int,
    liverfirm: int,
    spleenpalpable: int,
    spiders: int,
    ascites: int,
    varices: int,
    bilirubin: float,
    alkphosphate: float,
    sgot: float,
    albumin: float,
    protime: float,
    histology: int
) -> dict:
    """Predict mortality probability for a hepatitis patient using ML model (87.10% accuracy).
    
    Args:
        age: Patient age in years
        sex: 0=female, 1=male
        steroid: Steroid treatment (0=no, 1=yes)
        antivirals: Antiviral treatment (0=no, 1=yes)
        fatigue: Fatigue symptom (0=no, 1=yes)
        malaise: Malaise symptom (0=no, 1=yes)
        anorexia: Anorexia symptom (0=no, 1=yes)
        liverbig: Enlarged liver (0=no, 1=yes)
        liverfirm: Firm liver (0=no, 1=yes)
        spleenpalpable: Palpable spleen (0=no, 1=yes)
        spiders: Spider angiomas (0=no, 1=yes)
        ascites: Ascites present (0=no, 1=yes)
        varices: Varices present (0=no, 1=yes)
        bilirubin: Bilirubin level (mg/dL)
        alkphosphate: Alkaline phosphatase level (U/L)
        sgot: SGOT level (U/L)
        albumin: Albumin level (g/dL)
        protime: Prothrombin time (seconds)
        histology: Liver histology (0=no, 1=yes)
    
    Returns:
        Dictionary with mortality prediction results:
        - mortality_probability: float (0-1 range)
        - mortality_percentage: string (e.g., "23.45%")
        - risk_level: string ("LOW", "MODERATE", or "HIGH")
        - recommendation: string with clinical recommendation
    """
    try:
        model = get_model()
        
        # Create patient data DataFrame
        patient_data = pd.DataFrame({
            'age': [age], 
            'sex': [sex], 
            'steroid': [steroid],
            'antivirals': [antivirals], 
            'fatigue': [fatigue],
            'malaise': [malaise], 
            'anorexia': [anorexia],
            'liverbig': [liverbig], 
            'liverfirm': [liverfirm],
            'spleenpalpable': [spleenpalpable], 
            'spiders': [spiders],
            'ascites': [ascites], 
            'varices': [varices],
            'bilirubin': [bilirubin], 
            'alkphosphate': [alkphosphate],
            'sgot': [sgot], 
            'albumin': [albumin],
            'protime': [protime], 
            'histology': [histology]
        })
        
        # Get prediction
        prob = model.predict_mortality_probability(patient_data)[0]
        
        # Determine risk level based on clinical trial criteria
        if prob > 0.85:
            risk_level = "CRITICAL"
        elif prob >= 0.50:
            risk_level = "CLINICAL_TRIAL_CANDIDATE"
        else:
            risk_level = "STANDARD_TREATMENT"
        
        # Generate recommendation based on new thresholds
        if prob > 0.85:
            recommendation = "CRITICAL: Focus on patient care and quality of life. Mortality risk >85%."
        elif prob >= 0.50:
            recommendation = "RECOMMEND CLINICAL TRIAL: Patient is a candidate for clinical trial enrollment. Mortality risk 50-85%."
        else:
            recommendation = "CONTINUE STANDARD TREATMENT: Patient should continue on current treatment protocol. Mortality risk <50%."
        
        return {
            "mortality_probability": float(prob),
            "mortality_percentage": f"{prob * 100:.2f}%",
            "risk_level": risk_level,
            "recommendation": recommendation
        }
        
    except Exception as e:
        logging.error(f"Error in predict_hepatitis_mortality: {str(e)}")
        return {
            "error": str(e),
            "mortality_probability": -1.0,
            "mortality_percentage": "ERROR",
            "risk_level": "ERROR",
            "recommendation": f"Error occurred: {str(e)}"
        }

@mcp.tool()
async def batch_predict_hepatitis(patients: list) -> list:
    """Predict mortality for multiple hepatitis patients at once.
    
    Args:
        patients: List of patient dictionaries, each containing all 19 features
        
    Returns:
        List of prediction dictionaries
    """
    try:
        model = get_model()
        
        # Convert list of patients to DataFrame
        patient_df = pd.DataFrame(patients)
        
        # Get predictions
        probs = model.predict_mortality_probability(patient_df)
        
        results = []
        for i, prob in enumerate(probs):
            risk_level = "HIGH" if prob > 0.5 else "MODERATE" if prob > 0.3 else "LOW"
            
            results.append({
                "patient_index": i,
                "mortality_probability": float(prob),
                "mortality_percentage": f"{prob * 100:.2f}%",
                "risk_level": risk_level
            })
        
        return results
        
    except Exception as e:
        logging.error(f"Error in batch_predict_hepatitis: {str(e)}")
        return [{"error": str(e)}]


if __name__ == '__main__':
    mcp.run(transport='stdio')
