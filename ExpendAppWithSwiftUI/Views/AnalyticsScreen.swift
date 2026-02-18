import SwiftUI
import Charts

struct AnalyticsScreen: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Picker
                    Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                        ForEach(AnalyticsViewModel.TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Total Spending Card
                    totalSpendingCard
                    
                    // Category Breakdown
                    categoryBreakdownSection
                    
                    // Monthly Trends
                    monthlyTrendsSection
                    
                    // Insights
                    insightsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Analytics")
            .background(Color(.systemGroupedBackground))
            .refreshable {
                viewModel.loadAnalyticsData()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(10)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ), presenting: viewModel.errorMessage) { _ in
                Button("Retry") {
                    viewModel.loadAnalyticsData()
                }
                Button("Cancel", role: .cancel) {}
            } message: { error in
                Text(error)
            }
        }
    }
    
    private var totalSpendingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total Spent")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(viewModel.totalSpent.formatted(.currency(code: "USD")))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("across \(viewModel.categorySpending.count) categories")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(viewModel.categorySpending) { item in
                SectorMark(
                    angle: .value("Spending", item.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 1
                )
                .foregroundStyle(item.category.color.gradient)
                .cornerRadius(4)
                .annotation(position: .overlay) {
                    if item.percentage >= 5 {
                        Text("\(Int(item.percentage))%")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(height: 200)
            .chartLegend(alignment: .center, spacing: 16)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal)
            
            // Detailed Breakdown List
            VStack(spacing: 0) {
                ForEach(viewModel.categorySpending) { item in
                    DisclosureGroup {
                        VStack(spacing: 0) {
                            ForEach(item.expenses) { expense in
                                HStack {
                                    Text(expense.title)
                                        .font(.subheadline)
                                    Spacer()
                                    Text(expense.amount.formatted(.currency(code: "USD")))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                
                                if expense != item.expenses.last {
                                    Divider()
                                }
                            }
                        }
                        .padding(.top, 4)
                    } label: {
                        HStack {
                            Circle()
                                .fill(item.category.color)
                                .frame(width: 12, height: 12)
                            
                            Text(item.category.rawValue)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(item.amount.formatted(.currency(code: "USD")))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text("\(Int(item.percentage))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    
                    if item.id != viewModel.categorySpending.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    private var monthlyTrendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Trends")
                .font(.headline)
                .padding(.horizontal)
            
            Chart(viewModel.monthlySpending) { item in
                BarMark(
                    x: .value("Month", item.month),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(Color.blue.gradient)
                .cornerRadius(4)
            }
            .frame(height: 150)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }
    
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Insights")
                .font(.headline)
                .padding(.horizontal)
            
            if let topCategory = viewModel.categorySpending.first {
                InsightCard(
                    icon: "trophy.fill",
                    title: "Top Spending Category",
                    description: "\(topCategory.category.rawValue) - \(topCategory.amount.formatted(.currency(code: "USD")))",
                    color: topCategory.category.color
                )
            }
            
            if viewModel.categorySpending.count >= 2 {
                let secondCategory = viewModel.categorySpending[1]
                InsightCard(
                    icon: "chart.bar.fill",
                    title: "Second Highest",
                    description: "\(secondCategory.category.rawValue) - \(secondCategory.amount.formatted(.currency(code: "USD")))",
                    color: secondCategory.category.color
                )
            }
        }
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

#Preview {
    AnalyticsScreen()
}
