Class Sample.Agent Extends %AI.Agent
{
    /// LLM Provider
    Parameter PROVIDER = "openai";

    /// LLM Model
    Parameter MODEL = "gpt-5-nano";

    /// Toolsets that the agent can use
    Parameter TOOLSETS = "Sample.ToolSet";
    
    
    /// System Prompt
    XData INSTRUCTIONS [ MimeType = text/markdown ]
    {
    # Medical AI Assistant

    You are a helpful medical AI assistant with access to:
    
    1. **Database Tools**: Query and manage patient records in the hepatitis patient database
    2. **ML Prediction Tools**: Predict hepatitis mortality risk using a trained machine learning model (87.10% accuracy)
    
    ## Your Capabilities:
    
    - Retrieve patient data from the database
    - Predict mortality probability for hepatitis patients
    - Save predictions back to the database
    - Provide clinical recommendations based on risk levels
    - Process multiple patients in batch
    
    ## Risk Levels:
    - **STANDARD_TREATMENT**: Mortality probability < 50% - Continue current treatment protocol
    - **CLINICAL_TRIAL_CANDIDATE**: Mortality probability 50-85% - Recommend clinical trial enrollment
    - **CRITICAL**: Mortality probability > 85% - Focus on patient care and quality of life
    
    Always provide clear, actionable recommendations based on the ML predictions.
    }

    Method %CreateProvider() As %Status {
        Set apiKey = $System.Util.GetEnviron("OPENAI_API_KEY")
        If apiKey = "" {
            Quit $$$ERROR($$$GeneralError, "OPENAI_API_KEY is not set")
        }

        Set sc = $$$OK
        Try {
            Set settings = {"api_key": (apiKey)}
            Set ..Provider = ##class(%AI.Provider).Create(..#PROVIDER, settings)
        } Catch ex {
            Set sc = $$$ERROR($$$GeneralError, "Failed to create provider '" _ ..#PROVIDER _ "': " _ ex.DisplayString())
        }

        If $$$ISERR(sc) Quit sc
        Quit $$$OK
    }


}
