using System.Linq;
using System.Windows.Controls;
using Jovi3DReview.Services;

namespace Jovi3DReview.Views
{
    public partial class ReportsView : UserControl
    {
        private readonly FirebaseService _firebaseService;

        public ReportsView()
        {
            InitializeComponent();
            _firebaseService = new FirebaseService();
            Loaded += ReportsView_Loaded;
        }

        private async void ReportsView_Loaded(object sender, System.Windows.RoutedEventArgs e)
        {
            var models = await _firebaseService.GetModelsAsync();
            
            TotalCount.Text = models.Count.ToString();
            ApprovedCount.Text = models.Count(m => m.Status == "approved").ToString();
            RejectedCount.Text = models.Count(m => m.Status == "denied").ToString();
            PendingCount.Text = models.Count(m => m.Status == "pending_review").ToString();
        }
    }
}
