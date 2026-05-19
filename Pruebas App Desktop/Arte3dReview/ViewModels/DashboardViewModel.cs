// MODIFICADO POR ANTIGRAVITY - CAMBIO DINÁMICO DE TÍTULOS
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using Jovi3DReview.Models;
using Jovi3DReview.Services;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Threading.Tasks;
using System.Windows;

namespace Jovi3DReview.ViewModels
{
    public partial class DashboardViewModel : ObservableObject
    {
        private readonly IFirebaseService _firebaseService;
        private List<Model3D> _allModels = new List<Model3D>();

        [ObservableProperty]
        private ObservableCollection<Model3D> _models = new ObservableCollection<Model3D>();

        [ObservableProperty]
        private string _currentFilter = "Pending";

        [ObservableProperty]
        private string _headerCountText = string.Empty;
        
        [ObservableProperty]
        private int _totalPendingCount;

        [ObservableProperty]
        private string _paginationText = string.Empty;

        [ObservableProperty]
        private bool _isLoading;

        public DashboardViewModel() : this(new FirebaseService())
        {
        }

        public DashboardViewModel(IFirebaseService firebaseService)
        {
            _firebaseService = firebaseService;
            UpdateCounters(); // Initialize localized strings

            ThemeService.Instance.LanguageChanged += (s, lang) => UpdateCounters();
        }

        [RelayCommand]
        public async Task RefreshDataAsync()
        {
            await LoadDataAsync();
        }

        public async Task LoadDataAsync()
        {
            IsLoading = true;
            try
            {
                var data = await _firebaseService.GetModelsAsync();
                _allModels = data ?? new List<Model3D>();
                ApplyFilter();
            }
            catch (Exception ex)
            {
                // In a real app, we'd use a dialog service. For now, we just log.
                System.Diagnostics.Debug.WriteLine($"Error loading models: {ex.Message}");
            }
            finally
            {
                IsLoading = false;
            }
        }

        [RelayCommand]
        public void ChangeFilter(string filter)
        {
            CurrentFilter = filter;
            ApplyFilter();
        }

        private void ApplyFilter()
        {
            Models.Clear();
            IEnumerable<Model3D> filtered = _allModels;

            // Use internal names for logic, matching what comes from the buttons
            switch (CurrentFilter)
            {
                case "Pendientes":
                case "Pending":
                    filtered = _allModels.Where(m => m.Status == "pending_review");
                    break;
                case "Aprobados":
                case "Approved":
                    filtered = _allModels.Where(m => m.Status == "approved");
                    break;
                case "Rechazados":
                case "Rejected":
                    filtered = _allModels.Where(m => m.Status == "denied");
                    break;
                case "Todos":
                case "All":
                    break;
            }

            foreach (var item in filtered)
            {
                Models.Add(item);
            }

            UpdateCounters();
        }

        private void UpdateCounters()
        {
            int count = Models.Count;
            int totalPending = _allModels.Count(m => m.Status == "pending_review");
            TotalPendingCount = totalPending;
            
            // Check for Application.Current to avoid NullReferenceException in Unit Tests
            var resources = Application.Current?.Resources;
            
            string headerFormat = resources?["StrHeaderCountFormat"] as string ?? "Hay {0} obras esperando tu aprobación hoy.";
            string paginationFormat = resources?["StrPaginationFormat"] as string ?? "Mostrando {0} obras ({1})";
            
            // For pagination text, we still need a localized filter name
            string localizedFilter = CurrentFilter;
            if (resources != null)
            {
                if (CurrentFilter == "Pending") localizedFilter = resources["StrPendientes"] as string ?? "Pendientes";
                else if (CurrentFilter == "Approved") localizedFilter = resources["StrAprobados"] as string ?? "Aprobados";
                else if (CurrentFilter == "Rejected") localizedFilter = resources["StrRechazados"] as string ?? "Rechazados";
                else if (CurrentFilter == "All") localizedFilter = resources["StrTodos"] as string ?? "Todos";
            }

            HeaderCountText = string.Format(headerFormat, totalPending);
            PaginationText = string.Format(paginationFormat, count, localizedFilter);
        }

        [RelayCommand]
        public async Task ApproveModelAsync(Model3D model)
        {
            if (model == null || string.IsNullOrEmpty(model.Id)) return;

            var success = await _firebaseService.ApproveModelAsync(model);
            if (success)
            {
                model.Status = "approved";
                model.ReviewedAt = DateTime.UtcNow;
                ApplyFilter();
            }
        }

        [RelayCommand]
        public async Task RejectModelAsync((Model3D model, string reason) param)
        {
            var model = param.model;
            var reason = param.reason;
            if (model == null || string.IsNullOrEmpty(model.Id)) return;

            var success = await _firebaseService.RejectModelAsync(model, reason);
            if (success)
            {
                model.Status = "denied";
                model.ReviewedAt = DateTime.UtcNow;
                ApplyFilter();
            }
        }
    }
}
