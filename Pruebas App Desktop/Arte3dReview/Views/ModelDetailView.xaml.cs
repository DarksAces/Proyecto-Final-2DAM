using System.Windows;
using System.Windows.Controls;
using Jovi3DReview.Models;
using Jovi3DReview.Services;

namespace Jovi3DReview.Views
{
    public partial class ModelDetailView : UserControl
    {
        private Model3D _model;
        private readonly FirebaseService _firebaseService;

        public ModelDetailView()
        {
            InitializeComponent();
            _firebaseService = new FirebaseService();
        }

        public ModelDetailView(Model3D model) : this()
        {
            _model = model;
            this.DataContext = _model;
            this.Loaded += ModelDetailView_Loaded;
        }

        private async void ModelDetailView_Loaded(object sender, RoutedEventArgs e)
        {
            if (_model != null && !string.IsNullOrEmpty(_model.AuthorId))
            {
                // Si el autor es "Anónimo" o similar, intentamos buscar su displayName real
                var realName = await _firebaseService.GetUserNameAsync(_model.AuthorId);
                if (!string.IsNullOrEmpty(realName))
                {
                    _model.Author = realName;
                    // Forzamos actualización de la UI si es necesario (aunque el binding debería funcionar si Model3D implementara INotifyPropertyChanged)
                    // Como Model3D no parece implementar INotifyPropertyChanged, reasignamos el DataContext
                    this.DataContext = null;
                    this.DataContext = _model;
                }
            }
        }

        private async void Approve_Click(object sender, RoutedEventArgs e)
        {
            if (_model == null) return;

            var success = await _firebaseService.ApproveModelAsync(_model);
            if (success)
            {
                MessageBox.Show("Modelo aprobado correctamente.", "ARte", MessageBoxButton.OK, MessageBoxImage.Information);
                // Navigate back to Dashboard or update UI
                var mainWindow = Window.GetWindow(this) as MainWindow;
                mainWindow?.NavigateToDashboard();
            }
            else
            {
                MessageBox.Show("Error al aprobar el modelo.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
            }
        }

        private async void Reject_Click(object sender, RoutedEventArgs e)
        {
            if (_model == null || _model.Id == null) return;

            var dialog = new RejectionDialog();
            dialog.Owner = Window.GetWindow(this);

            if (dialog.ShowDialog() == true)
            {
                string reason = dialog.RejectionReason;
                var success = await _firebaseService.RejectModelAsync(_model, reason);

                if (success)
                {
                    MessageBox.Show("Modelo rechazado.", "ARte", MessageBoxButton.OK, MessageBoxImage.Information);
                    var mainWindow = Window.GetWindow(this) as MainWindow;
                    mainWindow?.NavigateToDashboard();
                }
                else
                {
                    MessageBox.Show("Error al rechazar el modelo.", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                }
            }
        }

        private async void Load3D_Click(object sender, RoutedEventArgs e)
        {
            if (_model == null || string.IsNullOrEmpty(_model.ModelUrl))
            {
                MessageBox.Show("Este objeto no tiene un archivo 3D (AR) asociado.", "ARte", MessageBoxButton.OK, MessageBoxImage.Warning);
                return;
            }

            try
            {
                PlayOverlay.Visibility = Visibility.Collapsed;
                PlaceholderImage.Visibility = Visibility.Collapsed;
                LoadingOverlay.Visibility = Visibility.Visible;
                WebView.Visibility = Visibility.Collapsed;

                await WebView.EnsureCoreWebView2Async();
                
                // Usamos un directorio temporal para servir el archivo, evitando problemas de tamaño con Base64
                string tempPath = System.IO.Path.Combine(System.IO.Path.GetTempPath(), "ARteReview");
                if (!System.IO.Directory.Exists(tempPath)) System.IO.Directory.CreateDirectory(tempPath);
                
                string modelFileName = "model.glb";
                string fullPath = System.IO.Path.Combine(tempPath, modelFileName);
                
                byte[] modelData;
                using (var client = new System.Net.Http.HttpClient())
                {
                    modelData = await client.GetByteArrayAsync(_model.ModelUrl);
                }
                System.IO.File.WriteAllBytes(fullPath, modelData);

                // Mapeamos el directorio temporal a un host virtual
                WebView.CoreWebView2.SetVirtualHostNameToFolderMapping("arte.local", tempPath, Microsoft.Web.WebView2.Core.CoreWebView2HostResourceAccessKind.Allow);

                string html = $@"
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset='utf-8'>
                    <script type='module' src='https://ajax.googleapis.com/ajax/libs/model-viewer/3.4.0/model-viewer.min.js'></script>
                    <style>
                        body {{ margin: 0; background-color: #f8f9fa; overflow: hidden; display: flex; justify-content: center; align-items: center; height: 100vh; font-family: sans-serif; }}
                        model-viewer {{ width: 100%; height: 100%; display: block; }}
                    </style>
                </head>
                <body>
                    <model-viewer 
                        id='viewer'
                        src='https://arte.local/{modelFileName}' 
                        camera-controls 
                        auto-rotate 
                        shadow-intensity='2' 
                        environment-image='neutral' 
                        exposure='1.2'>
                    </model-viewer>
                </body>
                </html>";

                string htmlPath = System.IO.Path.Combine(tempPath, "index.html");
                System.IO.File.WriteAllText(htmlPath, html);

                // Nos registramos para ocultar el cargando una vez termine la navegación
                System.EventHandler<Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs>? handler = null;
                handler = (s, args) =>
                {
                    LoadingOverlay.Visibility = Visibility.Collapsed;
                    WebView.Visibility = Visibility.Visible;
                    WebView.NavigationCompleted -= handler; // Desvincular para evitar fugas de memoria
                };
                WebView.NavigationCompleted += handler;

                WebView.CoreWebView2.Navigate("https://arte.local/index.html");
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Error al procesar el modelo 3D: {ex.Message}", "Error", MessageBoxButton.OK, MessageBoxImage.Error);
                PlayOverlay.Visibility = Visibility.Visible;
                PlaceholderImage.Visibility = Visibility.Visible;
                LoadingOverlay.Visibility = Visibility.Collapsed;
                WebView.Visibility = Visibility.Collapsed;
            }
        }
        private void BackToDashboard_Click(object sender, System.Windows.Input.MouseButtonEventArgs e)
        {
            var mainWindow = Window.GetWindow(this) as MainWindow;
            mainWindow?.NavigateToDashboard();
        }
    }
}
