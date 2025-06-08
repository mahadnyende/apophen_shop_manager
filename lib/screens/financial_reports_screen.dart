// lib/screens/financial_reports_screen.dart
import 'package:flutter/material.dart';
import 'package:apophen_shop_manager/services/pos_service.dart';
import 'package:apophen_shop_manager/services/expense_service.dart';
import 'package:apophen_shop_manager/data/models/pos/sale_model.dart';
import 'package:apophen_shop_manager/data/models/purchases/expense_model.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'package:apophen_shop_manager/services/inventory_service.dart';
import 'package:apophen_shop_manager/data/models/inventory/product_model.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final POSService _posService = POSService();
  final ExpenseService _expenseService = ExpenseService();
  final InventoryService _inventoryService = InventoryService();

  double _totalSalesRevenue = 0.0;
  double _totalCostOfGoodsSold = 0.0;
  double _grossProfit = 0.0;
  double _netProfit = 0.0;
  double _totalExpenses = 0.0; 

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  List<Sale> _allSales = [];
  List<Expense> _allExpenses = [];
  List<Product> _allProducts = [];

  Map<String, double> _expensesByCategory = {};
  Map<DateTime, double> _dailySales = {};
  Map<DateTime, double> _dailyExpenses = {};
  Map<String, double> _productProfits = {};

  Map<String, double> _salesByProduct = {};
  Map<String, double> _salesByCategory = {};
  Map<String, double> _grossProfitByProduct = {};


  bool _showPositiveProfitSalesOnly = false;
  bool _showPositiveExpenseAmountsOnly = false;

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  @override
  void dispose() {
    _posService.dispose();
    _expenseService.dispose();
    _inventoryService.dispose();
    super.dispose();
  }

  Future<void> _loadFinancialData() async {
    _posService.getSales().listen((sales) {
      _allSales = sales;
      _calculateFinancials();
    }, onError: (error) {
      print('Error loading sales for financial reports: $error');
    });

    _expenseService.getExpenses().listen((expenses) {
      _allExpenses = expenses;
      _calculateFinancials();
    }, onError: (error) {
      print('Error loading expenses for financial reports: $error');
    });

    _inventoryService.getProducts().listen((products) {
      _allProducts = products;
      _calculateFinancials();
    }, onError: (error) {
      print('Error loading products for financial reports: $error');
    });
  }

  void _calculateFinancials() {
    final filteredSales = _allSales.where((sale) =>
        sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        sale.saleDate.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    final filteredExpenses = _allExpenses.where((expense) =>
        expense.expenseDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        expense.expenseDate.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    double salesSum = filteredSales.fold(0.0, (sum, sale) => sum + sale.finalTotalAmount);
    
    double cogsSum = 0.0;
    _salesByProduct = {};
    _salesByCategory = {};
    _grossProfitByProduct = {};

    for (var sale in filteredSales) {
      for (var item in sale.items) {
        cogsSum += item.costPrice * item.quantity;

        _salesByProduct.update(
          item.productName,
          (value) => value + item.finalSubtotal,
          ifAbsent: () => item.finalSubtotal,
        );

        _grossProfitByProduct.update(
          item.productName,
          (value) => value + item.grossProfit,
          ifAbsent: () => item.grossProfit,
        );

        final product = _allProducts.firstWhere(
          (p) => p.id == item.productId,
          orElse: () => Product(productSku: 'unknown', name: 'Unknown Product', price: 0, costPrice: 0, stockQuantity: 0, category: 'Unknown'),
        );
        _salesByCategory.update(
          product.category,
          (value) => value + item.finalSubtotal,
          ifAbsent: () => item.finalSubtotal,
        );
      }
    }

    double expensesSum = filteredExpenses.fold(0.0, (sum, expense) => sum + expense.amount);

    final Map<String, double> tempExpensesByCategory = {};
    for (var expense in filteredExpenses) {
      tempExpensesByCategory.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final Map<DateTime, double> tempDailySales = {};
    for (var sale in filteredSales) {
      final normalizedDate = DateTime(sale.saleDate.year, sale.saleDate.month, sale.saleDate.day);
      tempDailySales.update(
        normalizedDate,
        (value) => value + sale.finalTotalAmount,
        ifAbsent: () => sale.finalTotalAmount,
      );
    }

    final Map<DateTime, double> tempDailyExpenses = {};
    for (var expense in filteredExpenses) {
      final normalizedDate = DateTime(expense.expenseDate.year, expense.expenseDate.month, expense.expenseDate.day);
      tempDailyExpenses.update(
        normalizedDate,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final Map<String, double> tempProductProfits = {};
    for (var sale in filteredSales) {
      for (var item in sale.items) {
        tempProductProfits.update(
          item.productName,
          (value) => value + item.grossProfit,
          ifAbsent: () => item.grossProfit,
        );
      }
    }


    setState(() {
      _totalSalesRevenue = salesSum;
      _totalCostOfGoodsSold = cogsSum;
      _grossProfit = salesSum - cogsSum;
      _netProfit = _grossProfit - expensesSum;
      _totalExpenses = expensesSum; 
      _expensesByCategory = tempExpensesByCategory;
      _dailySales = tempDailySales;
      _dailyExpenses = tempDailyExpenses;
      _productProfits = tempProductProfits;
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null && (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _calculateFinancials();
      });
    }
  }

  void _exportDataToCsv() {
    final List<Sale> salesToExport = _allSales.where((sale) =>
        sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        sale.saleDate.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    final List<Expense> expensesToExport = _allExpenses.where((expense) =>
        expense.expenseDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        expense.expenseDate.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    // Sales CSV
    final salesCsvRows = <List<String>>[];
    salesCsvRows.add(['Sale ID', 'Date', 'Subtotal', 'Discount', 'Total Amount', 'Customer ID', 'Employee ID', 'Product SKU', 'Product Name', 'Quantity', 'Base Price', 'Cost Price', 'Item Discount', 'Item Profit']);
    for (final sale in salesToExport) {
      final saleDateFormatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(sale.saleDate);
      final baseRow = [
        sale.id ?? 'N/A',
        saleDateFormatted,
        sale.subtotalBeforeDiscount.toStringAsFixed(2),
        sale.overallDiscountAmount.toStringAsFixed(2),
        sale.finalTotalAmount.toStringAsFixed(2),
        sale.customerId ?? 'Walk-in',
        sale.employeeId ?? 'N/A',
      ];
      if (sale.items.isEmpty) {
        salesCsvRows.add([...baseRow, '', '', '', '', '', '']);
      } else {
        for (final item in sale.items) {
          salesCsvRows.add([
            ...baseRow,
            item.productSku,
            item.productName,
            item.quantity.toString(),
            item.basePrice.toStringAsFixed(2),
            item.costPrice.toStringAsFixed(2),
            item.itemDiscount.toStringAsFixed(2),
            item.grossProfit.toStringAsFixed(2),
          ]);
        }
      }
    }

    // Expenses CSV
    final expensesCsvRows = <List<String>>[];
    expensesCsvRows.add(['Expense ID', 'Title', 'Description', 'Amount', 'Date', 'Category']);
    for (final expense in expensesToExport) {
      final expenseDateFormatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(expense.expenseDate);
      expensesCsvRows.add([
        expense.id ?? 'N/A',
        expense.title,
        expense.description ?? '',
        expense.amount.toStringAsFixed(2),
        expenseDateFormatted,
        expense.category,
      ]);
    }

    String salesCsvContent = salesCsvRows.map((row) => row.map(_csvEncode).join(',')).join('\n');
    String expensesCsvContent = expensesCsvRows.map((row) => row.map(_csvEncode).join(',')).join('\n');

    _downloadCsv(salesCsvContent, 'sales_report_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.csv');
    _downloadCsv(expensesCsvContent, 'expenses_report_${DateFormat('yyyyMMdd').format(_startDate)}_${DateFormat('yyyyMMdd').format(_endDate)}.csv');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Financial data exported to CSV!')),
    );
  }

  String _csvEncode(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  void _downloadCsv(String csvContent, String filename) {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  List<Widget> _buildProductProfitabilityList() {
    final List<MapEntry<String, double>> sortedEntries = _productProfits.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.map((entry) => Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          '\$${entry.value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: entry.value >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    )).toList();
  }

  List<Widget> _buildSalesByProductList() {
    final List<MapEntry<String, double>> sortedEntries = _salesByProduct.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.map((entry) {
      final productName = entry.key;
      final totalRevenue = entry.value;
      final productGrossProfit = _grossProfitByProduct[productName] ?? 0.0;

      return Card(
        margin: const EdgeInsets.only(bottom: 8.0),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: ListTile(
          title: Text(productName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Revenue: \$${totalRevenue.toStringAsFixed(2)}'),
          trailing: Text(
            'Profit: \$${productGrossProfit.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: productGrossProfit >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildSalesByCategoryList() {
    final List<MapEntry<String, double>> sortedEntries = _salesByCategory.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.map((entry) => Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: ListTile(
        title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(
          '\$${entry.value.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
      ),
    )).toList();
  }


  @override
  Widget build(BuildContext context) {
    List<Sale> displaySales = _allSales.where((sale) =>
        sale.saleDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        sale.saleDate.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    List<Expense> displayExpenses = _allExpenses.where((expense) =>
        expense.expenseDate.isAfter(_startDate.subtract(const Duration(days: 1))) &&
        expense.expenseDate.isBefore(_endDate.add(const Duration(days: 1))))
        .toList();

    if (_showPositiveProfitSalesOnly) {
      displaySales = displaySales.where((sale) {
        final saleProfit = sale.items.fold(0.0, (sum, item) => sum + item.grossProfit);
        return saleProfit > 0;
      }).toList();
    }

    if (_showPositiveExpenseAmountsOnly) {
      displayExpenses = displayExpenses.where((expense) => expense.amount > 0).toList();
    }

    displaySales.sort((a, b) => b.saleDate.compareTo(a.saleDate));
    displayExpenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

    final sortedExpensesByCategory = _expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final double maxExpenseAmount = sortedExpensesByCategory.isEmpty
        ? 1.0
        : sortedExpensesByCategory.first.value;

    final List<PieChartSectionData> pieChartSections = [];
    final List<Color> pieChartColors = [
      Colors.blue, Colors.green, Colors.red, Colors.purple, Colors.orange,
      Colors.teal, Colors.brown, Colors.cyan, Colors.indigo, Colors.lime,
    ];
    double totalExpensesForChart = _expensesByCategory.values.fold(0.0, (sum, amount) => sum + amount);
    
    int colorIndex = 0;
    for (var entry in sortedExpensesByCategory) {
      final isNotEmpty = totalExpensesForChart > 0;
      final percentage = isNotEmpty ? (entry.value / totalExpensesForChart * 100) : 0.0;

      pieChartSections.add(
        PieChartSectionData(
          color: pieChartColors[colorIndex % pieChartColors.length],
          value: entry.value,
          title: isNotEmpty && percentage >= 5 ? '${percentage.toStringAsFixed(1)}%' : '',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: isNotEmpty ? _Badge(entry.key, pieChartColors[colorIndex % pieChartColors.length]) : null,
          badgePositionPercentageOffset: 1.0,
        ),
      );
      colorIndex++;
    }

    List<DateTime> datesInRange = [];
    for (int i = 0; i <= _endDate.difference(_startDate).inDays; i++) {
      datesInRange.add(DateTime(_startDate.year, _startDate.month, _startDate.day + i));
    }

    final List<FlSpot> salesSpots = [];
    double maxY = 0.0;
    for (int i = 0; i < datesInRange.length; i++) {
      final date = datesInRange[i];
      final salesAmount = _dailySales[date] ?? 0.0;
      salesSpots.add(FlSpot(i.toDouble(), salesAmount));
      if (salesAmount > maxY) maxY = salesAmount;
    }
    maxY = maxY * 1.1;
    if (maxY == 0.0) maxY = 10.0;


    final List<BarChartGroupData> barGroups = [];
    double maxBarY = 0.0;
    for (int i = 0; i < datesInRange.length; i++) {
      final date = datesInRange[i];
      final salesAmount = _dailySales[date] ?? 0.0;
      final expensesAmount = _dailyExpenses[date] ?? 0.0;

      if ((salesAmount + expensesAmount) > maxBarY) {
        maxBarY = salesAmount + expensesAmount;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              fromY: 0,
              toY: salesAmount,
              color: Colors.green.withOpacity(0.7),
              width: 10,
              borderRadius: BorderRadius.zero,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxBarY,
                color: Colors.grey.withOpacity(0.2),
              ),
            ),
            BarChartRodData(
              fromY: salesAmount,
              toY: salesAmount + expensesAmount,
              color: Colors.red.withOpacity(0.7),
              width: 10,
              borderRadius: BorderRadius.zero,
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxBarY,
                color: Colors.transparent,
              ),
            ),
          ],
          showingTooltipIndicators: [0, 1],
        ),
      );
    }
    maxBarY = maxBarY * 1.1;
    if (maxBarY == 0.0) maxBarY = 10.0;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF6A1B9A),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white),
            tooltip: 'Select Date Range',
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Export Data to CSV',
            onPressed: _exportDataToCsv,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Date Range Display
              Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, color: Colors.deepPurple, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Report Period: ${DateFormat('MMM d,yyyy').format(_startDate)} - ${DateFormat('MMM d,yyyy').format(_endDate)}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _selectDateRange(context),
                        child: const Text('Change', style: TextStyle(color: Colors.blueAccent)),
                      ),
                    ],
                  ),
                ),
              ),
              // Summary Cards
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryCard(
                        'Total Sales Revenue',
                        '\$${_totalSalesRevenue.toStringAsFixed(2)}',
                        Colors.green,
                        Icons.attach_money,
                      ),
                      _buildSummaryCard(
                        'Total Cost of Goods Sold',
                        '\$${_totalCostOfGoodsSold.toStringAsFixed(2)}',
                        Colors.orange,
                        Icons.money_off_csred,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryCard(
                        'Gross Profit',
                        '\$${_grossProfit.toStringAsFixed(2)}',
                        _grossProfit >= 0 ? Colors.teal : Colors.red,
                        _grossProfit >= 0 ? Icons.show_chart : Icons.area_chart_outlined,
                      ),
                      _buildSummaryCard(
                        'Total Expenses',
                        '\$${_totalExpenses.toStringAsFixed(2)}',
                        Colors.redAccent,
                        Icons.money_off,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSummaryCard(
                        'Net Profit',
                        '\$${_netProfit.toStringAsFixed(2)}',
                        _netProfit >= 0 ? Colors.blueAccent : Colors.orange,
                        _netProfit >= 0 ? Icons.trending_up : Icons.trending_down,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Sales Trend Chart
              Text(
                'Sales Trend Over Period',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),
              if (salesSpots.isEmpty || _totalSalesRevenue == 0.0)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No sales data to display for this period.', style: TextStyle(color: Colors.grey)),
                )
              else
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            getDrawingHorizontalLine: (value) {
                              return const FlLine(
                                color: Color(0xff37434d),
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return const FlLine(
                                color: Color(0xff37434d),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < datesInRange.length) {
                                    final date = datesInRange[value.toInt()];
                                    return SideTitleWidget(
                                      // Removed axisSide, as it's not present in fl_chart 1.0.0
                                      child: Text(DateFormat('MMM d').format(date),
                                          style: const TextStyle(fontSize: 10)),
                                    );
                                  }
                                  return const Text('');
                                },
                                interval: (datesInRange.length / 5).ceil().toDouble(),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: const Color(0xff37434d), width: 1),
                          ),
                          minX: 0,
                          maxX: (datesInRange.length - 1).toDouble(),
                          minY: 0,
                          maxY: maxY,
                          lineBarsData: [
                            LineChartBarData(
                              spots: salesSpots,
                              isCurved: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.greenAccent.withOpacity(0.8),
                                  Colors.blueAccent.withOpacity(0.8),
                                ],
                              ),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.greenAccent.withOpacity(0.3),
                                    Colors.blueAccent.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          lineTouchData: const LineTouchData(enabled: true),
                        ),
                      ),
                    ),
                  ),

              const SizedBox(height: 20),

              // Sales vs Expenses Bar Chart
              Text(
                'Daily Sales vs Expenses',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),
              if (barGroups.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('No sales or expenses data to display for this period.', style: TextStyle(color: Colors.grey)),
                )
              else
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      height: 250,
                      child: BarChart(
                        BarChartData(
                          barGroups: barGroups,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            getDrawingHorizontalLine: (value) {
                              return const FlLine(
                                color: Color(0xff37434d),
                                strokeWidth: 1,
                              );
                            },
                            getDrawingVerticalLine: (value) {
                              return const FlLine(
                                color: Color(0xff37434d),
                                strokeWidth: 1,
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < datesInRange.length) {
                                    final date = datesInRange[value.toInt()];
                                    return SideTitleWidget(
                                      // Removed axisSide, as it's not present in fl_chart 1.0.0
                                      child: Text(DateFormat('MMM d').format(date),
                                          style: const TextStyle(fontSize: 10)),
                                    );
                                  }
                                  return const Text('');
                                },
                                interval: (datesInRange.length / 5).ceil().toDouble(),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text('\$${value.toInt()}', style: const TextStyle(fontSize: 10));
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: const Color(0xff37434d), width: 1),
                          ),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                String text;
                                if (rodIndex == 0) {
                                  text = 'Sales: \$${rod.toY.toStringAsFixed(2)}';
                                } else {
                                  text = 'Expenses: \$${(rod.toY - group.barRods[0].toY).toStringAsFixed(2)}';
                                }
                                return BarTooltipItem(
                                  text,
                                  const TextStyle(color: Colors.white),
                                );
                              },
                            ),
                          ),
                          minY: 0,
                          maxY: maxBarY,
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 20),

              // NEW: Sales by Product Section
              Text(
                'Sales by Product',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),
              _salesByProduct.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No product sales data for this period.', style: TextStyle(color: Colors.grey)),
                    )
                  : Column(
                      children: _buildSalesByProductList(),
                    ),
              const SizedBox(height: 20),

              // NEW: Sales by Category Section
              Text(
                'Sales by Category',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),
              _salesByCategory.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No sales data by category for this period.', style: TextStyle(color: Colors.grey)),
                    )
                  : Column(
                      children: _buildSalesByCategoryList(),
                    ),
              const SizedBox(height: 20),


              // Expenses by Category Breakdown
              Text(
                'Expenses by Category',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),
              sortedExpensesByCategory.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No categorized expenses for this period.', style: TextStyle(color: Colors.grey)),
                    )
                  : Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: PieChart(
                            PieChartData(
                              sections: pieChartSections,
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                              borderData: FlBorderData(show: false),
                              pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    return;
                                  }
                                });
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Column(
                            children: sortedExpensesByCategory.map((entry) => Card(
                                  margin: const EdgeInsets.only(bottom: 8.0),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text('\$${entry.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: entry.value / maxExpenseAmount,
                                          backgroundColor: Colors.grey[200],
                                          color: Colors.redAccent.withOpacity(0.7),
                                          minHeight: 8,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ],
                                    ),
                                  ),
                                )).toList(),
                          ),
                      ],
                    ),
              const SizedBox(height: 20),

              // Product Profitability Breakdown
              Text(
                'Product Profitability',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              const SizedBox(height: 10),
              _productProfits.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No product profit data for this period.', style: TextStyle(color: Colors.grey)),
                    )
                  : Column(
                      children: _buildProductProfitabilityList(),
                    ),
              const SizedBox(height: 20),


              // Detailed Sales List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sales Breakdown (${displaySales.length} transactions)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                  Row(
                    children: [
                      const Text('Positive Profit Only', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Switch(
                        value: _showPositiveProfitSalesOnly,
                        onChanged: (bool value) {
                          setState(() {
                            _showPositiveProfitSalesOnly = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              displaySales.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No sales for this period or matching filter.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displaySales.length,
                      itemBuilder: (context, index) {
                        final sale = displaySales[index];
                        final saleDateFormatted = DateFormat('yyyy-MM-dd HH:mm').format(sale.saleDate);
                        final totalProfit = sale.items.fold(0.0, (sum, item) => sum + item.grossProfit);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          child: ExpansionTile(
                            title: Text('Sale ID: ${sale.id!.substring(0, 8)}...'),
                            subtitle: Text('Total: \$${sale.finalTotalAmount.toStringAsFixed(2)} | Profit: \$${totalProfit.toStringAsFixed(2)} | Date: $saleDateFormatted'),
                            children: sale.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text('${item.productName} (x${item.quantity})')),
                                      Text('\$${item.finalSubtotal.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                )).toList(),
                          ),
                        );
                      },
                    ),

              const SizedBox(height: 20),

              // Detailed Expenses List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Expenses Breakdown (${displayExpenses.length} transactions)',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                  ),
                  Row(
                    children: [
                      const Text('Positive Amounts Only', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Switch(
                        value: _showPositiveExpenseAmountsOnly,
                        onChanged: (bool value) {
                          setState(() {
                            _showPositiveExpenseAmountsOnly = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              displayExpenses.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('No expenses for this period or matching filter.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = displayExpenses[index];
                        final expenseDateFormatted = DateFormat('yyyy-MM-dd HH:mm').format(expense.expenseDate);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          child: ListTile(
                            title: Text(expense.title),
                            subtitle: Text('Category: ${expense.category} | Date: $expenseDateFormatted'),
                            trailing: Text('-\$${expense.amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
        elevation: 6,
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color.withOpacity(0.8)),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Extension to capitalize first letter (used for status text)
extension StringExtension on String {
  String get capitalizeFirst {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
