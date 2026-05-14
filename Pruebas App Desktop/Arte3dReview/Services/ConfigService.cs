using System;
using System.IO;
using System.Text.Json;

namespace Jovi3DReview.Services
{
    public class AppSettings
    {
        public bool IsDarkMode { get; set; } = false;
        public string Language { get; set; } = "es";
    }

    public class ConfigService
    {
        private static ConfigService _instance;
        public static ConfigService Instance => _instance ??= new ConfigService();

        private readonly string _configPath;
        public AppSettings Settings { get; private set; }

        private ConfigService()
        {
            string appData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
            string folder = Path.Combine(appData, "Jovi3DReview");
            if (!Directory.Exists(folder)) Directory.CreateDirectory(folder);
            
            _configPath = Path.Combine(folder, "settings.json");
            Load();
        }

        public void Load()
        {
            if (File.Exists(_configPath))
            {
                try
                {
                    string json = File.ReadAllText(_configPath);
                    Settings = JsonSerializer.Deserialize<AppSettings>(json) ?? new AppSettings();
                }
                catch
                {
                    Settings = new AppSettings();
                }
            }
            else
            {
                Settings = new AppSettings();
            }
        }

        public void Save()
        {
            try
            {
                string json = JsonSerializer.Serialize(Settings, new JsonSerializerOptions { WriteIndented = true });
                File.WriteAllText(_configPath, json);
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error saving settings: {ex.Message}");
            }
        }
    }
}
