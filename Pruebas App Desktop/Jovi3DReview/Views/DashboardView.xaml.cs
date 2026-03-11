using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Collections.ObjectModel;
using System.Linq;
using Jovi3DReview.Models;

namespace Jovi3DReview.Views
{
    public partial class DashboardView : UserControl
    {
        public ObservableCollection<Model3D> Models { get; set; }
        private List<Model3D> _allModels = new List<Model3D>();
        private readonly Services.IFirebaseService _firebaseService;
        private string _currentFilter = "Pendientes"; // Pendientes, Aprobados, Rechazados, Todos

        public DashboardView()
        {
            InitializeComponent();
            _firebaseService = new Services.FirebaseService();
            Models = new ObservableCollection<Model3D>();

            // Setup Data Context
            this.DataContext = this;
            if (this.FindName("ModelsList") is ItemsControl list)
            {
                list.ItemsSource = Models;
            }

            this.Loaded += DashboardView_Loaded;
        }

        private async void DashboardView_Loaded(object sender, RoutedEventArgs e)
        {
             await LoadData();
        }

        private async System.Threading.Tasks.Task LoadData()
        {
             try
             {
                 var data = await _firebaseService.GetModelsAsync();
                 _allModels = data;
                  ApplyFilter(clickedButton: null); // Default filter
             }
             catch (System.Exception ex)
             {
                 MessageBox.Show($"Error loading data: {ex.Message}");
             }
        }

        public ObservableCollection<Model3D> PendingModels => Models; // Alias

        private void Filter_Click(object sender, RoutedEventArgs e)
        {
            if (sender is Button btn)
            {
                _currentFilter = btn.Content.ToString();
                ApplyFilter(btn);
            }
        }

        private void ApplyFilter(Button? clickedButton)
        {
            // Reset styles
            if (clickedButton != null)
            {
                FilterPending.Style = (Style)FindResource("FilterPillButton");
                FilterApproved.Style = (Style)FindResource("FilterPillButton");
                FilterDenied.Style = (Style)FindResource("FilterPillButton");
                FilterAll.Style = (Style)FindResource("FilterPillButton");

                clickedButton.Style = (Style)FindResource("FilterPillButtonActive");
            }

            Models.Clear();
            IEnumerable<Model3D> filtered = _allModels;

            switch (_currentFilter)
            {
                case "Pendientes":
                    filtered = _allModels.Where(m => m.Status == "pending_review");
                    break;
                case "Aprobados":
                    filtered = _allModels.Where(m => m.Status == "approved");
                    break;
                case "Rechazados":
                    filtered = _allModels.Where(m => m.Status == "denied");
                    break;
                case "Todos":
                    break;
            }

            foreach (var item in filtered)
            {
                Models.Add(item);
            }

            UpdateCounters();
        }

        private void UpdateCounters()
        {
            int count = Models.Count;
            int totalPending = _allModels.Count(m => m.Status == "pending_review");
            
            // Text: "Hay 12 modelos escolares esperando tu aprobación hoy."
            if (HeaderCountText != null)
            {
                HeaderCountText.Text = $"Hay {totalPending} modelos escolares esperando tu aprobación hoy.";
            }

            // PaginationText update
            if (PaginationText != null)
            {
                 PaginationText.Text = $"Mostrando {count} modelos ({_currentFilter})";
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
                if (model.Id == null) return;

                var success = await _firebaseService.ApproveModelAsync(model.Id);
                if (success)
                {
                    // Update local model status
                    model.Status = "approved";
                    model.ReviewedAt = System.DateTime.UtcNow;
                    
                    // Refresh current view
                    ApplyFilter(clickedButton: null); // Re-apply filter to remove/move item
                    
                    // Force UI update if needed (ObservableCollection handles add/remove, but property change needs INotifyPropertyChanged on Model)
                    // Since we re-populate Models in ApplyFilter, it should update.
                }
                else
                {
                    MessageBox.Show("Error approving model.");
                }
            }
        }

        private async void Reject_Click(object sender, RoutedEventArgs e)
        {
            if (sender is FrameworkElement element && element.DataContext is Model3D model)
            {
                if (model.Id == null) return;

                var dialog = new RejectionDialog();
                dialog.Owner = Window.GetWindow(this);
                
                if (dialog.ShowDialog() == true)
                {
                    string reason = dialog.RejectionReason;
                    var success = await _firebaseService.RejectModelAsync(model.Id, reason);
                    
                    if (success)
                    {
                        model.Status = "denied";
                        model.ReviewedAt = System.DateTime.UtcNow;
                        ApplyFilter(clickedButton: null);
                    }
                    else
                    {
                        MessageBox.Show("Error rejecting model.");
                    }
                }
            }
        }
    }
}
