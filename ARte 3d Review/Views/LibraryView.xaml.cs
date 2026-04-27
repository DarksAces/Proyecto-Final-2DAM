using System.Collections.Generic;
using System.Linq;
using System.Windows.Controls;
using Jovi3DReview.Models;
using Jovi3DReview.Services;

namespace Jovi3DReview.Views
{
    public partial class LibraryView : UserControl
    {
        private readonly FirebaseService _firebaseService;

        public LibraryView()
        {
            InitializeComponent();
            _firebaseService = new FirebaseService();
            Loaded += LibraryView_Loaded;
        }

        private async void LibraryView_Loaded(object sender, System.Windows.RoutedEventArgs e)
        {
            var allModels = await _firebaseService.GetModelsAsync();
            // Filter only approved
            var approved = allModels.Where(m => m.Status == "approved").ToList();
            ModelsList.ItemsSource = approved;
        }
    }
}
