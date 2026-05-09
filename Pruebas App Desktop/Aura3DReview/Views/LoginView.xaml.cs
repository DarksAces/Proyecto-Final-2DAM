using System.Windows;
using System.Windows.Controls;

namespace Jovi3DReview.Views
{
    public partial class LoginView : UserControl
    {
        private readonly Services.AuthService _authService;

        public LoginView()
        {
            InitializeComponent();
            _authService = Services.AuthService.Instance;
        }

        private async void Login_Click(object sender, RoutedEventArgs e)
        {
             // 1. Validation
             string email = txtEmail.Text;
             string password = txtPassword.Password;

             if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
             {
                 MessageBox.Show("Por favor ingresa correo y contraseña.", "Aviso", MessageBoxButton.OK, MessageBoxImage.Warning);
                 return;
             }

             // 2. UI State
             LoadingBar.Visibility = Visibility.Visible;
             IsEnabled = false;

             // 3. Auth Call
             var token = await _authService.LoginAsync(email, password);

             // 4. Result Handling
             LoadingBar.Visibility = Visibility.Collapsed;
             IsEnabled = true;

             if (!string.IsNullOrEmpty(token))
             {
                 // Check Admin Role
                 var firebaseService = new Services.FirebaseService();
                 var userId = _authService.GetCurrentUserId();
                 var user = await firebaseService.GetUserAsync(userId);

                 if (user != null && user.Admin?.ToLower() == "si")
                 {
                     // Success
                     var mainWindow = Window.GetWindow(this) as MainWindow; 
                     if (mainWindow != null)
                     {
                         mainWindow.ShowSidebar();
                         mainWindow.NavigateToDashboard();
                     }
                 }
                 else
                 {
                     MessageBox.Show("Acceso denegado. No tienes permisos de administrador.", "Error de Permisos", MessageBoxButton.OK, MessageBoxImage.Error);
                     await _authService.LogoutAsync();
                 }
             }
             else
             {
                 MessageBox.Show("Error al iniciar sesión. Verifica tus credenciales o la configuración de Firebase.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
             }
        }
    }
}
