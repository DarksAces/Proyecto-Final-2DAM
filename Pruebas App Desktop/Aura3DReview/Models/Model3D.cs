using System;


namespace Jovi3DReview.Models
{
    public class Model3D
    {
        public string? Id { get; set; }
        
        public string? Title { get; set; } // title
        public string? Author { get; set; } // author
        public string? AuthorId { get; set; } // authorId
        public string? ImageUrl { get; set; } // imageUrl
        public string? Status { get; set; } // "pending_review", "approved", "denied"
        public string? Type { get; set; } // type
        public string? DenialReason { get; set; } // denialReason
        
        public DateTime? CreatedAt { get; set; } // createdAt
        public DateTime? ReviewedAt { get; set; } // reviewedAt
        
        public double Lat { get; set; } // lat
        public double Lng { get; set; } // lng

        // Helpers for UI
        public string StatusDisplay => Status switch 
        {
            "pending_review" => "Pendiente",
            "approved" => "Aprobado",
            "denied" => "Rechazado",
            _ => Status ?? "Desconocido"
        };

        public bool IsPending => Status == "pending_review";
        public bool IsNotPending => !IsPending;

        public string ReviewsDateDisplay => ReviewedAt.HasValue 
            ? $"Revisado: {ReviewedAt.Value.ToShortDateString()}" 
            : (CreatedAt.HasValue ? $"Creado: {CreatedAt.Value.ToShortDateString()}" : "");
    }
}
