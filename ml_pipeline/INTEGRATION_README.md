# Hepatitis ML Model - IRIS Integration Guide

This guide explains how the hepatitis mortality prediction ML model integrates with InterSystems IRIS using AI agents and MCP tools.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AI Agent (Sample.Agent)                   │
│  - Receives natural language requests                       │
│  - Orchestrates database queries and ML predictions         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  ToolSet (Sample.ToolSet)                    │
│  - ObjectScript Tools (Sample.HepatitisTools)               │
│  - Python MCP Tools (hepatitis_ml_mcp.py)                   │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┴─────────────┐
                ▼                           ▼
┌──────────────────────────┐   ┌──────────────────────────┐
│  IRIS Database           │   │  ML Model (Python)       │
│  - HepatitisPatient      │   │  - RandomForest          │
│  - SQL Queries           │   │  - 87.10% Accuracy       │
│  - Store Predictions     │   │  - Probability Output    │
└──────────────────────────┘   └──────────────────────────┘
```

## Components Created

### 1. **Python MCP Tool** (`src/Python/hepatitis_ml_mcp.py`)
Exposes ML model as MCP tools that the agent can call:

**Tools:**
- `predict_hepatitis_mortality()` - Predict single patient
- `batch_predict_hepatitis()` - Predict multiple patients

**Returns:**
```json
{
  "mortality_probability": 0.2345,
  "mortality_percentage": "23.45%",
  "risk_level": "LOW",
  "recommendation": "LOW RISK: Continue standard care..."
}
```

### 2. **ObjectScript Tools** (`src/Sample/HepatitisTools.cls`)
Database operations for patient management:

**Methods:**
- `GetPatientById(patientId)` - Retrieve patient data
- `GetPendingPatients()` - Get all patients needing predictions
- `GetAllPatients()` - List all patients with predictions
- `SavePrediction(patientId, prob, risk)` - Save ML results
- `AddPatient(...)` - Add new patient to database

### 3. **Patient Table** (`src/Sample/HepatitisPatient.cls`)
Persistent class storing patient data and predictions:

**Properties:**
- Clinical features (age, sex, bilirubin, etc.)
- Prediction results (MortalityProbability, RiskLevel)
- Status tracking (PredictionStatus, PredictionTimestamp)

### 4. **Updated ToolSet** (`src/Sample/ToolSet.cls`)
Registers both ObjectScript and Python tools:
- Includes `Sample.HepatitisTools`
- Includes `HepatitisML` MCP server

### 5. **Updated Agent** (`src/Sample/Agent.cls`)
Medical AI assistant with ML prediction capabilities

## How the Agent Works

### Example Workflow 1: Single Patient Prediction

**User:** "Predict mortality risk for patient 12345"

**Agent Process:**
1. Calls `GetPatientById(12345)` → retrieves patient data
2. Calls `predict_hepatitis_mortality(age, sex, ...)` → ML prediction
3. Calls `SavePrediction(12345, 0.234, "LOW")` → saves to database
4. Returns: "Patient 12345 has 23.4% mortality risk (LOW). Recommendation: Continue standard care..."

### Example Workflow 2: Batch Processing

**User:** "Analyze all pending hepatitis patients"

**Agent Process:**
1. Calls `GetPendingPatients()` → retrieves all pending patients
2. For each patient:
   - Calls `predict_hepatitis_mortality(...)` → ML prediction
   - Calls `SavePrediction(...)` → saves result
3. Returns summary: "Processed 15 patients: 2 HIGH risk, 5 MODERATE, 8 LOW"

### Example Workflow 3: Add New Patient

**User:** "Add a new patient: 45 year old male with bilirubin 1.2..."

**Agent Process:**
1. Calls `AddPatient(age=45, sex=1, bilirubin=1.2, ...)` → creates patient
2. Calls `predict_hepatitis_mortality(...)` → immediate prediction
3. Calls `SavePrediction(...)` → saves prediction
4. Returns: "Patient added with ID 123. Mortality risk: 15.3% (LOW)"

## Setup Instructions

### 1. Build and Start IRIS Container

```bash
docker-compose up --build
```

### 2. Load Classes into IRIS

The classes will be automatically loaded during the Docker build from the `src/` directory.

### 3. Verify ML Model is Accessible

The ML model should be at:
```
/home/irisowner/dev/ml_pipeline/best_hepatitis_optimized.pkl
```

### 4. Test the Agent

Connect to IRIS and test:

```objectscript
// Create agent instance
Set agent = ##class(Sample.Agent).%New()

// Send a request
Set response = agent.Chat("Get patient 1 and predict their mortality risk")
Write response
```

## Agent Capabilities

The agent can understand and execute:

✅ **Query Operations:**
- "Show me patient 123"
- "List all pending patients"
- "Get all patients with HIGH risk"

✅ **ML Predictions:**
- "Predict mortality for patient 456"
- "What's the mortality risk for this patient?"
- "Analyze all pending patients"

✅ **Data Management:**
- "Add a new patient with age 45..."
- "Save the prediction for patient 789"
- "Update patient records"

✅ **Reporting:**
- "Show me a summary of all predictions"
- "Which patients have HIGH mortality risk?"
- "Generate a report for patient 123"

## Risk Level Interpretation

| Probability | Risk Level | Recommendation |
|-------------|-----------|----------------|
| 0% - 30% | LOW | Continue standard care with routine follow-up |
| 30% - 50% | MODERATE | Regular monitoring and standard treatment protocol |
| 50% - 70% | HIGH | Close monitoring and aggressive treatment recommended |
| 70% - 100% | HIGH | URGENT: Immediate intensive care recommended |

## Model Performance

- **Accuracy:** 87.10%
- **Algorithm:** RandomForest Classifier
- **Features:** 19 clinical features
- **Output:** Continuous probability (0-1) representing mortality risk

## Troubleshooting

### ML Model Not Loading
- Check model path: `/home/irisowner/dev/ml_pipeline/best_hepatitis_optimized.pkl`
- Verify Python dependencies are installed
- Check logs in stderr

### MCP Tool Not Found
- Verify ToolSet includes `HepatitisML` MCP server
- Check Python script path in ToolSet.cls
- Restart IRIS container

### Database Errors
- Ensure `Sample.HepatitisPatient` table is compiled
- Check SQL permissions
- Verify patient data format matches schema

## Next Steps

1. **Load Sample Data:** Import hepatitis.csv into IRIS database
2. **Test Agent:** Run example queries through the agent
3. **Build UI:** Create web interface for agent interactions
4. **Monitor Performance:** Track prediction accuracy on real data
5. **Extend Features:** Add more clinical tools and predictions

## Files Reference

```
ready-2026-team-04/
├── ml_pipeline/
│   ├── best_hepatitis_optimized.pkl    # Trained ML model
│   ├── model_optimized.py              # Model class
│   └── predict_example.py              # Usage examples
├── src/
│   ├── Python/
│   │   └── hepatitis_ml_mcp.py         # MCP tool wrapper
│   └── Sample/
│       ├── Agent.cls                   # AI Agent
│       ├── ToolSet.cls                 # Tool registry
│       ├── HepatitisTools.cls          # Database tools
│       └── HepatitisPatient.cls        # Patient table
```

## Support

For questions or issues:
1. Check IRIS logs: `docker-compose logs`
2. Review MCP stderr output
3. Test ML model independently: `python predict_example.py`
