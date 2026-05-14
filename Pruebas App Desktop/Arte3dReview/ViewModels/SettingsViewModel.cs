using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Jovi3DReview.Services;
using System;
using System.Threading.Tasks;
using System.Windows;

namespace Jovi3DReview.ViewModels
{
    public partial class SettingsViewModel : ObservableObject
    {
        private readonly IAuthService _authService;

        [ObservableProperty]
        private string _newPassword = string.Empty;

        [ObservableProperty]
        private string _confirmPassword = string.Empty;

        [ObservableProperty]
        private bool _isDarkMode;

        [ObservableProperty]
        private string _selectedLanguage = "Español";

        [ObservableProperty]
        private bool _isChangingPassword;

        partial void OnIsDarkModeChanged(bool value)
        {
            ThemeService.Instance.SetDarkMode(value);
        }

        partial void OnSelectedLanguageChanged(string value)
        {
            string code = value == "English" ? "en" : "es";
            ThemeService.Instance.SetLanguage(code);
        }

        [ObservableProperty]
        private bool _notificationsEnabled = true;

        [ObservableProperty]
        private bool _autoSaveComments = true;

        public SettingsViewModel() : this(AuthService.Instance)
        {
        }

        public SettingsViewModel(IAuthService authService)
        {
            _authService = authService;
            
            // Initialize from persisted settings
            var settings = ConfigService.Instance.Settings;
            _isDarkMode = settings.IsDarkMode;
            _selectedLanguage = settings.Language == "en" ? "English" : "Español";
        }

        [RelayCommand]
        private async Task ChangePasswordAsync()
        {
            if (string.IsNullOrWhiteSpace(NewPassword) || NewPassword.Length < 6)
            {
                MessageBox.Show("La contraseña debe tener al menos 6 caracteres.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            if (NewPassword != ConfirmPassword)
            {
                MessageBox.Show("Las contraseñas no coinciden.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                return;
            }

            IsChangingPassword = true;
            try
            {
                var success = await _authService.ChangePasswordAsync(NewPassword);
                if (success)
                {
                    MessageBox.Show("Contraseña cambiada con éxito.", "Configuración", MessageBoxButton.OK, MessageBoxImage.Information);
                    NewPassword = string.Empty;
                    ConfirmPassword = string.Empty;
                }
                else
                {
                    MessageBox.Show("Error al cambiar la contraseña. Asegúrate de haber iniciado sesión recientemente.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
            finally
            {
                IsChangingPassword = false;
            }
        }

        [RelayCommand]
        private void CloseApplication()
        {
            var title = Application.Current.Resources["StrCerrarApp"] as string ?? "Cerrar Aplicación";
            var result = MessageBox.Show("¿Estás seguro de que quieres cerrar la aplicación?", title, MessageBoxButton.YesNo, MessageBoxImage.Question);
            if (result == MessageBoxResult.Yes)
            {
                Application.Current.Shutdown();
            }
        }

        [RelayCommand]
        private async Task ClearCacheAsync()
        {
             // Simulate clearing cache
             await Task.Delay(1000);
             MessageBox.Show("Caché de modelos 3D limpiada correctamente.", "Mantenimiento", MessageBoxButton.OK, MessageBoxImage.Information);
        }
    }
}
