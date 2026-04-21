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
                        UserNameText.Text = user.Name ?? "Usuario";
                        UserEmailText.Text = user.Email ?? "Sin email";
                        UserRoleText.Text = (user.IsAdmin ? "ADMINISTRADOR" : user.Role ?? "INVITADO").ToUpper();
                    }
                }
                catch
                {
                    UserNameText.Text = "Error al cargar";
                }
            }
        }

        private async void ChangePassword_Click(object sender, RoutedEventArgs e)
        {
            string newPass = NewPasswordBox.Password;
            if (string.IsNullOrWhiteSpace(newPass))
            {
                MessageBox.Show("Ingresa una nueva contraseña.", "Error", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            if (newPass.Length < 6)
            {
                MessageBox.Show("La contraseña debe tener al menos 6 caracteres.", "Error", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            bool success = await _authService.ChangePasswordAsync(newPass);
            if (success)
            {
                MessageBox.Show("Contraseña actualizada correctamente.", "Éxito", MessageBoxButton.OK, MessageBoxImage.Information);
                NewPasswordBox.Password = "";
            }
            else
            {
                MessageBox.Show("Error al actualizar la contraseña. Es posible que debas volver a iniciar sesión.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
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
