using System;
using Jovi3DReview.Models;
using Xunit;

namespace Jovi3DReview.Tests.Models
{
    public class Model3DTests
    {
        [Theory]
        [InlineData("pending_review", "Pendiente")]
        [InlineData("accepted", "Aprobado")]
        [InlineData("denied", "Rechazado")]
        [InlineData("unknown", "unknown")]
        [InlineData(null, "Desconocido")]
        public void StatusDisplay_ShouldReturnCorrectMapping(string? status, string expected)
        {
            // Arrange
            var model = new Model3D { Status = status };

            // Act
            var result = model.StatusDisplay;

            // Assert
            Assert.Equal(expected, result);
        }

        [Fact]
        public void IsPending_ShouldBeTrue_OnlyWhenStatusIsPendingReview()
        {
            // Arrange
            var model1 = new Model3D { Status = "pending_review" };
            var model2 = new Model3D { Status = "accepted" };

            // Assert
            Assert.True(model1.IsPending);
            Assert.False(model1.IsNotPending);
            
            Assert.False(model2.IsPending);
            Assert.True(model2.IsNotPending);
        }

        [Fact]
        public void ReviewsDateDisplay_ShouldReturnReviewedDate_WhenAvailable()
        {
            // Arrange
            var reviewedAt = new DateTime(2024, 1, 1);
            var model = new Model3D { ReviewedAt = reviewedAt };

            // Act
            var result = model.ReviewsDateDisplay;

            // Assert
            Assert.Contains("Revisado:", result);
            Assert.Contains("2024", result);
        }

        [Fact]
        public void ReviewsDateDisplay_ShouldReturnCreatedDate_WhenReviewedIsNull()
        {
            // Arrange
            var createdAt = new DateTime(2023, 12, 25);
            var model = new Model3D { CreatedAt = createdAt, ReviewedAt = null };

            // Act
            var result = model.ReviewsDateDisplay;

            // Assert
            Assert.Contains("Creado:", result);
            Assert.Contains("2023", result);
            Assert.Contains("25", result);
        }

        [Fact]
        public void ReviewsDateDisplay_ShouldReturnEmpty_WhenBothDatesAreNull()
        {
            // Arrange
            var model = new Model3D { CreatedAt = null, ReviewedAt = null };

            // Act
            var result = model.ReviewsDateDisplay;

            // Assert
            Assert.Equal(string.Empty, result);
        }
    }
}
