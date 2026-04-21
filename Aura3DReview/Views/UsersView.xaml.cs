using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using Aura3DReview.Models;
using Aura3DReview.Services;

namespace Aura3DReview.Views
{
    public partial class UsersView : UserControl
    {
        private readonly FirebaseService _firebaseService;
        private List<User> _users = new List<User>();

        public UsersView()
        {
            InitializeComponent();
            _firebaseService = new FirebaseService();
            this.Loaded += UsersView_Loaded;
        }

        private async void UsersView_Loaded(object sender, RoutedEventArgs e)
        {
            await LoadUsers();
        }

        private async System.Threading.Tasks.Task LoadUsers()
        {
            try
            {
                var users = await _firebaseService.GetAllUsersAsync();
                
                // Sort: Not Admins first (so we can see who needs promotion), or just by Name
                // Let's sort by Name
                users.Sort((a, b) => string.Compare(a.Name, b.Name));

                _users = users;
                UsersGrid.ItemsSource = _users;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error loading users: {ex.Message}");
            }
        }

        private async void MakeAdmin_Click(object sender, RoutedEventArgs e)
        {
            if (sender is FrameworkElement element && element.DataContext is User user)
            {
                var result = MessageBox.Show(
                    $"¿Estás seguro que quieres hacer a '{user.Name}' administrador?",
                    "Confirmar Permisos",
                    MessageBoxButton.YesNo,
                    MessageBoxImage.Question);

                if (result == MessageBoxResult.Yes)
                {
                    if (user.Id == null) return;

                    bool success = await _firebaseService.UpdateUserAdminAsync(user.Id, true);
                    if (success)
                    {
                        MessageBox.Show($"¡{user.Name} ahora es administrador!", "Éxito", MessageBoxButton.OK, MessageBoxImage.Information);
                        await LoadUsers(); // Refresh list
                    }
                    else
                    {
                        MessageBox.Show("Error al actualizar permisos.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                    }
                }
            }
        }
    }
}
