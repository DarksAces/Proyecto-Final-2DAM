using System;

namespace Jovi3DReview.Models
{
    public class User
    {
        public string? Id { get; set; }
        public string? Name { get; set; }
        public string? Email { get; set; }
        public string? Role { get; set; } // "admin", "editor", etc.
        public string? Admin { get; set; } // "si" or "no" or null
        public string? AvatarUrl { get; set; }

        // Helpers for UI
        public bool IsAdmin => Admin?.Trim() == "1" || 
                               Admin?.Trim().ToLower() == "si" || 
                               Admin?.Trim().ToLower() == "true"; 
        public bool IsNotAdmin => !IsAdmin;
        
        public string AdminDisplay => IsAdmin 
            ? (System.Windows.Application.Current?.Resources["StrAdministrador"]?.ToString() ?? "ADMINISTRATOR").ToUpper() 
            : (System.Windows.Application.Current?.Resources["StrUsuario"]?.ToString() ?? "USER").ToUpper();
        public string AdminBackground => IsAdmin ? "#1AB22222" : "#F0F0F0"; // Light Red or Grey
        public string AdminForeground => IsAdmin ? "#D32F2F" : "#757575";
    }
}
