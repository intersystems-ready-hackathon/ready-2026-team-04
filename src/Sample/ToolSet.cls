Class Sample.ToolSet Extends %AI.ToolSet [DependsOn=Sample.Tools]
{
    XData Definition
    {
        <ToolSet>
            <Description>Sample Toolset with Hepatitis ML Predictions</Description>
            <Include Class="Sample.Tools"></Include>
            <MCP Name="PythonServer">
                <Stdio Executable="/usr/irissys/bin/irispython" 
                Args="/home/irisowner/dev/src/Python/multiplication_mcp.py" />
            </MCP>
            <MCP Name="HepatitisML">
                <Stdio Executable="/usr/irissys/bin/irispython" 
                Args="/home/irisowner/dev/src/Python/hepatitis_ml_mcp.py" />
            </MCP>
        </ToolSet>
    }    
}

