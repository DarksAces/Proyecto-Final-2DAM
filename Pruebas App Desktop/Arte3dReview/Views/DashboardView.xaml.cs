using System.Windows;
using System.Windows.Controls;
using Jovi3DReview.Models;
using Jovi3DReview.ViewModels;

namespace Jovi3DReview.Views
{
    public partial class DashboardView : UserControl
    {
        public DashboardViewModel ViewModel { get; }

        public DashboardView()
        {
            InitializeComponent();
            ViewModel = new DashboardViewModel();
            this.DataContext = ViewModel;

            this.Loaded += DashboardView_Loaded;
        }

        private async void DashboardView_Loaded(object sender, RoutedEventArgs e)
        {
             await ViewModel.LoadDataAsync();
        }

        private void Filter_Click(object sender, RoutedEventArgs e)
        {
            if (sender is Button btn)
            {
                string filter = btn.Content.ToString() ?? "Todos";
                ViewModel.ChangeFilter(filter);
                
                // Manual style update because triggers are complex for this specific case
                FilterPending.Style = (Style)FindResource(filter == "Pendientes" ? "FilterPillButtonActive" : "FilterPillButton");
                FilterApproved.Style = (Style)FindResource(filter == "Aprobados" ? "FilterPillButtonActive" : "FilterPillButton");
                FilterDenied.Style = (Style)FindResource(filter == "Rechazados" ? "FilterPillButtonActive" : "FilterPillButton");
                FilterAll.Style = (Style)FindResource(filter == "Todos" ? "FilterPillButtonActive" : "FilterPillButton");
            }
        }

        private void Card_Click(object sender, RoutedEventArgs e)
        {
            if (sender is FrameworkElement element && element.DataContext is Model3D model)
            {
                var mainWindow = Window.GetWindow(this) as MainWindow;
                mainWindow?.NavigateToDetails(model);
            }
        }

        private async void Approve_Click(object sender, RoutedEventArgs e)
        {
            if (sender is FrameworkElement element && element.DataContext is Model3D model)
            {
                await ViewModel.ApproveModelCommand.ExecuteAsync(model);
            }
        }

        private async void Reject_Click(object sender, RoutedEventArgs e)
        {
            if (sender is FrameworkElement element && element.DataContext is Model3D model)
            {
                var dialog = new RejectionDialog();
                dialog.Owner = Window.GetWindow(this);
                
                if (dialog.ShowDialog() == true)
                {
                    string reason = dialog.RejectionReason;
                    await ViewModel.RejectModelCommand.ExecuteAsync((model, reason));
                }
            }
        }

        private void Notification_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("No tienes nuevas notificaciones.", "Notificaciones", MessageBoxButton.OK, MessageBoxImage.Information);
        }

        private void Help_Click(object sender, RoutedEventArgs e)
        {
            var mainWindow = Window.GetWindow(this) as MainWindow;
            if (mainWindow != null)
            {
                 mainWindow.ActiveContent.Content = new HelpView();
            }
        }
    }
}
