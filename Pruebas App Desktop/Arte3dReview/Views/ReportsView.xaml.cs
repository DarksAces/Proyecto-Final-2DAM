using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Windows;
using System.Windows.Controls;
using Jovi3DReview.Models;
using Jovi3DReview.Services;
using LiveChartsCore;
using LiveChartsCore.SkiaSharpView;
using LiveChartsCore.SkiaSharpView.Painting;
using SkiaSharp;

namespace Jovi3DReview.Views
{
    public partial class ReportsView : UserControl
    {
        private readonly FirebaseService _firebaseService;
        private List<Model3D> _allModels = new();

        public ISeries[] Series { get; set; } = Array.Empty<ISeries>();
        public Axis[] XAxes { get; set; } = Array.Empty<Axis>();
        public Axis[] YAxes { get; set; } = Array.Empty<Axis>();

        public ReportsView()
        {
            InitializeComponent();
            _firebaseService = new FirebaseService();
            this.DataContext = this;
            Loaded += ReportsView_Loaded;
        }

        private async void ReportsView_Loaded(object sender, RoutedEventArgs e)
        {
            _allModels = await _firebaseService.GetModelsAsync();
            UpdateStats();
            UpdateChart("Weekly");
        }

        private void UpdateStats()
        {
            TotalCount.Text = _allModels.Count.ToString();
            ApprovedCount.Text = _allModels.Count(m => m.Status == "approved").ToString();
            RejectedCount.Text = _allModels.Count(m => m.Status == "denied").ToString();
            PendingCount.Text = _allModels.Count(m => m.Status == "pending_review").ToString();
        }

        private void Filter_Checked(object sender, RoutedEventArgs e)
        {
            if (_allModels == null || !IsLoaded) return;

            var rb = sender as RadioButton;
            if (rb == null) return;

            string filter = rb.Name switch
            {
                "FilterWeekly" => "Weekly",
                "FilterMonthly" => "Monthly",
                "FilterYearly" => "Yearly",
                _ => "Weekly"
            };

            UpdateChart(filter);
        }

        private void UpdateChart(string filter)
        {
            if (_allModels == null || !_allModels.Any()) return;

            string[] labels;
            double[] approvedData;
            double[] rejectedData;

            DateTime now = DateTime.Now;
            DateTime startDate;

            if (filter == "Weekly")
            {
                startDate = now.Date.AddDays(-(int)now.DayOfWeek + 1); // Monday
                labels = new[] { "Lun", "Mar", "Mie", "Jue", "Vie", "Sab", "Dom" };
                approvedData = new double[7];
                rejectedData = new double[7];

                for (int i = 0; i < 7; i++)
                {
                    DateTime day = startDate.AddDays(i);
                    approvedData[i] = _allModels.Count(m => m.CreatedAt?.Date == day && m.Status == "approved");
                    rejectedData[i] = _allModels.Count(m => m.CreatedAt?.Date == day && m.Status == "denied");
                }
            }
            else if (filter == "Monthly")
            {
                startDate = new DateTime(now.Year, now.Month, 1);
                labels = new[] { "Sem 1", "Sem 2", "Sem 3", "Sem 4" };
                approvedData = new double[4];
                rejectedData = new double[4];

                for (int i = 0; i < 4; i++)
                {
                    DateTime weekStart = startDate.AddDays(i * 7);
                    DateTime weekEnd = weekStart.AddDays(7);
                    approvedData[i] = _allModels.Count(m => m.CreatedAt >= weekStart && m.CreatedAt < weekEnd && m.Status == "approved");
                    rejectedData[i] = _allModels.Count(m => m.CreatedAt >= weekStart && m.CreatedAt < weekEnd && m.Status == "denied");
                }
            }
            else // Yearly
            {
                labels = new[] { "Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic" };
                approvedData = new double[12];
                rejectedData = new double[12];

                for (int i = 0; i < 12; i++)
                {
                    int month = i + 1;
                    approvedData[i] = _allModels.Count(m => m.CreatedAt?.Year == now.Year && m.CreatedAt?.Month == month && m.Status == "approved");
                    rejectedData[i] = _allModels.Count(m => m.CreatedAt?.Year == now.Year && m.CreatedAt?.Month == month && m.Status == "denied");
                }
            }

            Series = new ISeries[]
            {
                new ColumnSeries<double>
                {
                    Name = "Aprobados",
                    Values = approvedData,
                    Fill = new SolidColorPaint(SKColor.Parse("#28a745")),
                    Padding = 2
                },
                new ColumnSeries<double>
                {
                    Name = "Rechazados",
                    Values = rejectedData,
                    Fill = new SolidColorPaint(SKColor.Parse("#f31621")), // ARte Primary
                    Padding = 2
                }
            };

            XAxes = new Axis[]
            {
                new Axis
                {
                    Labels = labels,
                    LabelsRotation = 0,
                    SeparatorsPaint = new SolidColorPaint(SKColors.LightGray) { StrokeThickness = 1 }
                }
            };

            YAxes = new Axis[]
            {
                new Axis
                {
                    Labeler = value => value.ToString(),
                    SeparatorsPaint = new SolidColorPaint(SKColors.LightGray) { StrokeThickness = 1 }
                }
            };

            // Notify UI
            OnPropertyChanged(nameof(Series));
            OnPropertyChanged(nameof(XAxes));
            OnPropertyChanged(nameof(YAxes));
            
            if (MainChart != null)
            {
                MainChart.Series = Series;
                MainChart.XAxes = XAxes;
                MainChart.YAxes = YAxes;
            }
        }

        public event System.ComponentModel.PropertyChangedEventHandler? PropertyChanged;
        protected virtual void OnPropertyChanged(string propertyName)
        {
            PropertyChanged?.Invoke(this, new System.ComponentModel.PropertyChangedEventArgs(propertyName));
        }
    }
}
