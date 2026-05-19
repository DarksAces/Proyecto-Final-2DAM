using Jovi3DReview.Services;
using Jovi3DReview.ViewModels;
using Moq;
using System;
using System.Threading.Tasks;
using Xunit;

namespace Jovi3DReview.Tests.ViewModels
{
    public class LoginViewModelTests
    {
        private readonly Mock<IAuthService> _authServiceMock;
        private readonly LoginViewModel _viewModel;

        public LoginViewModelTests()
        {
            _authServiceMock = new Mock<IAuthService>();
            _viewModel = new LoginViewModel(_authServiceMock.Object);
        }

        [Fact]
        public async Task LoginCommand_ShouldShowError_WhenEmailOrPasswordIsEmpty()
        {
            // Arrange
            _viewModel.Email = "";
            _viewModel.Password = "";

            // Act
            await _viewModel.LoginCommand.ExecuteAsync(null);

            // Assert
            Assert.True(_viewModel.IsErrorVisible);
            Assert.Equal("Please enter email and password.", _viewModel.ErrorMessage);
        }

        [Fact]
        public async Task LoginCommand_ShouldCallOnSuccess_WhenLoginIsSuccessful()
        {
            // Arrange
            _viewModel.Email = "test@example.com";
            _viewModel.Password = "password123";
            _authServiceMock.Setup(s => s.LoginAsync(It.IsAny<string>(), It.IsAny<string>()))
                            .ReturnsAsync("valid_token");

            bool successCalled = false;
            Func<Task> onSuccess = () => { successCalled = true; return Task.CompletedTask; };

            // Act
            await _viewModel.LoginCommand.ExecuteAsync(onSuccess);

            // Assert
            Assert.True(successCalled);
            Assert.False(_viewModel.IsErrorVisible);
        }

        [Fact]
        public async Task LoginCommand_ShouldShowError_WhenCredentialsAreInvalid()
        {
            // Arrange
            _viewModel.Email = "wrong@example.com";
            _viewModel.Password = "wrong";
            _authServiceMock.Setup(s => s.LoginAsync(It.IsAny<string>(), It.IsAny<string>()))
                            .ThrowsAsync(new Exception("INVALID_LOGIN_CREDENTIALS"));

            // Act
            await _viewModel.LoginCommand.ExecuteAsync(null);

            // Assert
            Assert.True(_viewModel.IsErrorVisible);
            Assert.Equal("Incorrect email or password.", _viewModel.ErrorMessage);
        }

        [Fact]
        public async Task LoginCommand_ShouldShowNetworkError_WhenNetworkFails()
        {
            // Arrange
            _viewModel.Email = "test@example.com";
            _viewModel.Password = "password";
            _authServiceMock.Setup(s => s.LoginAsync(It.IsAny<string>(), It.IsAny<string>()))
                            .ThrowsAsync(new Exception("Network error occurred"));

            // Act
            await _viewModel.LoginCommand.ExecuteAsync(null);

            // Assert
            Assert.True(_viewModel.IsErrorVisible);
            Assert.Equal("Connection error. Check your internet.", _viewModel.ErrorMessage);
        }

        [Fact]
        public async Task LoginCommand_ShouldDisableButton_WhileLoading()
        {
            // Arrange
            _viewModel.Email = "test@example.com";
            _viewModel.Password = "password";
            
            // Setup a delayed response to check loading state
            _authServiceMock.Setup(s => s.LoginAsync(It.IsAny<string>(), It.IsAny<string>()))
                            .Returns(async () => {
                                await Task.Delay(100);
                                return "token";
                            });

            // Act
            var task = _viewModel.LoginCommand.ExecuteAsync(() => Task.CompletedTask);
            
            // Assert loading state
            Assert.True(_viewModel.IsLoading);
            Assert.False(_viewModel.IsButtonEnabled);

            await task;

            // Assert final state
            Assert.False(_viewModel.IsLoading);
            Assert.True(_viewModel.IsButtonEnabled);
        }
    }
}
