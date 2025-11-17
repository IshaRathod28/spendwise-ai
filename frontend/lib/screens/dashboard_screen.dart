import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/transaction_provider.dart';
import '../models/transaction.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedPeriod = 'All Time';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<TransactionProvider>(context, listen: false).fetchTransactions());
  }

  // Filter transactions by date range
  List<Transaction> _getFilteredTransactions(List<Transaction> transactions) {
    if (_startDate == null && _endDate == null) {
      return transactions;
    }

    return transactions.where((transaction) {
      final transactionDate = transaction.createdAt;
      
      // Check if transaction is within the date range
      if (_startDate != null && transactionDate.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && transactionDate.isAfter(_endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  // Get daily spending data for line chart
  Map<DateTime, double> _getDailySpending(List<Transaction> transactions) {
    final Map<DateTime, double> dailySpending = {};
    
    // Add transaction amounts to their respective dates
    for (var transaction in transactions) {
      final date = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );
      dailySpending[date] = (dailySpending[date] ?? 0) + transaction.amount;
    }
    
    // If we have a date range filter, fill in all dates with 0 for missing days
    if (_startDate != null && _endDate != null && dailySpending.isNotEmpty) {
      final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
      final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
      
      DateTime currentDate = start;
      while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
        dailySpending.putIfAbsent(currentDate, () => 0);
        currentDate = currentDate.add(const Duration(days: 1));
      }
    }
    
    return Map.fromEntries(
      dailySpending.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
  }

  // Calculate average daily spending
  double _getAverageDailySpending(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0;
    
    final dailySpending = _getDailySpending(transactions);
    if (dailySpending.isEmpty) return 0;
    
    final total = dailySpending.values.reduce((a, b) => a + b);
    return total / dailySpending.length;
  }

  // Calculate optimal date interval for X-axis based on number of days
  double _calculateDateInterval(int totalDays) {
    if (totalDays <= 7) {
      return 1; // Show every day for a week or less
    } else if (totalDays <= 14) {
      return 2; // Show every 2 days for 2 weeks
    } else if (totalDays <= 30) {
      return 3; // Show every 3 days for a month
    } else if (totalDays <= 60) {
      return 5; // Show every 5 days for 2 months
    } else if (totalDays <= 90) {
      return 7; // Show every week for 3 months
    } else {
      return (totalDays / 10).ceilToDouble(); // Show approximately 10 labels
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedPeriod = 'Custom';
      });
    }
  }

  void _setPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();
      
      switch (period) {
        case 'Today':
          _startDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'This Week':
          // Start from Monday at 00:00:00
          final daysToMonday = now.weekday - 1;
          final monday = now.subtract(Duration(days: daysToMonday));
          _startDate = DateTime(monday.year, monday.month, monday.day, 0, 0, 0);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'This Month':
          _startDate = DateTime(now.year, now.month, 1, 0, 0, 0);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Last 7 Days':
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          _startDate = DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day, 0, 0, 0);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'Last 30 Days':
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          _startDate = DateTime(thirtyDaysAgo.year, thirtyDaysAgo.month, thirtyDaysAgo.day, 0, 0, 0);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'All Time':
          _startDate = null;
          _endDate = null;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Provider.of<TransactionProvider>(context, listen: false).fetchTransactions();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading && provider.transactions.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (provider.error != null && provider.transactions.isEmpty) {
              return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.fetchTransactions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.transactions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 80,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start by adding your first expense',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/upload');
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
            );
          }

          final filteredTransactions = _getFilteredTransactions(provider.transactions);
          final filteredTotal = filteredTransactions.fold<double>(
            0, (sum, t) => sum + t.amount
          );

          return RefreshIndicator(
            onRefresh: provider.fetchTransactions,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 16),

                    // Summary Cards
                    _buildSummaryCards(filteredTransactions, filteredTotal),
                    const SizedBox(height: 24),

                    // Daily Spending Graph
                    if (filteredTransactions.isNotEmpty) ...[
                      Text(
                        'Daily Spending Trend',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildDailySpendingChart(filteredTransactions),
                      const SizedBox(height: 24),
                    ],

                    // Category Chart
                    if (filteredTransactions.isNotEmpty) ...[
                      Text(
                        'Spending by Category',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryChart(filteredTransactions, filteredTotal),
                      const SizedBox(height: 24),
                    ],

                    // Transactions List or Motivational Message
                    if (filteredTransactions.isEmpty && _selectedPeriod == 'Today') ...[
                      _buildNoSpendingMotivation(),
                    ] else ...[
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildTransactionsList(filteredTransactions, provider),
                    ],
                  ],
                ),
              ),
            ),
          );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/upload');
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['Today', 'This Week', 'This Month', 'Last 7 Days', 'Last 30 Days', 'All Time'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: periods.map((period) {
                  final isSelected = _selectedPeriod == period;
                  return FilterChip(
                        label: Text(period),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) _setPeriod(period);
                        },
                        selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
            ),
            IconButton.filled(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.calendar_today_rounded, size: 20),
              tooltip: 'Custom Date Range',
              style: IconButton.styleFrom(
                backgroundColor: _selectedPeriod == 'Custom' 
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
            ),
          ],
        ),
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.date_range,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM dd').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCards(List<Transaction> transactions, double totalSpent) {
    final avgDaily = _getAverageDailySpending(transactions);
    final dailySpending = _getDailySpending(transactions);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        transactions.length.toString(),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'transactions',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.currency_rupee_rounded,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Spent',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${totalSpent.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'total amount',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_down_rounded,
                            color: Theme.of(context).colorScheme.tertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Daily Avg',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${avgDaily.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'per day',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Days',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dailySpending.length.toString(),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      Text(
                        'with spending',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailySpendingChart(List<Transaction> transactions) {
    final dailySpending = _getDailySpending(transactions);
    
    if (dailySpending.isEmpty) return const SizedBox.shrink();

    final entries = dailySpending.entries.toList();
    final maxAmount = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minAmount = entries.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    
    // If all values are 0, set a default max for chart scaling
    final effectiveMaxAmount = maxAmount == 0 ? 100.0 : maxAmount;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trend Analysis',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${entries.length} days tracked',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '₹${maxAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 280,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      verticalInterval: _calculateDateInterval(entries.length),
                      horizontalInterval: effectiveMaxAmount / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.05),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          interval: _calculateDateInterval(entries.length),
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= entries.length || value.toInt() < 0) {
                              return const Text('');
                            }
                            final date = entries[value.toInt()].key;
                            // Show different format based on duration
                            final format = entries.length <= 7 
                                ? 'dd\nMMM' 
                                : entries.length <= 30 
                                    ? 'dd\nMMM'
                                    : 'dd\nMMM';
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                DateFormat(format).format(date),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: entries.length > 30 ? 8 : 9,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          interval: effectiveMaxAmount / 4,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '₹${(value / 1000).toStringAsFixed(value >= 1000 ? 1 : 0)}${value >= 1000 ? 'k' : ''}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  minY: 0,
                  maxY: effectiveMaxAmount * 1.2,
                  lineBarsData: [
                    // Main line
                    LineChartBarData(
                      spots: entries.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.value,
                        );
                      }).toList(),
                      isCurved: true,
                      curveSmoothness: 0.4,
                      preventCurveOverShooting: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            Theme.of(context).colorScheme.primary.withOpacity(0.05),
                            Theme.of(context).colorScheme.primary.withOpacity(0.0),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      shadow: Shadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 12,
                      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      tooltipMargin: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date = entries[spot.x.toInt()].key;
                          final amount = spot.y;
                          return LineTooltipItem(
                            '',
                            const TextStyle(),
                            children: [
                              TextSpan(
                                text: '${DateFormat('MMM dd, yyyy').format(date)}\n',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: '₹${amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                    touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                      // Add haptic feedback or animations here if needed
                    },
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((spotIndex) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            strokeWidth: 2,
                            dashArray: [5, 5],
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 8,
                                color: Theme.of(context).colorScheme.primary,
                                strokeWidth: 3,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoSpendingMotivation() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Celebration Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              
              // Motivational Message
              Text(
                'Great Job! 🎉',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'No spending today!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re doing an amazing job managing your expenses! Keep up the good work! 💪',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Reminder Section
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(height: 16),
              Text(
                'Did you miss adding a transaction?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Don\'t worry! You can still add any missed expenses.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Add Transaction Button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/upload');
                },
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text(
                  'Add Missed Transaction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 4,
                  shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChart(List<Transaction> transactions, double totalSpent) {
    // Calculate category totals from filtered transactions
    final Map<TransactionCategory, double> categoryTotals = {};
    for (var transaction in transactions) {
      categoryTotals[transaction.category] = 
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              height: 200,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: PieChart(
                PieChartData(
                  sections: categoryTotals.entries.map((entry) {
                    final percentage = (entry.value / totalSpent) * 100;
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 70,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      color: _getCategoryColor(entry.key),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: categoryTotals.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entry.key.icon} ${entry.key.label}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions, TransactionProvider provider) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getCategoryColor(transaction.category).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction.category.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            title: Text(
              transaction.note,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(transaction.category.label),
                if (transaction.merchant != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.merchant!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing: SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${transaction.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Transaction?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      final success = await provider.deleteTransaction(transaction.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Transaction deleted'
                                  : 'Failed to delete transaction',
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return Colors.orange;
      case TransactionCategory.transportation:
        return Colors.blue;
      case TransactionCategory.shopping:
        return Colors.purple;
      case TransactionCategory.groceries:
        return Colors.green;
      case TransactionCategory.utilities:
        return Colors.amber;
      case TransactionCategory.entertainment:
        return Colors.pink;
      case TransactionCategory.healthcare:
        return Colors.red;
      case TransactionCategory.education:
        return Colors.indigo;
      case TransactionCategory.rent:
        return Colors.brown;
      case TransactionCategory.personal:
        return Colors.teal;
      case TransactionCategory.other:
        return Colors.grey;
    }
  }
}
