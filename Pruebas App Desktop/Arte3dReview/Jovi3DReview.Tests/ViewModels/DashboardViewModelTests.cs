using Jovi3DReview.Models;
using Jovi3DReview.Services;
using Jovi3DReview.ViewModels;
using Moq;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;

namespace Jovi3DReview.Tests.ViewModels
{
    public class DashboardViewModelTests
    {
        private readonly Mock<IFirebaseService> _firebaseServiceMock;
        private readonly DashboardViewModel _viewModel;

        public DashboardViewModelTests()
        {
            _firebaseServiceMock = new Mock<IFirebaseService>();
            _viewModel = new DashboardViewModel(_firebaseServiceMock.Object);
        }

        [Fact]
        public async Task LoadDataAsync_ShouldPopulateModels_AndSetCounters()
        {
            // Arrange
            var testModels = new List<Model3D>
            {
                new Model3D { Id = "1", Status = "pending_review" },
                new Model3D { Id = "2", Status = "approved" },
                new Model3D { Id = "3", Status = "pending_review" }
            };
            _firebaseServiceMock.Setup(s => s.GetModelsAsync()).ReturnsAsync(testModels);

            // Act
            await _viewModel.LoadDataAsync();

            // Assert
            Assert.Equal(2, _viewModel.Models.Count); // Default filter is "Pending"
            Assert.Contains("2 obras esperando", _viewModel.HeaderCountText);
            Assert.Contains("Mostrando 2 obras", _viewModel.PaginationText);
        }

        [Fact]
        public async Task ChangeFilter_ShouldUpdateDisplayedModels()
        {
            // Arrange
            var testModels = new List<Model3D>
            {
                new Model3D { Id = "1", Status = "pending_review" },
                new Model3D { Id = "2", Status = "approved" }
            };
            _firebaseServiceMock.Setup(s => s.GetModelsAsync()).ReturnsAsync(testModels);
            await _viewModel.LoadDataAsync();

            // Act - Change to Approved
            _viewModel.ChangeFilter("Approved");

            // Assert
            Assert.Single(_viewModel.Models);
            Assert.Equal("approved", _viewModel.Models[0].Status);

            // Act - Change to All
            _viewModel.ChangeFilter("All");
            Assert.Equal(2, _viewModel.Models.Count);
        }

        [Fact]
        public async Task ApproveModelAsync_ShouldUpdateStatus_AndRefreshFilter()
        {
            // Arrange
            var model = new Model3D { Id = "1", Status = "pending_review" };
            var testModels = new List<Model3D> { model };
            _firebaseServiceMock.Setup(s => s.GetModelsAsync()).ReturnsAsync(testModels);
            _firebaseServiceMock.Setup(s => s.ApproveModelAsync(model)).ReturnsAsync(true);
            
            await _viewModel.LoadDataAsync();

            // Act
            await _viewModel.ApproveModelAsync(model);

            // Assert
            Assert.Equal("approved", model.Status);
            Assert.Empty(_viewModel.Models); // Since filter is still "Pending", it should disappear
            Assert.Contains("0 obras esperando", _viewModel.HeaderCountText);
        }

        [Fact]
        public async Task RejectModelAsync_ShouldUpdateStatus_AndSetReason()
        {
            // Arrange
            var model = new Model3D { Id = "1", Status = "pending_review" };
            var testModels = new List<Model3D> { model };
            _firebaseServiceMock.Setup(s => s.GetModelsAsync()).ReturnsAsync(testModels);
            _firebaseServiceMock.Setup(s => s.RejectModelAsync(model, "Too blurry")).ReturnsAsync(true);
            
            await _viewModel.LoadDataAsync();

            // Act
            await _viewModel.RejectModelCommand.ExecuteAsync((model, "Too blurry"));

            // Assert
            Assert.Equal("denied", model.Status);
            _firebaseServiceMock.Verify(s => s.RejectModelAsync(model, "Too blurry"), Times.Once);
        }

        [Fact]
        public async Task LoadDataAsync_ShouldHandleNullDataGracefully()
        {
            // Arrange
            _firebaseServiceMock.Setup(s => s.GetModelsAsync()).ReturnsAsync((List<Model3D>)null!);

            // Act
            await _viewModel.LoadDataAsync();

            // Assert
            Assert.Empty(_viewModel.Models);
            Assert.Contains("0 obras", _viewModel.HeaderCountText);
        }
    }
}
