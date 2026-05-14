using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Jovi3DReview.Services;
using System;
using System.Threading.Tasks;

namespace Jovi3DReview.ViewModels
{
    public partial class LoginViewModel : ObservableObject
    {
        private readonly IAuthService _authService;

        [ObservableProperty]
        private string _email = string.Empty;

        [ObservableProperty]
        private string _password = string.Empty;

        [ObservableProperty]
        private string _errorMessage = string.Empty;

        [ObservableProperty]
        private bool _isErrorVisible;

        [ObservableProperty]
        private bool _isLoading;

        [ObservableProperty]
        [NotifyCanExecuteChangedFor(nameof(LoginCommand))]
        private bool _isButtonEnabled = true;

        public LoginViewModel() : this(AuthService.Instance)
        {
        }

        public LoginViewModel(IAuthService authService)
        {
            _authService = authService;
        }

        [RelayCommand(CanExecute = nameof(CanLogin))]
        private async Task LoginAsync(Func<Task> onSuccess)
        {
            if (string.IsNullOrWhiteSpace(Email) || string.IsNullOrWhiteSpace(Password))
            {
                ShowError("Por favor, introduce email y contraseña.");
                return;
            }

            IsLoading = true;
            IsErrorVisible = false;
            IsButtonEnabled = false;

            try
            {
                var token = await _authService.LoginAsync(Email, Password);
                if (!string.IsNullOrEmpty(token))
                {
                    await onSuccess();
                }
                else
                {
                    ShowError("Error desconocido al iniciar sesión.");
                }
            }
            catch (Exception ex)
            {
                HandleLoginException(ex);
            }
            finally
            {
                IsLoading = false;
                IsButtonEnabled = true;
            }
        }

        private bool CanLogin() => !IsLoading;

        private void ShowError(string message)
        {
            ErrorMessage = message;
            IsErrorVisible = true;
        }

        private void HandleLoginException(Exception ex)
        {
            string msg = ex.Message.ToLower();
            if (msg.Contains("invalid_login_credentials") || msg.Contains("user_not_found") || msg.Contains("wrong_password") || msg.Contains("invalid-email"))
            {
                ShowError("Correo o contraseña incorrectos.");
            }
            else if (msg.Contains("network") || msg.Contains("http"))
            {
                ShowError("Error de conexión. Revisa tu internet.");
            }
            else
            {
                ShowError("Error al iniciar sesión. Inténtalo de nuevo.");
            }
        }
    }
}
