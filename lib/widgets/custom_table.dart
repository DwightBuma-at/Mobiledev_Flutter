import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CustomTable extends StatelessWidget {
  const CustomTable({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    required this.emptyText,
    this.searchPlaceholder,
    this.showHeader = true,
    this.framed = true,
    this.horizontalMargin = 24,
    this.columnSpacing = 48,
    this.headingRowHeight = 56,
    this.dataRowMinHeight = 62,
    this.dataRowMaxHeight = 72,
    this.onSearchChanged,
  });

  final String title;
  final List<String> columns;
  final List<List<Widget>> rows;
  final String emptyText;
  final String? searchPlaceholder;
  final bool showHeader;
  final bool framed;
  final double horizontalMargin;
  final double columnSpacing;
  final double headingRowHeight;
  final double dataRowMinHeight;
  final double dataRowMaxHeight;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: framed ? Border.all(color: AppColors.slate200) : null,
        borderRadius: framed ? BorderRadius.circular(12) : BorderRadius.zero,
        boxShadow: framed
            ? const [
                BoxShadow(
                  color: Color(0x0d0f172a),
                  blurRadius: 5,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: framed ? BorderRadius.circular(12) : BorderRadius.zero,
        child: Column(
          children: [
            if (showHeader)
              Container(
                constraints: const BoxConstraints(minHeight: 70),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Color(0x80f8fafc),
                  border: Border(bottom: BorderSide(color: AppColors.slate200)),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final titleWidget = Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.slate800,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    );
                    final searchWidget = searchPlaceholder == null
                        ? null
                        : SizedBox(
                            width: constraints.maxWidth < 520
                                ? double.infinity
                                : 256,
                            height: 38,
                            child: TextField(
                              onChanged: onSearchChanged,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.slate400,
                                  size: 18,
                                ),
                                hintText: searchPlaceholder,
                                hintStyle: const TextStyle(
                                  color: AppColors.slate400,
                                  fontSize: 14,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.slate200,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppColors.blue600,
                                  ),
                                ),
                              ),
                            ),
                          );

                    if (constraints.maxWidth < 520 && searchWidget != null) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            titleWidget,
                            const SizedBox(height: 10),
                            searchWidget,
                          ],
                        ),
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [titleWidget, ?searchWidget],
                    );
                  },
                ),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        AppColors.slate50,
                      ),
                      headingRowHeight: headingRowHeight,
                      dataRowMinHeight: dataRowMinHeight,
                      dataRowMaxHeight: dataRowMaxHeight,
                      horizontalMargin: horizontalMargin,
                      columnSpacing: columnSpacing,
                      dividerThickness: 1,
                      headingTextStyle: const TextStyle(
                        color: AppColors.slate500,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      dataTextStyle: const TextStyle(
                        color: AppColors.slate600,
                        fontSize: 14,
                      ),
                      columns: columns
                          .map(
                            (col) => DataColumn(
                              numeric: col.toLowerCase() == 'action',
                              label: Text(
                                col,
                                textAlign: col.toLowerCase() == 'action'
                                    ? TextAlign.right
                                    : TextAlign.left,
                              ),
                            ),
                          )
                          .toList(),
                      rows: rows
                          .map(
                            (cells) => DataRow(
                              cells: cells.asMap().entries.map((entry) {
                                final isAction =
                                    columns[entry.key].toLowerCase() ==
                                    'action';
                                return DataCell(
                                  Align(
                                    alignment: isAction
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: entry.value,
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  emptyText,
                  style: const TextStyle(color: AppColors.slate500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
