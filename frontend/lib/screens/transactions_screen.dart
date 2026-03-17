// lib/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/app_state.dart';
import '../widgets/common_widgets.dart';
import 'transaction_detail_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});
  @override State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _filter = 0;
  String _search = '';
  final _searchCtrl = TextEditingController();

  final _filters = ['All', 'Approved', 'Flagged', 'Blocked'];

  List<Transaction> get _filtered {
    var list = AppData.transactions.where((tx) {
      final matchFilter = _filter == 0
        || (_filter == 1 && tx.status == TxStatus.approved)
        || (_filter == 2 && tx.status == TxStatus.flagged)
        || (_filter == 3 && tx.status == TxStatus.blocked);
      final matchSearch = _search.isEmpty
        || tx.name.toLowerCase().contains(_search.toLowerCase())
        || tx.id.toLowerCase().contains(_search.toLowerCase());
      return matchFilter && matchSearch;
    }).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        color: AppColors.card,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Transactions', style: AppText.display(22)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(8)),
              child: Text('${_filtered.length} records', style: AppText.mono(11, color: AppColors.accent)),
            ),
          ]),
          const SizedBox(height: 12),
          // Search bar
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.card2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, color: AppColors.ink3, size: 18),
              const SizedBox(width: 8),
              Expanded(child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: AppText.body(13),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: AppText.body(13, color: AppColors.ink3),
                  border: InputBorder.none,
                  isDense: true,
                ),
              )),
              if (_search.isNotEmpty) GestureDetector(
                onTap: () { _searchCtrl.clear(); setState(() => _search = ''); },
                child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.close, size: 16, color: AppColors.ink3)),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          ChipFilterRow(chips: _filters, selected: _filter, onSelect: (i) => setState(() => _filter = i)),
        ]),
      ),

      // Summary row
      Container(
        color: AppColors.bg,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          _SummaryChip('${AppData.transactions.where((t) => t.status == TxStatus.approved).length}', 'Approved', AppColors.safe),
          const SizedBox(width: 8),
          _SummaryChip('${AppData.transactions.where((t) => t.status == TxStatus.flagged).length}', 'Flagged', AppColors.warn),
          const SizedBox(width: 8),
          _SummaryChip('${AppData.transactions.where((t) => t.status == TxStatus.blocked).length}', 'Blocked', AppColors.danger),
          const Spacer(),
          Text('Total: RM ${AppData.transactions.fold(0.0, (s, t) => s + t.amount).toStringAsFixed(0)}',
            style: AppText.mono(11, color: AppColors.ink2, weight: FontWeight.w600)),
        ]),
      ),

      // List
      Expanded(
        child: _filtered.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('🔍', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('No transactions found', style: AppText.body(14, color: AppColors.ink3)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const BouncingScrollPhysics(),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _TxRow(tx: _filtered[i]),
            ),
      ),
    ]);
  }
}

Widget _SummaryChip(String val, String label, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text('$val $label', style: AppText.body(11, color: color, weight: FontWeight.w600)),
    ]),
  );
}

class _TxRow extends StatelessWidget {
  final Transaction tx;
  const _TxRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(13),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(tx: tx))),
        child: Column(children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: switch (tx.status) {
                  TxStatus.approved => AppColors.accentLight,
                  TxStatus.flagged  => AppColors.warnLight,
                  TxStatus.blocked  => AppColors.dangerLight,
                },
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(tx.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.name, style: AppText.body(13, weight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('${tx.id}  ·  ${tx.platform}', style: AppText.mono(10, color: AppColors.ink3)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('RM ${tx.amount.toStringAsFixed(2)}',
                style: AppText.mono(13, weight: FontWeight.w600,
                  color: tx.status == TxStatus.blocked ? AppColors.danger : AppColors.ink)),
              const SizedBox(height: 4),
              StatusPill(status: tx.status, score: tx.riskScore),
            ]),
          ]),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 8),
          Row(children: [
            _Meta('📍', tx.location),
            const Spacer(),
            _Meta('🕐', '${tx.date} ${tx.time}'),
            const Spacer(),
            RiskBadge(score: tx.riskScore),
          ]),
        ]),
      ),
    );
  }
}

Widget _Meta(String icon, String text) => Row(children: [
  Text(icon, style: const TextStyle(fontSize: 11)),
  const SizedBox(width: 4),
  Text(text, style: AppText.body(10, color: AppColors.ink3), overflow: TextOverflow.ellipsis),
]);
