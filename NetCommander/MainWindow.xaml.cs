using Microsoft.Win32;
using System;
using System.Collections.ObjectModel;
using System.Diagnostics;
using System.IO;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using System.Windows;
using System.Windows.Controls;

namespace NetCommander
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        Process process = null;
        public MainWindow()
        {
            InitializeComponent();
            Console.SetOut(new StreamWriter("log.log"));
            SystemEvents.SessionEnding += SystemEvents_SessionEnding;
        }

        private void SystemEvents_SessionEnding(object sender, SessionEndingEventArgs e)
        {
            e.Cancel = true;
            Process.Start("shutdown", "-a");
            Process.Start("shutdown", "/r /t 0");
        }

        private string RunScript(string scriptText)
        {
            // create Powershell runspace
            Runspace runspace = RunspaceFactory.CreateRunspace();

            // open it
            runspace.Open();

            // create a pipeline and feed it the script text
            Pipeline pipeline = runspace.CreatePipeline();
            pipeline.Commands.AddScript(scriptText);
            pipeline.Commands.Add("Out-String");

            // execute the script
            Collection<PSObject> results = pipeline.Invoke();

            // close the runspace
            runspace.Close();

            // convert the script result into a single string
            StringBuilder stringBuilder = new StringBuilder();
            foreach (PSObject obj in results)
            {
                stringBuilder.AppendLine(obj.ToString());
            }

            return stringBuilder.ToString();
        }

        private void lstScripts_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            string scriptPath = lstScripts.SelectedItem.ToString();
            if (File.Exists(scriptPath))
                GetProperties(scriptPath);
            else
                Console.WriteLine(scriptPath + "Not Found");
        }

        private void GetProperties(string scriptPath)
        {
            Runspace runspace = RunspaceFactory.CreateRunspace();
            runspace.Open();
            Pipeline pipeline = runspace.CreatePipeline();
            pipeline.Commands.Add($"Get-Command {scriptPath}");

            // execute the script
            Collection<PSObject> results = pipeline.Invoke();

            // close the runspace
            runspace.Close();
        }

        protected override void OnClosed(EventArgs e)
        {
            SystemEvents.SessionEnding -= SystemEvents_SessionEnding;
            base.OnClosed(e);
        }

        private void btnAddScript_Click(object sender, RoutedEventArgs e)
        {
            OpenFileDialog openFile = new OpenFileDialog()
            {
                Filter = "PowerShell file (*.ps1)|*.ps1",
            };
            openFile.ShowDialog();
            string filePath = openFile.FileName;
            var info = File.GetLastWriteTime(filePath).ToString("dd-MM-yyyy HH:mm:ss");
            if (!string.IsNullOrEmpty(filePath) && File.Exists(filePath))
                lstScripts.Items.Add(new ScriptsDetails() { ScriptPath = filePath, ModDate = info });
        }
    }

    public class ScriptsDetails
    {
        public string ScriptPath { get; set; }
        public string ModDate { get; set; }
    }
}
