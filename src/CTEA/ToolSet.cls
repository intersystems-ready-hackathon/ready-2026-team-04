Class CTEA.ToolSet Extends %AI.ToolSet [ DependsOn = CTEA.Tool ]
{

XData Definition [ MimeType = application/xml ]
{
<ToolSet Name="HepatitisData">
  <Description>Tools for querying a hepatitis patient dataset containing clinical lab values, symptoms, demographics, and survival outcomes.</Description>
  <Include Class="CTEA.Tool"/>
</ToolSet>
}

}
