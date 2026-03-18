import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _filter = 0;
  String _search = '';
  final _ctrl = TextEditingController();
  final _filters = ['All', 'Approved', 'Flagged', 'Blocked'];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final filtered = state.transactions.where((tx) {
      final matchesFilter = _filter == 0 ||
          (_filter == 1 && tx.status == TxStatus.approved) ||
          (_filter == 2 && tx.status == TxStatus.flagged) ||
          (_filter == 3 && tx.status == TxStatus.blocked);
      final matchesSearch = _search.isEmpty ||
          tx.name.toLowerCase().contains(_search.toLowerCase()) ||
          tx.id.toLowerCase().contains(_search.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
    final total = state.transactions.fold(0.0, (sum, tx) => sum + tx.amount);

    return Column(
      children: [
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Transactions',
                            style: AppText.h1(22),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(
                          '${filtered.length} records · RM ${total.toStringAsFixed(0)} total',
                          style: AppText.label(12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${filtered.length}',
                      style: AppText.mono(14, color: AppColors.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.card2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.search_rounded, color: AppColors.ink4, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        onChanged: (v) => setState(() => _search = v),
                        style: AppText.body(13),
                        decoration: InputDecoration(
                          hintText: 'Search by name or ID...',
                          hintStyle: AppText.label(13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_search.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _ctrl.clear();
                          setState(() => _search = '');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Icon(Icons.close_rounded,
                              size: 16, color: AppColors.ink3),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ChipFilterRow(
                chips: _filters,
                selected: _filter,
                onSelect: (i) => setState(() => _filter = i),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SChip('${state.transactions.where((t) => t.status == TxStatus.approved).length}', 'Approved', AppColors.safe),
              _SChip('${state.transactions.where((t) => t.status == TxStatus.flagged).length}', 'Flagged', AppColors.warn),
              _SChip('${state.transactions.where((t) => t.status == TxStatus.blocked).length}', 'Blocked', AppColors.danger),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 48, color: AppColors.ink4),
                      const SizedBox(height: 12),
                      Text('No results found',
                          style: AppText.h2(16, color: AppColors.ink3)),
                      const SizedBox(height: 4),
                      Text('Try a different filter or search term',
                          style: AppText.label(13)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _TxRow(tx: filtered[i]),
                ),
        ),
      ],
    );
  }
}

Widget _SChip(String val, String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$val $label',
            style: AppText.label(11, color: color, weight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

class _TxRow extends StatelessWidget {
  final Transaction tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransactionDetailScreen(tx: tx)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: switch (tx.status) {
                      TxStatus.approved => AppColors.accentLight,
                      TxStatus.flagged => AppColors.warnLight,
                      TxStatus.blocked => AppColors.dangerLight,
                    },
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(tx.emoji, style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.name,
                        style: AppText.body(14,
                            color: AppColors.ink, weight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${tx.id} · ${tx.platform}',
                        style: AppText.label(10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RM ${tx.amount.toStringAsFixed(2)}',
                      style: AppText.mono(
                        13,
                        color: tx.status == TxStatus.blocked
                            ? AppColors.danger
                            : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 5),
                    StatusPill(status: tx.status, score: tx.riskScore),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _M('📍', tx.location),
                _M('🕐', '${tx.date} · ${tx.time}'),
                RiskBadge(score: tx.riskScore),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _M(String icon, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Text(
            text,
            style: AppText.label(10),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
