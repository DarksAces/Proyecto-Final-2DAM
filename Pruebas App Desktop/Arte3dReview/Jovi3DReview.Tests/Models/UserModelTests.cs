using Jovi3DReview.Models;
using Xunit;

namespace Jovi3DReview.Tests.Models
{
    public class UserModelTests
    {
        [Theory]
        [InlineData("1", true)]
        [InlineData("si", true)]
        [InlineData("SI", true)]
        [InlineData("True", true)]
        [InlineData("TRUE", true)]
        [InlineData("  si  ", true)]
        [InlineData("no", false)]
        [InlineData("0", false)]
        [InlineData(null, false)]
        [InlineData("", false)]
        [InlineData("   ", false)]
        [InlineData("False", false)]
        [InlineData("monkey", false)]
        public void IsAdmin_ShouldReturnCorrectValue_BasedOnAdminString(string? adminValue, bool expected)
        {
            // Arrange
            var user = new User { Admin = adminValue };

            // Act
            var result = user.IsAdmin;

            // Assert
            Assert.Equal(expected, result);
        }

        [Fact]
        public void AdminDisplay_ShouldReturnAdministrador_WhenIsAdminIsTrue()
        {
            // Arrange
            var user = new User { Admin = "si" };

            // Act
            var result = user.AdminDisplay;

            // Assert
            Assert.Equal("ADMINISTRADOR", result);
        }

        [Fact]
        public void AdminDisplay_ShouldReturnUsuario_WhenIsAdminIsFalse()
        {
            // Arrange
            var user = new User { Admin = "no" };

            // Act
            var result = user.AdminDisplay;

            // Assert
            Assert.Equal("USUARIO", result);
        }

        [Fact]
        public void IsNotAdmin_ShouldBeInverseOfIsAdmin()
        {
            // Arrange
            var user = new User { Admin = "si" };

            // Assert
            Assert.True(user.IsAdmin);
            Assert.False(user.IsNotAdmin);

            user.Admin = "no";
            Assert.False(user.IsAdmin);
            Assert.True(user.IsNotAdmin);
        }
    }
}
