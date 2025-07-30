import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../../data/services/plan_service.dart';
import '../../domain/entities/user_plan_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../controllers/auth_controller.dart';
import '../widgets/widgets.dart';

/// Home screen with bottom navigation for the SingleClin app
/// 
/// This screen provides the main interface for patients to:
/// - View their plan and credit balance
/// - Access QR code generation
/// - View transaction history
/// - Manage their profile
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AuthController _authController = Get.find<AuthController>();
  final PlanService _planService = PlanService();
  late TabController _tabController;
  int _currentIndex = 0;
  
  // Plan data state
  UserPlanEntity? _currentPlan;
  bool _isLoadingPlan = false;
  bool _isUsingCachedData = false;
  
  // Recent transactions state
  List<TransactionEntity> _recentTransactions = [];
  bool _isLoadingTransactions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentIndex = _tabController.index;
      });
    });
    _loadPlanData();
    _loadRecentTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlanView(),
          _buildHistoryView(),
          _buildProfileView(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Build custom app bar with user info and notifications
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SingleClin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Obx(() => Text(
            _authController.currentUser?.displayName ?? 'Usuário',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.white70,
            ),
          )),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            // TODO: Navigate to notifications screen
            _showComingSoonDialog('Notificações');
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Build bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        _tabController.animateTo(index);
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey[600],
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Início',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'Histórico',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }

  /// Build plan view tab (main screen)
  Widget _buildPlanView() {
    return RefreshIndicator(
      onRefresh: _refreshPlanData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome message
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            
            // Plan card - integrated with real data
            PlanCard(
              userPlan: _currentPlan,
              isLoading: _isLoadingPlan,
              onTap: () {
                // TODO: Navigate to plan details screen
                _showComingSoonDialog('Detalhes do plano');
              },
              onRefresh: _loadPlanData,
            ),
            const SizedBox(height: 24),
            
            // QR Code button - will be enhanced in task 9.5
            _buildQRCodeButton(),
            const SizedBox(height: 24),
            
            // Recent visits with real transaction data
            RecentVisitsCard(
              recentTransactions: _recentTransactions,
              isLoading: _isLoadingTransactions,
              onViewAll: () {
                _tabController.animateTo(1); // Switch to history tab
              },
              onRefresh: _loadRecentTransactions,
            ),
          ],
        ),
      ),
    );
  }

  /// Build history view tab
  Widget _buildHistoryView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Histórico de Consultas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Em breve você poderá visualizar\nseu histórico completo de consultas',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Build profile view tab
  Widget _buildProfileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(),
          const SizedBox(height: 24),
          
          // Profile options
          _buildProfileOptions(),
        ],
      ),
    );
  }

  /// Build welcome section
  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bem-vindo!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Gerencie seu plano de saúde de forma simples e prática',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (_isUsingCachedData) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.offline_bolt,
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Dados em cache • Puxe para atualizar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }


  /// Build enhanced QR Code button
  Widget _buildQRCodeButton() {
    final hasActivePlan = _currentPlan != null && _currentPlan!.isActive && !_currentPlan!.isExpired;
    
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasActivePlan 
              ? [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.8)]
              : [Colors.grey, Colors.grey.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: hasActivePlan 
                ? Theme.of(context).primaryColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: hasActivePlan ? () => context.go(AppRoutes.qrGenerate) : null,
        icon: Icon(
          Icons.qr_code_2,
          size: 32,
          color: hasActivePlan ? Colors.white : Colors.white70,
        ),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gerar QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: hasActivePlan ? Colors.white : Colors.white70,
              ),
            ),
            if (!hasActivePlan) ...[
              const SizedBox(height: 2),
              Text(
                'Plano inativo',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ],
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
    );
  }


  /// Build profile header
  Widget _buildProfileHeader() {
    return Obx(() => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).primaryColor,
            backgroundImage: _authController.currentUser?.photoUrl != null
                ? NetworkImage(_authController.currentUser!.photoUrl!)
                : null,
            child: _authController.currentUser?.photoUrl == null
                ? Text(
                    _authController.currentUser?.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            _authController.currentUser?.displayName ?? 'Usuário',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _authController.currentUser?.email ?? '',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    ));
  }

  /// Build profile options
  Widget _buildProfileOptions() {
    return Column(
      children: [
        _buildProfileOption(
          icon: Icons.person_outline,
          title: 'Editar Perfil',
          subtitle: 'Altere suas informações pessoais',
          onTap: () => _showComingSoonDialog('Edição de perfil'),
        ),
        _buildProfileOption(
          icon: Icons.notifications_outlined,
          title: 'Notificações',
          subtitle: 'Configure suas preferências de notificação',
          onTap: () => _showComingSoonDialog('Configurações de notificação'),
        ),
        _buildProfileOption(
          icon: Icons.security_outlined,
          title: 'Segurança',
          subtitle: 'Altere sua senha e configurações de segurança',
          onTap: () => _showComingSoonDialog('Configurações de segurança'),
        ),
        _buildProfileOption(
          icon: Icons.help_outline,
          title: 'Suporte',
          subtitle: 'Precisa de ajuda? Entre em contato conosco',
          onTap: () => _showComingSoonDialog('Suporte'),
        ),
        _buildProfileOption(
          icon: Icons.info_outline,
          title: 'Sobre',
          subtitle: 'Informações sobre o aplicativo',
          onTap: () => context.go(AppRoutes.about),
        ),
        const SizedBox(height: 16),
        _buildProfileOption(
          icon: Icons.logout,
          title: 'Sair',
          subtitle: 'Desconectar da sua conta',
          onTap: _showLogoutDialog,
          isDestructive: true,
        ),
      ],
    );
  }

  /// Build individual profile option
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.red : Theme.of(context).primaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  /// Load plan data from API (uses cache when available)
  Future<void> _loadPlanData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingPlan = true;
      _isUsingCachedData = false;
    });

    try {
      // Check if we'll use cached data
      final hasCachedData = await _planService.hasCachedPlanData();
      
      final plan = await _planService.getCurrentPlan();
      
      if (mounted) {
        setState(() {
          _currentPlan = plan;
          _isLoadingPlan = false;
          _isUsingCachedData = hasCachedData;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPlan = false;
          _isUsingCachedData = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados do plano: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Load recent transactions data
  Future<void> _loadRecentTransactions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final transactions = await _planService.getRecentTransactions(limit: 5);
      
      if (mounted) {
        setState(() {
          _recentTransactions = transactions;
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
        // Don't show error for transactions as it's not critical
      }
    }
  }

  /// Refresh plan data (pull-to-refresh)
  Future<void> _refreshPlanData() async {
    try {
      // Force refresh from server (bypasses cache)
      final plan = await _planService.refreshPlanData();
      
      // Also refresh recent transactions
      _loadRecentTransactions();
      
      if (mounted) {
        setState(() {
          _currentPlan = plan;
          _isUsingCachedData = false; // Data is fresh from server
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    plan != null 
                        ? 'Dados atualizados com sucesso!'
                        : 'Nenhum plano ativo encontrado',
                  ),
                ),
              ],
            ),
            backgroundColor: plan != null ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Erro ao atualizar dados: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: _refreshPlanData,
            ),
          ),
        );
      }
    }
  }

  /// Show coming soon dialog
  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Em Breve'),
        content: Text('A funcionalidade "$feature" estará disponível em breve!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Tem certeza de que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _authController.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}