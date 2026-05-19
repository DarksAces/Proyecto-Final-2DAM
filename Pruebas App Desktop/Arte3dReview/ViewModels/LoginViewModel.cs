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
                string msg = System.Windows.Application.Current?.Resources["StrLoginCredencialesVacias"]?.ToString() ?? "Please enter email and password.";
                ShowError(msg);
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
                    string msg = System.Windows.Application.Current?.Resources["StrLoginErrorDesconocido"]?.ToString() ?? "Unknown error during login.";
                    ShowError(msg);
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
                string res = System.Windows.Application.Current?.Resources["StrLoginCredencialesIncorrectas"]?.ToString() ?? "Incorrect email or password.";
                ShowError(res);
            }
            else if (msg.Contains("network") || msg.Contains("http"))
            {
                string res = System.Windows.Application.Current?.Resources["StrLoginErrorConexion"]?.ToString() ?? "Connection error. Check your internet.";
                ShowError(res);
            }
            else
            {
                string res = System.Windows.Application.Current?.Resources["StrLoginErrorInicio"]?.ToString() ?? "Error logging in. Try again.";
                ShowError(res);
            }
        }
    }
}
