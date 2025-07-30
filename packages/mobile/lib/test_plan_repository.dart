import 'package:flutter/material.dart';
import 'data/services/plan_service.dart';
import 'domain/entities/user_plan_entity.dart';
import 'domain/entities/transaction_entity.dart';
import 'core/errors/api_exceptions.dart';

/// Test widget to verify PlanRepository and PlanService functionality
class PlanRepositoryTestWidget extends StatefulWidget {
  const PlanRepositoryTestWidget({super.key});

  @override
  State<PlanRepositoryTestWidget> createState() => _PlanRepositoryTestWidgetState();
}

class _PlanRepositoryTestWidgetState extends State<PlanRepositoryTestWidget> {
  final PlanService _planService = PlanService();
  
  String _testResults = 'No tests run yet';
  bool _isRunning = false;
  UserPlanEntity? _currentPlan;
  List<TransactionEntity> _recentTransactions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Repository Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Plan Repository & Service Test',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            // Current plan status
            if (_currentPlan != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Plan',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Plan: ${_currentPlan!.plan.name}'),
                      Text('Credits: ${_currentPlan!.remainingCredits}/${_currentPlan!.totalCredits}'),
                      Text('Usage: ${(_currentPlan!.usagePercentage * 100).toStringAsFixed(1)}%'),
                      Text('Status: ${_currentPlan!.isActive ? "Active" : "Inactive"}'),
                      Text('Expires: ${_currentPlan!.expirationDate.toLocal().toString().split(' ')[0]}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Recent transactions
            if (_recentTransactions.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...(_recentTransactions.take(3).map((transaction) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${transaction.clinicName} - ${transaction.serviceType}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${transaction.creditsUsed} créditos',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Test buttons
            ElevatedButton(
              onPressed: _isRunning ? null : _testCurrentPlan,
              child: _isRunning 
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Running Tests...'),
                      ],
                    )
                  : const Text('Test Get Current Plan'),
            ),
            
            ElevatedButton(
              onPressed: _isRunning ? null : _testRecentTransactions,
              child: const Text('Test Recent Transactions'),
            ),
            
            ElevatedButton(
              onPressed: _isRunning ? null : _testRefreshPlan,
              child: const Text('Test Refresh Plan Data'),
            ),
            
            ElevatedButton(
              onPressed: _isRunning ? null : _testPlanHistory,
              child: const Text('Test Plan History'),
            ),
            
            ElevatedButton(
              onPressed: _isRunning ? null : _testPlanStatistics,
              child: const Text('Test Plan Statistics'),
            ),
            
            const SizedBox(height: 16),
            
            // Test results
            Card(
              child: Container(
                width: double.infinity,
                height: 300,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _testResults,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Test get current plan functionality
  Future<void> _testCurrentPlan() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Testing current plan retrieval...\\n\\n';
    });

    try {
      _appendResult('🧪 Test: Get Current Plan');
      
      final plan = await _planService.getCurrentPlan();
      
      if (plan != null) {
        setState(() {
          _currentPlan = plan;
        });
        
        _appendResult('✅ Current plan retrieved successfully');
        _appendResult('Plan Name: ${plan.plan.name}');
        _appendResult('Total Credits: ${plan.totalCredits}');
        _appendResult('Used Credits: ${plan.usedCredits}');
        _appendResult('Remaining Credits: ${plan.remainingCredits}');
        _appendResult('Usage: ${(plan.usagePercentage * 100).toStringAsFixed(1)}%');
        _appendResult('Status: ${plan.isActive ? "Active" : "Inactive"}');
        _appendResult('Expires: ${plan.expirationDate.toLocal()}');
        _appendResult('Days until expiration: ${plan.daysUntilExpiration}');
        _appendResult('Status color: ${plan.statusColor}');
        _appendResult('Is running low: ${plan.isRunningLow}');
        _appendResult('Is expired: ${plan.isExpired}\\n');
      } else {
        _appendResult('⚠️ No active plan found');
        _appendResult('User may not have a plan or plan is expired\\n');
      }
      
      // Test has active plan
      _appendResult('🧪 Test: Has Active Plan');
      final hasActive = await _planService.hasActivePlan();
      _appendResult('Has active plan: $hasActive\\n');
      
    } on ApiException catch (e) {
      _appendResult('❌ API Exception: ${e.message}');
      _appendResult('Code: ${e.code}');
      _appendResult('Localized: ${ApiExceptionLocalizer.getLocalizedMessage(e)}\\n');
    } catch (e) {
      _appendResult('❌ Unexpected error: $e\\n');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Test recent transactions functionality
  Future<void> _testRecentTransactions() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Testing recent transactions retrieval...\\n\\n';
    });

    try {
      _appendResult('🧪 Test: Get Recent Transactions');
      
      final transactions = await _planService.getRecentTransactions(limit: 5);
      
      setState(() {
        _recentTransactions = transactions;
      });
      
      if (transactions.isNotEmpty) {
        _appendResult('✅ Recent transactions retrieved successfully');
        _appendResult('Found ${transactions.length} transactions:\\n');
        
        for (int i = 0; i < transactions.length; i++) {
          final transaction = transactions[i];
          _appendResult('${i + 1}. ${transaction.clinicName}');
          _appendResult('   Service: ${transaction.serviceType}');
          _appendResult('   Credits: ${transaction.creditsUsed}');
          _appendResult('   Date: ${transaction.formattedDate}');
          _appendResult('   Status: ${transaction.status}');
          _appendResult('   Value: R\$ ${transaction.value.toStringAsFixed(2)}\\n');
        }
      } else {
        _appendResult('⚠️ No recent transactions found\\n');
      }
      
    } on ApiException catch (e) {
      _appendResult('❌ API Exception: ${e.message}');
      _appendResult('Code: ${e.code}\\n');
    } catch (e) {
      _appendResult('❌ Unexpected error: $e\\n');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Test refresh plan data functionality
  Future<void> _testRefreshPlan() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Testing plan data refresh...\\n\\n';
    });

    try {
      _appendResult('🧪 Test: Refresh Plan Data');
      
      final plan = await _planService.refreshPlanData();
      
      if (plan != null) {
        setState(() {
          _currentPlan = plan;
        });
        
        _appendResult('✅ Plan data refreshed successfully');
        _appendResult('Updated Plan: ${plan.plan.name}');
        _appendResult('Updated Credits: ${plan.remainingCredits}/${plan.totalCredits}\\n');
      } else {
        _appendResult('⚠️ No plan data received after refresh\\n');
      }
      
    } on ApiException catch (e) {
      _appendResult('❌ API Exception: ${e.message}');
      _appendResult('Code: ${e.code}\\n');
    } catch (e) {
      _appendResult('❌ Unexpected error: $e\\n');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Test plan history functionality
  Future<void> _testPlanHistory() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Testing plan history retrieval...\\n\\n';
    });

    try {
      _appendResult('🧪 Test: Get Plan History');
      
      final history = await _planService.getPlanHistory(page: 1, limit: 10);
      
      if (history.isNotEmpty) {
        _appendResult('✅ Plan history retrieved successfully');
        _appendResult('Found ${history.length} transactions in history:\\n');
        
        for (int i = 0; i < history.take(5).length; i++) {
          final transaction = history[i];
          _appendResult('${i + 1}. ${transaction.clinicName} - ${transaction.serviceType}');
          _appendResult('   Credits: ${transaction.creditsUsed}, Date: ${transaction.formattedDate}\\n');
        }
        
        if (history.length > 5) {
          _appendResult('... and ${history.length - 5} more transactions\\n');
        }
      } else {
        _appendResult('⚠️ No plan history found\\n');
      }
      
    } on ApiException catch (e) {
      _appendResult('❌ API Exception: ${e.message}');
      _appendResult('Code: ${e.code}\\n');
    } catch (e) {
      _appendResult('❌ Unexpected error: $e\\n');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Test plan statistics functionality
  Future<void> _testPlanStatistics() async {
    setState(() {
      _isRunning = true;
      _testResults = 'Testing plan statistics retrieval...\\n\\n';
    });

    try {
      _appendResult('🧪 Test: Get Plan Statistics');
      
      final stats = await _planService.getPlanStatistics();
      
      if (stats.isNotEmpty) {
        _appendResult('✅ Plan statistics retrieved successfully');
        _appendResult('Statistics received:\\n');
        
        stats.forEach((key, value) {
          _appendResult('$key: $value');
        });
        _appendResult('');
      } else {
        _appendResult('⚠️ No statistics data received\\n');
      }
      
    } on ApiException catch (e) {
      _appendResult('❌ API Exception: ${e.message}');
      _appendResult('Code: ${e.code}\\n');
    } catch (e) {
      _appendResult('❌ Unexpected error: $e\\n');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  /// Append result to test output
  void _appendResult(String result) {
    setState(() {
      _testResults += '$result\\n';
    });
  }
}

/// Example of how to use PlanService in your app
class PlanServiceUsageExample {
  final PlanService _planService = PlanService();

  /// Example: Load user plan and display in UI
  Future<void> loadUserPlan() async {
    try {
      final plan = await _planService.getCurrentPlan();
      
      if (plan != null) {
        print('User Plan: ${plan.plan.name}');
        print('Credits: ${plan.remainingCredits}/${plan.totalCredits}');
        print('Usage: ${(plan.usagePercentage * 100).toStringAsFixed(1)}%');
        
        // Check if user is running low on credits
        if (plan.isRunningLow) {
          print('⚠️ User is running low on credits!');
        }
        
        // Check if plan is expiring soon
        if (plan.daysUntilExpiration <= 30) {
          print('⚠️ Plan expires in ${plan.daysUntilExpiration} days');
        }
      } else {
        print('User has no active plan');
      }
    } catch (e) {
      print('Error loading user plan: $e');
    }
  }

  /// Example: Load recent transactions for dashboard
  Future<void> loadRecentTransactions() async {
    try {
      final transactions = await _planService.getRecentTransactions(limit: 3);
      
      print('Recent Transactions:');
      for (final transaction in transactions) {
        print('- ${transaction.clinicName}: ${transaction.creditsUsed} credits (${transaction.formattedDate})');
      }
    } catch (e) {
      print('Error loading recent transactions: $e');
    }
  }

  /// Example: Refresh plan data with loading state
  Future<UserPlanEntity?> refreshPlanWithLoading() async {
    try {
      print('Refreshing plan data...');
      final plan = await _planService.refreshPlanData();
      print('Plan data refreshed successfully');
      return plan;
    } catch (e) {
      print('Error refreshing plan data: $e');
      return null;
    }
  }
}