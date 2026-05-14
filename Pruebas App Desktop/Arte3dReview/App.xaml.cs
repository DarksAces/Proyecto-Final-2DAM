using System.Configuration;
using System.Data;
using System.Windows;

namespace Jovi3DReview;

/// <summary>
/// Interaction logic for App.xaml
/// </summary>
public partial class App : Application
{
    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);
        
        // Initialize Theme and Language from persisted settings
        Jovi3DReview.Services.ThemeService.Instance.Initialize();
    }
}

