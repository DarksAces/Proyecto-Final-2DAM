using System.Windows;

namespace Jovi3DReview.Views
{
    public partial class RejectionDialog : Window
    {
        public RejectionDialog()
        {
            InitializeComponent();
        }

        public string RejectionReason { get; private set; } = string.Empty;

        private void Cancel_Click(object sender, RoutedEventArgs e)
        {
            this.DialogResult = false;
            this.Close();
        }

        private void Confirm_Click(object sender, RoutedEventArgs e)
        {
            // Gather input
            string reason = (ReasonCombo.SelectedItem as System.Windows.Controls.ComboBoxItem)?.Content?.ToString() ?? "Otro";
            string comments = CommentsBox.Text;

            RejectionReason = string.IsNullOrWhiteSpace(comments) ? reason : $"{reason}: {comments}";

            this.DialogResult = true;
            this.Close();
        }
    }
}
