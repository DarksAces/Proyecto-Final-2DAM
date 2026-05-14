using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Threading.Tasks;
using Jovi3DReview.Models;

namespace Jovi3DReview.Services
{
    public class FirebaseService : IFirebaseService
    {
        private const string ProjectId = "jovi-45c79";
        private const string BaseUrl = $"https://firestore.googleapis.com/v1/projects/{ProjectId}/databases/(default)/documents";
        private readonly HttpClient _httpClient;

        public FirebaseService()
        {
            _httpClient = new HttpClient();
        }

        private async Task<string?> GetAuthToken()
        {
            return await AuthService.Instance.GetIdTokenAsync();
        }

        public async Task<List<Model3D>> GetModelsAsync()
        {
            var list = new List<Model3D>();
            string? token = await GetAuthToken();

            try
            {
                var collections = new[] { "sitios", "ar_objects", "contest_entries" };
                var statuses = new[] { "pending_review", "approved", "denied", "accepted", "rejected" };
                
                foreach (var collection in collections)
                {
                    // Try to fetch all first (if permissions allow)
                    var allDocs = await RunQueryAsync(collection, null, token);
                    if (allDocs != null && allDocs.Count > 0)
                    {
                        foreach (var doc in allDocs)
                        {
                            var model = ParseFirestoreDocument(doc);
                            if (model != null)
                            {
                                model.CollectionName = collection;
                                if (string.IsNullOrEmpty(model.Type)) model.Type = collection;
                                if (!list.Any(m => m.Id == model.Id)) list.Add(model);
                            }
                        }
                    }
                    else
                    {
                        // If empty or failed, try fetching by status (Point #2: Rules are not filters)
                        foreach (var status in statuses)
                        {
                            var statusDocs = await RunQueryAsync(collection, status, token);
                            if (statusDocs != null)
                            {
                                foreach (var doc in statusDocs)
                                {
                                    var model = ParseFirestoreDocument(doc);
                                    if (model != null)
                                    {
                                        model.CollectionName = collection;
                                        if (string.IsNullOrEmpty(model.Type)) model.Type = collection;
                                        if (!list.Any(m => m.Id == model.Id)) list.Add(model);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting models: {ex.Message}");
            }

            return list;
        }

        private async Task<List<JsonNode>?> RunQueryAsync(string collectionId, string? status, string? token)
        {
            string url = $"{BaseUrl}:runQuery";
            
            var structuredQuery = new JsonObject
            {
                ["from"] = new JsonArray { new JsonObject { ["collectionId"] = collectionId } }
            };

            if (!string.IsNullOrEmpty(status))
            {
                structuredQuery["where"] = new JsonObject
                {
                    ["fieldFilter"] = new JsonObject
                    {
                        ["field"] = new JsonObject { ["fieldPath"] = "status" },
                        ["op"] = "EQUAL",
                        ["value"] = new JsonObject { ["stringValue"] = status }
                    }
                };
            }

            var body = new JsonObject { ["structuredQuery"] = structuredQuery };

            try
            {
                var request = new HttpRequestMessage(HttpMethod.Post, url);
                if (!string.IsNullOrEmpty(token))
                {
                    request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
                }
                request.Content = new StringContent(body.ToJsonString(), System.Text.Encoding.UTF8, "application/json");

                var response = await _httpClient.SendAsync(request);
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    var results = JsonNode.Parse(json)?.AsArray();
                    var docs = new List<JsonNode>();
                    
                    if (results != null)
                    {
                        foreach (var result in results)
                        {
                            var doc = result?["document"];
                            if (doc != null) docs.Add(doc);
                        }
                    }
                    return docs;
                }
                else
                {
                    var error = await response.Content.ReadAsStringAsync();
                    System.Diagnostics.Debug.WriteLine($"Query failed for {collectionId} (status: {status}): {response.StatusCode} - {error}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error running query: {ex.Message}");
            }
            return null;
        }

        public async Task<bool> ApproveModelAsync(Model3D model)
        {
             return await UpdateStatusAsync(model, "approved", null);
        }

        public async Task<bool> RejectModelAsync(Model3D model, string reason)
        {
             return await UpdateStatusAsync(model, "denied", reason);
        }
        
        private async Task<bool> UpdateStatusAsync(Model3D model, string status, string? reason)
        {
            string? token = await GetAuthToken();
            if (string.IsNullOrEmpty(token) || string.IsNullOrEmpty(model.CollectionName)) return false;
            
            string url = $"{BaseUrl}/{model.CollectionName}/{model.Id}";
            
            // Allow partial update using updateMask
            string updateMask = "updateMask.fieldPaths=status&updateMask.fieldPaths=reviewedAt";
            if (reason != null) updateMask += "&updateMask.fieldPaths=denialReason";
            
            url += "?" + updateMask;

            // Prepare fields
            var fields = new JsonObject();
            fields["status"] = new JsonObject { ["stringValue"] = status };
            fields["reviewedAt"] = new JsonObject { ["timestampValue"] = DateTime.UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ") };
            
            if (reason != null)
            {
                 fields["denialReason"] = new JsonObject { ["stringValue"] = reason };
            }

            var body = new JsonObject
            {
                ["fields"] = fields
            };

            var request = new HttpRequestMessage(new HttpMethod("PATCH"), url);
            request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
            request.Content = new StringContent(body.ToJsonString(), System.Text.Encoding.UTF8, "application/json");

            var response = await _httpClient.SendAsync(request);
            return response.IsSuccessStatusCode;
        }

        public async Task<Model3D> GetModelDetailsAsync(string modelId) 
        {
             // Implement if needed for details view, similar GET logic
             return new Model3D { Id = modelId, Title = "Loading..." };
        }

        private Model3D? ParseFirestoreDocument(JsonNode? doc)
        {
            if (doc == null) return null;
            
            // doc can be the document itself (from List) or extracted from {"document": ...} (from runQuery)
            var namePath = doc["name"]?.ToString().Trim('"'); // Remove quotes if present
            var id = namePath?.Split('/').LastOrDefault();
            
            var fields = doc["fields"];
            if (fields == null) return null; 

            var m = new Model3D { Id = id };
            
            m.Title = GetString(fields, "title") ?? GetString(fields, "location") ?? GetString(fields, "name") ?? GetString(fields, "description") ?? "Sin Título";
            m.Author = GetString(fields, "author") ?? GetString(fields, "username") ?? GetString(fields, "artistName") ?? "Anónimo";
            m.AuthorId = GetString(fields, "authorId") ?? GetString(fields, "userId");
            m.ImageUrl = GetString(fields, "imageUrl") ?? GetString(fields, "thumbnailUrl") ?? GetString(fields, "url");
            m.ModelUrl = GetString(fields, "url");
            
            var rawStatus = GetString(fields, "status");
            if (rawStatus == "accepted" || rawStatus == "approved") m.Status = "approved";
            else if (rawStatus == "denied" || rawStatus == "rejected") m.Status = "denied";
            else m.Status = "pending_review";

            m.Type = GetString(fields, "type") ?? "Modelo 3D";
            m.DenialReason = GetString(fields, "denialReason");
            
            m.Lat = GetDouble(fields, "lat") ?? GetDouble(fields, "latitude") ?? 0.0;
            m.Lng = GetDouble(fields, "lng") ?? GetDouble(fields, "longitude") ?? 0.0;
            
            m.CreatedAt = GetDate(fields, "createdAt") ?? GetDate(fields, "timestamp") ?? DateTime.Now;
            m.ReviewedAt = GetDate(fields, "reviewedAt");

            // New Metadata
            m.VerticesCount = GetDouble(fields, "verticesCount") ?? 0.0;
            m.FileSizeMB = GetDouble(fields, "fileSizeMB") ?? 0.0;
            m.FileFormat = GetString(fields, "fileFormat") ?? GetString(fields, "type");
            m.AuthorBio = GetString(fields, "authorBio") ?? "";
            m.FeedbackCount = (int)(GetDouble(fields, "feedbackCount") ?? 0.0);
            
            var ff = GetString(fields, "fileFormat");
            if (!string.IsNullOrEmpty(ff)) m.FileFormat = ff;
            
            var ar = GetString(fields, "authorRole");
            if (!string.IsNullOrEmpty(ar)) m.AuthorRole = ar;
            
            var ab = GetString(fields, "authorBio");
            if (!string.IsNullOrEmpty(ab)) m.AuthorBio = ab;
            
            var fc = GetInt(fields, "feedbackCount");
            if (fc != null && fc > 0) m.FeedbackCount = (int)fc;

            return m;
        }

        private string? GetString(JsonNode fields, string key) => fields[key]?["stringValue"]?.ToString();
        private double? GetDouble(JsonNode fields, string key) 
        {
            var val = fields[key];
            if (val?["doubleValue"] != null) return val["doubleValue"]!.GetValue<double>();
            if (val?["integerValue"] != null) return double.Parse(val["integerValue"]!.ToString());
            return null;
        }
        private int? GetInt(JsonNode fields, string key) 
        {
            var val = fields[key];
            if (val?["integerValue"] != null) return int.Parse(val["integerValue"]!.ToString());
            return null;
        }
        private DateTime? GetDate(JsonNode fields, string key) 
        {
            var ts = fields[key]?["timestampValue"]?.ToString();
            if (DateTime.TryParse(ts, out var dt)) return dt;
            return null;
        }

        public async Task<User?> GetUserAsync(string userId)
        {
            string? token = await GetAuthToken();
            if (string.IsNullOrEmpty(token)) return null;

            string url = $"{BaseUrl}/users/{userId}";
            
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Get, url);
                request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

                var response = await _httpClient.SendAsync(request);
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    var doc = JsonNode.Parse(json);
                    
                    if (doc != null)
                    {
                        var fields = doc["fields"];
                        if (fields != null)
                        {
                            return new User
                            {
                                Id = userId,
                                Name = GetString(fields, "displayName") ?? GetString(fields, "displayName") ?? GetString(fields, "Name") ?? GetString(fields, "name") ?? GetString(fields, "nombre"),
                                Email = GetString(fields, "email") ?? GetString(fields, "Email"),
                                Role = GetString(fields, "role") ?? GetString(fields, "Role"),
                                Admin = GetString(fields, "admin") ?? GetString(fields, "Admin") ?? GetInt(fields, "admin")?.ToString() ?? GetInt(fields, "Admin")?.ToString(),
                                AvatarUrl = GetString(fields, "avatarUrl") ?? GetString(fields, "AvatarUrl")
                            };
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting user: {ex.Message}");
            }
            return null;
        }

        public async Task<string?> GetUserNameAsync(string userId)
        {
            if (string.IsNullOrEmpty(userId)) return null;
            var user = await GetUserAsync(userId);
            return user?.Name;
        }

        public async Task<List<User>> GetAllUsersAsync()
        {
            var list = new List<User>();
            string? token = await GetAuthToken();
            if (string.IsNullOrEmpty(token)) return list;

            string url = $"{BaseUrl}/users";
            
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Get, url);
                request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);

                var response = await _httpClient.SendAsync(request);
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    var root = JsonNode.Parse(json);
                    var documents = root?["documents"]?.AsArray();

                    if (documents != null)
                    {
                        foreach (var doc in documents)
                        {
                            var fields = doc["fields"];
                            if (fields != null)
                            {
                                var namePath = doc["name"]?.ToString();
                                var id = namePath?.Split('/').LastOrDefault();
                                
                                list.Add(new User
                                {
                                    Id = id,
                                    Name = GetString(fields, "displayName") ?? GetString(fields, "displayName") ?? GetString(fields, "name") ?? GetString(fields, "Name"),
                                    Email = GetString(fields, "email"),
                                    Role = GetString(fields, "role"),
                                    Admin = GetString(fields, "admin") ?? GetInt(fields, "admin")?.ToString(),
                                    AvatarUrl = GetString(fields, "avatarUrl")
                                });
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting all users: {ex.Message}");
            }
            return list;
        }

        public async Task<bool> UpdateUserAdminAsync(string userId, bool isAdmin)
        {
            string? token = await GetAuthToken();
            if (string.IsNullOrEmpty(token)) return false;

            string url = $"{BaseUrl}/users/{userId}?updateMask.fieldPaths=admin";
            
            // Prepare fields
            var fields = new JsonObject();
            fields["admin"] = new JsonObject { ["stringValue"] = isAdmin ? "1" : "0" };

            var body = new JsonObject
            {
                ["fields"] = fields
            };

            var request = new HttpRequestMessage(new HttpMethod("PATCH"), url);
            request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
            request.Content = new StringContent(body.ToJsonString(), System.Text.Encoding.UTF8, "application/json");

            try
            {
                var response = await _httpClient.SendAsync(request);
                return response.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }
    }
}
