using System;

namespace Aura3DReview.Models
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
        public bool IsAdmin => Admin?.ToLower() == "si";
        public bool IsNotAdmin => !IsAdmin;
        
        public string AdminDisplay => IsAdmin ? "ADMINISTRADOR" : "USUARIO";
        public string AdminBackground => IsAdmin ? "#1AB22222" : "#F0F0F0"; // Light Red or Grey
        public string AdminForeground => IsAdmin ? "#D32F2F" : "#757575";
    }
}
