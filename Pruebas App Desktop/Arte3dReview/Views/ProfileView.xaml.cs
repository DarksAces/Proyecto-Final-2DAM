using System;
using System.Windows;
using System.Windows.Controls;
using Jovi3DReview.Services;

namespace Jovi3DReview.Views
{
    public partial class ProfileView : UserControl
    {
        private readonly AuthService _authService;
        private readonly FirebaseService _firebaseService;

        public ProfileView()
        {
            InitializeComponent();
            _authService = AuthService.Instance;
            _firebaseService = new FirebaseService();
            this.Loaded += ProfileView_Loaded;

            ThemeService.Instance.LanguageChanged += (s, lang) => {
                if (this.IsLoaded) ProfileView_Loaded(null, null);
            };
        }

        private async void ProfileView_Loaded(object sender, RoutedEventArgs e)
        {
            string userId = _authService.GetCurrentUserId();
            if (!string.IsNullOrEmpty(userId))
            {
                try 
                {
                    var user = await _firebaseService.GetUserAsync(userId);
                    if (user != null)
                    {
                        UserNameText.Text = user.Name ?? (Application.Current?.Resources["StrUsuario"]?.ToString() ?? "User");
                        UserEmailText.Text = user.Email ?? "Sin email";
                        UserRoleText.Text = (user.IsAdmin 
                            ? (Application.Current?.Resources["StrAdministrador"]?.ToString() ?? "Administrator") 
                            : user.Role ?? (Application.Current?.Resources["StrInvitado"]?.ToString() ?? "Guest")).ToUpper();
                    }
                }
                catch
                {
                    UserNameText.Text = Application.Current?.Resources["StrErrorAlCargar"]?.ToString() ?? "Error loading";
                }
            }
        }

        private async void ChangePassword_Click(object sender, RoutedEventArgs e)
        {
            string newPass = NewPasswordBox.Password;
            if (string.IsNullOrWhiteSpace(newPass))
            {
                string msg = Application.Current?.Resources["StrNuevaContrasenaError"]?.ToString() ?? "Please enter a new password.";
                string title = Application.Current?.Resources["StrError"]?.ToString() ?? "Error";
                MessageBox.Show(msg, title, MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (newPass.Length < 6)
            {
                string msg = Application.Current?.Resources["StrContrasenaCortaError"]?.ToString() ?? "Password must be at least 6 characters.";
                string title = Application.Current?.Resources["StrError"]?.ToString() ?? "Error";
                MessageBox.Show(msg, title, MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            bool success = await _authService.ChangePasswordAsync(newPass);
            if (success)
            {
                string msg = Application.Current?.Resources["StrContrasenaActualizada"]?.ToString() ?? "Password updated successfully.";
                string title = Application.Current?.Resources["StrExito"]?.ToString() ?? "Success";
                MessageBox.Show(msg, title, MessageBoxButton.OK, MessageBoxImage.Information);
                NewPasswordBox.Password = "";
            }
            else
            {
                string msg = Application.Current?.Resources["StrContrasenaError"]?.ToString() ?? "Error updating password. You may need to log in again.";
                string title = Application.Current?.Resources["StrError"]?.ToString() ?? "Error";
                MessageBox.Show(msg, title, MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void SignOut_Click(object sender, RoutedEventArgs e)
        {
            await _authService.LogoutAsync();
            // Redirect to Login is handled by main window if auth state changes, 
            // but for now simple reload or app restart
            
            var mainWindow = Window.GetWindow(this) as MainWindow;
            if (mainWindow != null)
            {
                 // Create new login view
                 mainWindow.ActiveContent.Content = new LoginView();
                 mainWindow.SidebarBorder.Visibility = Visibility.Collapsed;
            }
        }
    }
}
