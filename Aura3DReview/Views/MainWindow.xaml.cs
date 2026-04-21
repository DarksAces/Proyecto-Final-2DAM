using System.Windows;
using System.Windows.Input;
using Aura3DReview.Models;

namespace Aura3DReview.Views
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            ActiveContent.Content = new LoginView();
        }

        private void Profile_Click(object sender, MouseButtonEventArgs e)
        {
            NavigateToProfile();
        }

        public void ShowSidebar()
        {
            if (SidebarBorder != null)
                SidebarBorder.Visibility = Visibility.Visible;
        }

        public async void LoadUserProfile()
        {
            var auth = Services.AuthService.Instance;
            var userId = auth.GetCurrentUserId();
            if (!string.IsNullOrEmpty(userId))
            {
                var firebase = new Services.FirebaseService();
                var user = await firebase.GetUserAsync(userId);
                if (user != null)
                {
                    CurrentUserName.Text = user.Name ?? "Usuario";
                    CurrentUserRole.Text = (user.IsAdmin ? "Admin" : user.Role ?? "User");
                }
            }
        }

        private void Dashboard_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent != null)
                NavigateToDashboard();
        }

        private void Biblioteca_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent == null) return;
            ActiveContent.Content = new LibraryView();
        }

        private void Usuarios_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent != null)
                NavigateToUsers();
        }

        private void Reportes_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent == null) return;
            ActiveContent.Content = new ReportsView();
        }

        private void Configuracion_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent == null) return;
            ActiveContent.Content = new SettingsView();
        }

        private void Ayuda_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent == null) return;
            ActiveContent.Content = new HelpView();
        }

        public void NavigateToDashboard()
        {
            if (ActiveContent == null) return;
            ActiveContent.Content = new DashboardView();
        }

        public void NavigateToDetails(object model)
        {
            if (ActiveContent == null) return;
            
            if (model is Models.Model3D model3D)
            {
                ActiveContent.Content = new ModelDetailView(model3D);
            }
        }

        public void NavigateToProfile()
        {
            if (ActiveContent == null) return;
            ActiveContent.Content = new ProfileView();
        }

        public void NavigateToUsers()
        {
            if (ActiveContent == null) return;
            ActiveContent.Content = new UsersView();
        }
    }
}