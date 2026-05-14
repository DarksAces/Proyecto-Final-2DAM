using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using Jovi3DReview.ViewModels;

namespace Jovi3DReview.Views
{
    public partial class LoginView : UserControl
    {
        public LoginViewModel ViewModel { get; }

        public LoginView()
        {
            InitializeComponent();
            ViewModel = new LoginViewModel();
            this.DataContext = ViewModel;
        }

        private async void Login_Click(object sender, RoutedEventArgs e)
        {
            // Bind manual password box since it's not bindable by default
            ViewModel.Email = EmailBox.Text;
            ViewModel.Password = PasswordBox.Password;

            await ViewModel.LoginCommand.ExecuteAsync(async () => 
            {
                var mainWindow = Window.GetWindow(this) as MainWindow;
                if (mainWindow != null)
                {
                    mainWindow.ShowSidebar();
                    mainWindow.LoadUserProfile();
                    mainWindow.NavigateToDashboard();
                }
                await Task.CompletedTask;
            });
        }
    }
}
