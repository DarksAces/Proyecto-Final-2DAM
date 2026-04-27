using System.Windows;
using System.Windows.Controls;
using Jovi3DReview.Models;
using Jovi3DReview.Services;

namespace Jovi3DReview.Views
{
    public partial class ModelDetailView : UserControl
    {
        private Model3D _model;
        private readonly FirebaseService _firebaseService;

        public ModelDetailView()
        {
            InitializeComponent();
            _firebaseService = new FirebaseService();
        }

        public ModelDetailView(Model3D model) : this()
        {
            _model = model;
            this.DataContext = _model;
        }

        private async void Accept_Click(object sender, RoutedEventArgs e)
        {
            if (_model == null || _model.Id == null) return;

            var success = await _firebaseService.ApproveModelAsync(_model.Id);
            if (success)
            {
                MessageBox.Show("Modelo aprobado correctamente.", "Jovi 3D", MessageBoxButton.OK, MessageBoxImage.Information);
                // Navigate back to Dashboard or update UI
                var mainWindow = Window.GetWindow(this) as MainWindow;
                mainWindow?.NavigateToDashboard();
            }
            else
            {
                MessageBox.Show("Error al aprobar el modelo.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void Reject_Click(object sender, RoutedEventArgs e)
        {
            if (_model == null || _model.Id == null) return;

            var dialog = new RejectionDialog();
            dialog.Owner = Window.GetWindow(this);

            if (dialog.ShowDialog() == true)
            {
                string reason = dialog.RejectionReason;
                var success = await _firebaseService.RejectModelAsync(_model.Id, reason);

                if (success)
                {
                    MessageBox.Show("Modelo rechazado.", "Jovi 3D", MessageBoxButton.OK, MessageBoxImage.Information);
                    var mainWindow = Window.GetWindow(this) as MainWindow;
                    mainWindow?.NavigateToDashboard();
                }
                else
                {
                    MessageBox.Show("Error al rechazar el modelo.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }
    }
}
