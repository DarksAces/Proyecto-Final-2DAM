using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using Jovi3DReview.Services;

namespace Jovi3DReview.Views
{
    public partial class LoginView : UserControl
    {
        private readonly AuthService _authService;

        public LoginView()
        {
            InitializeComponent();
            _authService = AuthService.Instance;
        }

        private async void Login_Click(object sender, RoutedEventArgs e)
        {
            string email = EmailBox.Text;
            string password = PasswordBox.Password;

            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
            {
                ErrorMessage.Text = "Por favor, introduce email y contraseña.";
                ErrorMessage.Visibility = Visibility.Visible;
                return;
            }

            LoadingProgressBar.Visibility = Visibility.Visible;
            ErrorMessage.Visibility = Visibility.Collapsed;
            LoginButton.IsEnabled = false;

            try
            {
                var token = await _authService.LoginAsync(email, password);
                if (!string.IsNullOrEmpty(token))
                {
                     // Navigate to Dashboard
                     var mainWindow = Window.GetWindow(this) as MainWindow;
                     if (mainWindow != null)
                     {
                         mainWindow.ShowSidebar();
                         mainWindow.LoadUserProfile();
                         mainWindow.NavigateToDashboard();
                     }
                }
                else
                {
                    ErrorMessage.Text = "Error desconocido al iniciar sesión.";
                    ErrorMessage.Visibility = Visibility.Visible;
                }
            }
            catch (Exception ex)
            {
                ErrorMessage.Text = $"Error: {ex.Message}";
                ErrorMessage.Visibility = Visibility.Visible;
            }
            finally
            {
                LoadingProgressBar.Visibility = Visibility.Collapsed;
                LoginButton.IsEnabled = true;
            }
        }
    }
}
