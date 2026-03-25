using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Threading.Tasks;
using Aura3DReview.Models;

namespace Aura3DReview.Services
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
                // Query: Get all items from 'sitios'
                
                string url = $"{BaseUrl}/sitios?pageSize=100";
                if (!string.IsNullOrEmpty(token))
                {
                    _httpClient.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
                }

                var response = await _httpClient.GetAsync(url);
                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    var root = JsonNode.Parse(json);
                    var documents = root?["documents"]?.AsArray();

                    if (documents != null)
                    {
                        foreach (var doc in documents)
                        {
                            var model = ParseFirestoreDocument(doc);
                            if (model != null)
                            {
                                list.Add(model);
                            }
                        }
                    }
                }
                else 
                {
                   System.Diagnostics.Debug.WriteLine($"Firestore Error: {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error getting models: {ex.Message}");
            }

            return list;
        }

        public async Task<bool> ApproveModelAsync(string modelId)
        {
             return await UpdateStatusAsync(modelId, "approved", null);
        }

        public async Task<bool> RejectModelAsync(string modelId, string reason)
        {
             return await UpdateStatusAsync(modelId, "denied", reason);
        }
        
        private async Task<bool> UpdateStatusAsync(string modelId, string status, string? reason)
        {
            string? token = await GetAuthToken();
            if (string.IsNullOrEmpty(token)) return false;

            string url = $"{BaseUrl}/sitios/{modelId}";
            
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
            
            var namePath = doc["name"]?.ToString(); // projects/.../sitios/{id}
            var id = namePath?.Split('/').LastOrDefault();
            
            var fields = doc["fields"];
            if (fields == null) return null; // Should ideally return object with Id at least

            var m = new Model3D { Id = id };
            
            m.Title = GetString(fields, "title");
            m.Author = GetString(fields, "author");
            m.AuthorId = GetString(fields, "authorId");
            m.ImageUrl = GetString(fields, "imageUrl");
            m.Status = GetString(fields, "status");
            m.Type = GetString(fields, "type");
            m.DenialReason = GetString(fields, "denialReason");
            
            m.Lat = GetDouble(fields, "lat");
            m.Lng = GetDouble(fields, "lng");
            
            m.CreatedAt = GetDate(fields, "createdAt");
            m.ReviewedAt = GetDate(fields, "reviewedAt");

            return m;
        }

        private string? GetString(JsonNode fields, string key) => fields[key]?["stringValue"]?.ToString();
        private double GetDouble(JsonNode fields, string key) => fields[key]?["doubleValue"]?.GetValue<double>() ?? 0;
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
                                Name = GetString(fields, "name") ?? GetString(fields, "Name") ?? GetString(fields, "nombre"),
                                Email = GetString(fields, "email") ?? GetString(fields, "Email"),
                                Role = GetString(fields, "role") ?? GetString(fields, "Role"),
                                Admin = GetString(fields, "admin") ?? GetString(fields, "Admin"),
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
                                    Name = GetString(fields, "name"),
                                    Email = GetString(fields, "email"),
                                    Role = GetString(fields, "role"),
                                    Admin = GetString(fields, "admin"),
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
            fields["admin"] = new JsonObject { ["stringValue"] = isAdmin ? "si" : "no" };

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
