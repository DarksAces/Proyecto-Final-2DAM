using System.Collections.Generic;
using System.Threading.Tasks;
using Jovi3DReview.Models;

namespace Jovi3DReview.Services
{
    public interface IFirebaseService
    {
        Task<List<Model3D>> GetModelsAsync();
        Task<bool> ApproveModelAsync(string modelId);
        Task<bool> RejectModelAsync(string modelId, string reason);
        Task<Model3D> GetModelDetailsAsync(string modelId);
        Task<User?> GetUserAsync(string userId);
    }
}
