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
        private string _currentFilter = "Pendientes";

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

            switch (CurrentFilter)
            {
                case "Pendientes":
                    filtered = _allModels.Where(m => m.Status == "pending_review");
                    break;
                case "Aprobados":
                    filtered = _allModels.Where(m => m.Status == "approved");
                    break;
                case "Rechazados":
                    filtered = _allModels.Where(m => m.Status == "denied");
                    break;
                case "Todos":
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
            
            string headerFormat = Application.Current.Resources["StrHeaderCountFormat"] as string ?? "Hay {0} obras...";
            string paginationFormat = Application.Current.Resources["StrPaginationFormat"] as string ?? "Mostrando {0} obras...";
            
            // Map internal filter names to localized names for the pagination text
            string localizedFilter = CurrentFilter;
            if (CurrentFilter == "Pendientes") localizedFilter = Application.Current.Resources["StrPendientes"] as string ?? "Pendientes";
            else if (CurrentFilter == "Aprobados") localizedFilter = Application.Current.Resources["StrAprobados"] as string ?? "Aprobados";
            else if (CurrentFilter == "Rechazados") localizedFilter = Application.Current.Resources["StrRechazados"] as string ?? "Rechazados";
            else if (CurrentFilter == "Todos") localizedFilter = Application.Current.Resources["StrTodos"] as string ?? "Todos";

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
