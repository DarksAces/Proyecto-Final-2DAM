using System.Collections.Generic;
using System.Threading.Tasks;
using Jovi3DReview.Models;

namespace Jovi3DReview.Services
{
    public interface IFirebaseService
    {
        Task<List<Model3D>> GetModelsAsync();
        Task<bool> ApproveModelAsync(Model3D model);
        Task<bool> RejectModelAsync(Model3D model, string reason);
        Task<User?> GetUserAsync(string userId);
        Task<string?> GetUserNameAsync(string userId);
        Task<List<User>> GetAllUsersAsync();
        Task<bool> UpdateUserAdminAsync(string userId, bool isAdmin);
    }
}
