import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/tester_constants.dart';
import '../../core/navigation/navigation_service.dart';
import '../../core/providers/analytics_provider.dart';
import '../../core/providers/app_state_provider.dart';
import '../../data/services/token_service.dart';
import '../widgets/page_header.dart';

/// Compact in-app view of the admin metrics.
///
/// The full console lives on the web at `<backend>/admin`; this screen exists so
/// the same numbers can be shown on the phone without switching devices.
class AdminPage extends ConsumerStatefulWidget {
  const AdminPage({super.key});

  @override
  ConsumerState<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends ConsumerState<AdminPage> {
  final TokenService _tokenService = TokenService();

  Map<String, dynamic>? _overview;
  List<dynamic> _languages = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsServiceProvider).trackScreenView('Admin Page');
    });
  }

  Future<Map<String, String>> _headers() async {
    final isTester = await _tokenService.isTesterAccount();
    final token =
        isTester ? TesterConstants.testerJwtToken : await _tokenService.getToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _load() async {
    try {
      final headers = await _headers();

      final responses = await Future.wait([
        http.get(
          Uri.parse(ApiConstants.getUrl('/api/admin/stats/overview')),
          headers: headers,
        ),
        http.get(
          Uri.parse(ApiConstants.getUrl('/api/admin/stats/languages')),
          headers: headers,
        ),
      ]).timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (responses[0].statusCode != 200) {
        setState(() {
          _isLoading = false;
          _error = responses[0].statusCode == 404
              ? 'This account does not have admin access.'
              : 'Could not load admin stats.';
        });
        return;
      }

      setState(() {
        _overview = jsonDecode(responses[0].body) as Map<String, dynamic>;
        _languages = responses[1].statusCode == 200
            ? ((jsonDecode(responses[1].body)
                    as Map<String, dynamic>)['languages'] as List<dynamic>? ??
                const [])
            : const [];
        _error = null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load admin stats. Pull down to retry.';
      });
    }
  }

  String _money(dynamic value) => '₹${value ?? 0}';

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(appStateProvider).currentLanguage;
    final o = _overview;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/jesus_backdrop.png'),
                  fit: BoxFit.cover,
                ),
                color: Colors.black.withValues(alpha: 0.78),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  PageHeader(
                    title: AppStrings.get('admin_console', language),
                    onBackPressed: () => NavigationService.pop(),
                    heroTag: 'admin_console_title',
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              children: [
                                if (_error != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 120,
                                      horizontal: 24,
                                    ),
                                    child: Text(
                                      _error!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                else if (o != null) ...[
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 1.55,
                                    children: [
                                      _StatCard(
                                        label: 'Users',
                                        value: '${o['total_users'] ?? 0}',
                                        sub: 'registered',
                                      ),
                                      _StatCard(
                                        label: 'Conversations',
                                        value:
                                            '${o['total_conversations'] ?? 0}',
                                        sub: 'turns logged',
                                      ),
                                      _StatCard(
                                        label: 'Active subs',
                                        value:
                                            '${o['active_subscriptions'] ?? 0}',
                                        sub: '${o['paying_users'] ?? 0} paying',
                                      ),
                                      _StatCard(
                                        label: 'MRR',
                                        value: _money(o['mrr_rupees']),
                                        sub: 'monthly',
                                      ),
                                      _StatCard(
                                        label: 'Free → paid',
                                        value:
                                            '${o['conversion_rate_pct'] ?? 0}%',
                                        sub: 'conversion',
                                      ),
                                      _StatCard(
                                        label: 'Avg latency',
                                        value: o['avg_latency_ms'] != null
                                            ? '${((o['avg_latency_ms'] as num) / 1000).toStringAsFixed(1)}s'
                                            : '—',
                                        sub: 'end to end',
                                      ),
                                    ],
                                  ),
                                  if (_languages.isNotEmpty) ...[
                                    const SizedBox(height: 20),
                                    _LanguageBreakdown(languages: _languages),
                                  ],
                                  const SizedBox(height: 20),
                                  Text(
                                    'Full console: ${ApiConstants.baseUrl}/admin',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.sub});

  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageBreakdown extends StatelessWidget {
  const _LanguageBreakdown({required this.languages});

  final List<dynamic> languages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LANGUAGE SPLIT',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 14),
          ...languages.map((item) {
            final map = item as Map<String, dynamic>;
            final pct = (map['pct'] as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${map['language']}'.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${map['count']} · $pct%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
