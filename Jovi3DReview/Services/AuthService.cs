using System;
using System.Threading.Tasks;
using Firebase.Auth;
using Firebase.Auth.Providers;

namespace Jovi3DReview.Services
{
    public class AuthService : IAuthService
    {
        // TODO: Replace with your actual Firebase Web API Key from the Firebase Console -> Project Settings
        // API Key from user provided configuration (DefaultFirebaseOptions.windows/web)
        private const string ApiKey = "AIzaSyBNnSU-b7UgScNSyOb9dTezuHEoJ36z_9I"; 
        
        private readonly FirebaseAuthClient _authClient;
        private UserCredential? _userCredential;

        public static AuthService Instance { get; } = new AuthService();

        private AuthService()
        {
            var config = new FirebaseAuthConfig
            {
                ApiKey = ApiKey,
                AuthDomain = "jovi-45c79.firebaseapp.com",
                Providers = new FirebaseAuthProvider[]
                {
                    new EmailProvider()
                }
            };

            _authClient = new FirebaseAuthClient(config);
        }

        public async Task<string?> LoginAsync(string email, string password)
        {
            try
            {
                if (string.IsNullOrEmpty(email) || string.IsNullOrEmpty(password))
                    return null;

                // Sign in
                _userCredential = await _authClient.SignInWithEmailAndPasswordAsync(email, password);
                
                // Return the ID token (or LocalId depending on valid needs)
                return await _userCredential.User.GetIdTokenAsync();
            }
            catch (Exception ex)
            {
                // Log exception in a real app
                System.Diagnostics.Debug.WriteLine($"Login failed: {ex.Message}");
                return null;
            }
        }

        public Task<bool> LogoutAsync()
        {
            _authClient.SignOut();
            _userCredential = null;
            return Task.FromResult(true);
        }

        public string GetCurrentUserId()
        {
            return _userCredential?.User?.Uid ?? string.Empty;
        }

        public async Task<string?> GetIdTokenAsync()
        {
            if (_userCredential?.User == null) return null;
            return await _userCredential.User.GetIdTokenAsync(false);
        }

        public async Task<bool> ChangePasswordAsync(string newPassword)
        {
            try
            {
                if (_userCredential?.User == null) return false;
                await _userCredential.User.ChangePasswordAsync(newPassword);
                return true;
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Change Password failed: {ex.Message}");
                return false;
            }
        }
    }
}
