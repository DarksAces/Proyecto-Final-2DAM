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

            string approvedName = Application.Current?.Resources["StrAprobados"]?.ToString() ?? "Approved";
            string rejectedName = Application.Current?.Resources["StrRechazados"]?.ToString() ?? "Rejected";

            if (filter == "Weekly")
            {
                startDate = now.Date.AddDays(-(int)now.DayOfWeek + 1); // Monday
                labels = new[] 
                { 
                    Application.Current?.Resources["StrChartLun"]?.ToString() ?? "Mon",
                    Application.Current?.Resources["StrChartMar"]?.ToString() ?? "Tue",
                    Application.Current?.Resources["StrChartMie"]?.ToString() ?? "Wed",
                    Application.Current?.Resources["StrChartJue"]?.ToString() ?? "Thu",
                    Application.Current?.Resources["StrChartVie"]?.ToString() ?? "Fri",
                    Application.Current?.Resources["StrChartSab"]?.ToString() ?? "Sat",
                    Application.Current?.Resources["StrChartDom"]?.ToString() ?? "Sun"
                };
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
                string wkLabel = Application.Current?.Resources["StrChartSem"]?.ToString() ?? "Wk";
                labels = new[] { $"{wkLabel} 1", $"{wkLabel} 2", $"{wkLabel} 3", $"{wkLabel} 4" };
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
                labels = new[] 
                { 
                    Application.Current?.Resources["StrChartEne"]?.ToString() ?? "Jan",
                    Application.Current?.Resources["StrChartFeb"]?.ToString() ?? "Feb",
                    Application.Current?.Resources["StrChartMarMonth"]?.ToString() ?? "Mar",
                    Application.Current?.Resources["StrChartAbr"]?.ToString() ?? "Apr",
                    Application.Current?.Resources["StrChartMay"]?.ToString() ?? "May",
                    Application.Current?.Resources["StrChartJun"]?.ToString() ?? "Jun",
                    Application.Current?.Resources["StrChartJul"]?.ToString() ?? "Jul",
                    Application.Current?.Resources["StrChartAgo"]?.ToString() ?? "Aug",
                    Application.Current?.Resources["StrChartSep"]?.ToString() ?? "Sep",
                    Application.Current?.Resources["StrChartOct"]?.ToString() ?? "Oct",
                    Application.Current?.Resources["StrChartNov"]?.ToString() ?? "Nov",
                    Application.Current?.Resources["StrChartDic"]?.ToString() ?? "Dec"
                };
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
                    Name = approvedName,
                    Values = approvedData,
                    Fill = new SolidColorPaint(SKColor.Parse("#28a745")),
                    Padding = 2
                },
                new ColumnSeries<double>
                {
                    Name = rejectedName,
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
