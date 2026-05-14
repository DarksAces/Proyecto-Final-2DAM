using System;
using System.Linq;
using System.Windows;
using MaterialDesignThemes.Wpf;

namespace Jovi3DReview.Services
{
    public class ThemeService
    {
        private static ThemeService _instance;
        public static ThemeService Instance => _instance ??= new ThemeService();

        private ThemeService() { }

        public void Initialize()
        {
            var settings = ConfigService.Instance.Settings;
            SetDarkMode(settings.IsDarkMode, save: false);
            SetLanguage(settings.Language, save: false);
        }

        public void SetDarkMode(bool isDark, bool save = true)
        {
            PaletteHelper paletteHelper = new PaletteHelper();
            ITheme theme = paletteHelper.GetTheme();
            
            theme.SetBaseTheme(isDark ? Theme.Dark : Theme.Light);
            paletteHelper.SetTheme(theme);

            UpdateCustomBrushes(isDark);

            if (save)
            {
                ConfigService.Instance.Settings.IsDarkMode = isDark;
                ConfigService.Instance.Save();
            }
        }

        public void SetLanguage(string langCode, bool save = true) // "es", "en"
        {
            var dict = new ResourceDictionary();
            switch (langCode.ToLower())
            {
                case "en":
                    dict.Source = new Uri("pack://application:,,,/Resources/Strings.en.xaml");
                    break;
                default:
                    dict.Source = new Uri("pack://application:,,,/Resources/Strings.es.xaml");
                    break;
            }

            var oldDicts = Application.Current.Resources.MergedDictionaries
                .Where(d => d.Source != null && d.Source.OriginalString.Contains("Strings."))
                .ToList();

            foreach (var old in oldDicts)
            {
                Application.Current.Resources.MergedDictionaries.Remove(old);
            }

            Application.Current.Resources.MergedDictionaries.Add(dict);

            if (save)
            {
                ConfigService.Instance.Settings.Language = langCode;
                ConfigService.Instance.Save();
            }
        }

        private void UpdateCustomBrushes(bool isDark)
        {
            if (isDark)
            {
                Application.Current.Resources["ARteBackgroundLightBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(18, 18, 18));
                Application.Current.Resources["TextPrimaryBrush"] = System.Windows.Media.Brushes.White;
                Application.Current.Resources["TextSecondaryBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(160, 160, 160));
                Application.Current.Resources["BorderBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(40, 40, 40));
                
                // Button Brushes
                Application.Current.Resources["SuccessBackgroundBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(40, 40, 167, 69));
                Application.Current.Resources["SuccessBorderBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(80, 40, 167, 69));
                Application.Current.Resources["SuccessForegroundBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(80, 200, 120));
                
                Application.Current.Resources["ErrorBackgroundBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(40, 243, 22, 33));
                Application.Current.Resources["ErrorBorderBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(80, 243, 22, 33));
                Application.Current.Resources["ErrorForegroundBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(255, 80, 80));
                
                Application.Current.Resources["SurfaceVariantBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(30, 30, 30));
            }
            else
            {
                Application.Current.Resources["ARteBackgroundLightBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(248, 245, 246));
                Application.Current.Resources["TextPrimaryBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(28, 13, 14));
                Application.Current.Resources["TextSecondaryBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(156, 73, 78));
                Application.Current.Resources["BorderBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(231, 235, 243));

                // Button Brushes
                Application.Current.Resources["SuccessBackgroundBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(26, 40, 167, 69));
                Application.Current.Resources["SuccessBorderBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(51, 40, 167, 69));
                Application.Current.Resources["SuccessForegroundBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(40, 167, 69));

                Application.Current.Resources["ErrorBackgroundBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(26, 243, 22, 33));
                Application.Current.Resources["ErrorBorderBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromArgb(51, 243, 22, 33));
                Application.Current.Resources["ErrorForegroundBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(243, 22, 33));
                
                Application.Current.Resources["SurfaceVariantBrush"] = new System.Windows.Media.SolidColorBrush(System.Windows.Media.Color.FromRgb(240, 240, 240));
            }
        }
    }
}
