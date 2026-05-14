using System;


namespace Jovi3DReview.Models
{
    public class Model3D
    {
        public string? Id { get; set; } // documentId
        public string? CollectionName { get; set; } // sitios, ar_objects, contest_entries, etc.
        public string? Title { get; set; } // title or location       
        public string? Author { get; set; } // author
        public string? AuthorId { get; set; } // authorId
        public string? ImageUrl { get; set; } // imageUrl
        public string? ModelUrl { get; set; } // url (for 3D models)
        public string? Status { get; set; } // "pending_review", "approved", "denied"
        public string? Type { get; set; } // type
        public string? DenialReason { get; set; } // denialReason
        
        public DateTime? CreatedAt { get; set; } // createdAt
        public DateTime? ReviewedAt { get; set; } // reviewedAt
        
        public double Lat { get; set; } // lat
        public double Lng { get; set; } // lng

        // Metadata
        public double VerticesCount { get; set; } = 0;
        public double FileSizeMB { get; set; } = 0;
        public string? FileFormat { get; set; }
        public string AuthorRole { get; set; } = "Colaborador";
        public string AuthorBio { get; set; } = "";
        public int FeedbackCount { get; set; } = 0;

        // Helpers for UI
        public string StatusDisplay => Status switch 
        {
            "pending_review" => "Pendiente",
            "accepted" => "Aprobado",
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
