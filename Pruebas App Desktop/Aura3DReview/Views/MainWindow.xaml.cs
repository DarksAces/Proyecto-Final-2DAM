using System.Windows;
using System.Windows.Input;

namespace Jovi3DReview.Views
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

        private void Dashboard_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent != null)
                NavigateToDashboard();
        }

        private void Biblioteca_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent == null) return;
            // Placeholder view - show message for now
            ActiveContent.Content = new System.Windows.Controls.TextBlock 
            { 
                Text = "Biblioteca - Vista en desarrollo", 
                FontSize = 24, 
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center
            };
        }

        private void Usuarios_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent != null)
                NavigateToUsers();
        }

        private void Reportes_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent == null) return;
            // Placeholder view - show message for now
            ActiveContent.Content = new System.Windows.Controls.TextBlock 
            { 
                Text = "Reportes - Vista en desarrollo", 
                FontSize = 24, 
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center
            };
        }

        private void Configuracion_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent == null) return;
            // Placeholder view - show message for now
            ActiveContent.Content = new System.Windows.Controls.TextBlock 
            { 
                Text = "Configuración - Vista en desarrollo", 
                FontSize = 24, 
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center
            };
        }

        private void Ayuda_Checked(object sender, RoutedEventArgs e)
        {
            if (ActiveContent == null) return;
            // Placeholder view - show message for now
            ActiveContent.Content = new System.Windows.Controls.TextBlock 
            { 
                Text = "Ayuda - Vista en desarrollo", 
                FontSize = 24, 
                HorizontalAlignment = HorizontalAlignment.Center,
                VerticalAlignment = VerticalAlignment.Center
            };
        }

        public void NavigateToDashboard()
        {
            if (ActiveContent == null) return;
            System.Console.WriteLine("Navigating to Dashboard...");
            ActiveContent.Content = new DashboardView();
        }

        public void NavigateToDetails(object model)
        {
            if (ActiveContent == null) return;
            // For now just new instance, can pass data later
            ActiveContent.Content = new ModelDetailView();
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