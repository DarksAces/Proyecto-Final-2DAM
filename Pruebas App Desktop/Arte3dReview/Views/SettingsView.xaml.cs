using System;
using System.Windows;
using System.Windows.Controls;
using Jovi3DReview.ViewModels;

namespace Jovi3DReview.Views
{
    public partial class SettingsView : UserControl
    {
        public SettingsViewModel ViewModel { get; }

        public SettingsView()
        {
            InitializeComponent();
            ViewModel = new SettingsViewModel();
            this.DataContext = ViewModel;
        }
    }
}
