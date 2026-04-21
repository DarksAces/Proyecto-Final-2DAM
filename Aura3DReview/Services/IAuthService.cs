using System.Threading.Tasks;

namespace Jovi3DReview.Services
{
    public interface IAuthService
    {
        Task<string?> LoginAsync(string email, string password);
        Task<bool> LogoutAsync();
        string GetCurrentUserId();
        Task<string?> GetIdTokenAsync();
        Task<bool> ChangePasswordAsync(string newPassword);
    }
}
