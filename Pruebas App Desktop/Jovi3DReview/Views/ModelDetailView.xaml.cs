using System.Windows;
using System.Windows.Controls;

namespace Jovi3DReview.Views
{
    public partial class ModelDetailView : UserControl
    {
        public ModelDetailView()
        {
            InitializeComponent();
        }

        private void Accept_Click(object sender, RoutedEventArgs e)
        {
            MessageBox.Show("Modelo Aceptado (Simulación)", "Jovi 3D");
            // Logic to update status in Firebase would go here
        }

        private void Reject_Click(object sender, RoutedEventArgs e)
        {
            // Open Rejection Dialog
            var dialog = new RejectionDialog();
            dialog.ShowDialog();
        }
    }
}
