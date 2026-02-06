import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../home/providers/home_provider.dart';
import '../home/models/home_models.dart';
import 'missing_cashback_provider.dart';
import 'missing_cashback_service.dart';

class MissingCashbackForm extends ConsumerStatefulWidget {
  final VoidCallback onSubmitted;

  const MissingCashbackForm({
    super.key,
    required this.onSubmitted,
  });

  @override
  ConsumerState<MissingCashbackForm> createState() => _MissingCashbackFormState();
}

class _MissingCashbackFormState extends ConsumerState<MissingCashbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  final _orderAmountController = TextEditingController();
  final _expectedCashbackController = TextEditingController();
  final _notesController = TextEditingController();

  Store? _selectedStore;
  DateTime? _orderDate;

  bool _submitting = false;

  String? _screenshotFileName;
  Uint8List? _screenshotBytes;
  String? _screenshotPath;

  @override
  void dispose() {
    _orderIdController.dispose();
    _orderAmountController.dispose();
    _expectedCashbackController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = ref.watch(storesProvider(null));

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: storesAsync.when(
          data: (stores) {
            final options = stores.where((s) => s.isActive).toList();
            _selectedStore ??= options.isNotEmpty ? options.first : null;

            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Submit Missing Cashback',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _submitting ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _label('Store'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Store>(
                      initialValue: _selectedStore,
                      items: options
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: _submitting ? null : (v) => setState(() => _selectedStore = v),
                      validator: (v) => v == null ? 'Please select a store' : null,
                      decoration: _inputDecoration(),
                    ),

                    const SizedBox(height: 12),
                    _label('Order ID'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _orderIdController,
                      enabled: !_submitting,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Order ID is required' : null,
                      decoration: _inputDecoration(hint: 'e.g. ORDER12345'),
                    ),

                    const SizedBox(height: 12),
                    _label('Order Amount'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _orderAmountController,
                      enabled: !_submitting,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final raw = v?.trim() ?? '';
                        if (raw.isEmpty) return 'Order amount is required';
                        final parsed = double.tryParse(raw);
                        if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                        return null;
                      },
                      decoration: _inputDecoration(hint: 'e.g. 1499'),
                    ),

                    const SizedBox(height: 12),
                    _label('Order Date'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _submitting ? null : _pickDate,
                      child: InputDecorator(
                        decoration: _inputDecoration(),
                        child: Text(
                          _orderDate == null ? 'Select date' : _formatDate(_orderDate!),
                          style: TextStyle(
                            color: _orderDate == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    if (_orderDate == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 12),
                        child: Text(
                          'Order date is required',
                          style: TextStyle(color: AppTheme.errorRed, fontSize: 12),
                        ),
                      ),

                    const SizedBox(height: 12),
                    _label('Expected Cashback (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _expectedCashbackController,
                      enabled: !_submitting,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final raw = v?.trim() ?? '';
                        if (raw.isEmpty) return null;
                        final parsed = double.tryParse(raw);
                        if (parsed == null || parsed < 0) return 'Enter a valid amount';
                        return null;
                      },
                      decoration: _inputDecoration(hint: 'e.g. 75'),
                    ),

                    const SizedBox(height: 12),
                    _label('Upload Screenshot (optional)'),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _screenshotFileName == null ? 'No file selected' : _screenshotFileName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ),
                        TextButton(
                          onPressed: _submitting ? null : _pickScreenshot,
                          child: const Text('Choose File'),
                        ),
                        if (_screenshotFileName != null)
                          IconButton(
                            onPressed: _submitting
                                ? null
                                : () {
                                    setState(() {
                                      _screenshotFileName = null;
                                      _screenshotBytes = null;
                                      _screenshotPath = null;
                                    });
                                  },
                            icon: const Icon(Icons.close, size: 18, color: AppTheme.textSecondary),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    _label('Additional Notes (optional)'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _notesController,
                      enabled: !_submitting,
                      maxLines: 4,
                      decoration: _inputDecoration(hint: 'Any extra details to help us verify…'),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : () => _submit(options),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _submitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Submit Missing Cashback',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  'Unable to load stores',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(err.toString(), style: const TextStyle(color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _orderDate ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _orderDate = picked);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickScreenshot() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png'],
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final name = file.name;
    final ext = name.split('.').last.toLowerCase();
    if (!['jpg', 'jpeg', 'png'].contains(ext)) {
      _showSnack('Please select a JPG or PNG image');
      return;
    }

    setState(() {
      _screenshotFileName = name;
      _screenshotBytes = file.bytes;
      _screenshotPath = file.path;
    });
  }

  Future<void> _submit(List<Store> stores) async {
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) return;
    if (_orderDate == null) {
      setState(() {});
      return;
    }

    final store = _selectedStore;
    if (store == null) return;

    final orderAmount = double.parse(_orderAmountController.text.trim());
    final expectedCashbackRaw = _expectedCashbackController.text.trim();
    final expected = expectedCashbackRaw.isEmpty ? null : double.tryParse(expectedCashbackRaw);

    setState(() => _submitting = true);
    try {
      final req = MissingCashbackCreateRequest(
        storeId: store.id,
        orderId: _orderIdController.text.trim(),
        orderAmount: orderAmount,
        orderDate: _orderDate!,
        expectedCashback: expected,
        notes: _notesController.text,
        screenshotFileName: _screenshotFileName,
        screenshotBytes: _screenshotBytes,
        screenshotPath: _screenshotPath,
      );

      final service = ref.read(missingCashbackServiceProvider);
      await service.create(req);

      ref.invalidate(myMissingCashbackProvider);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your missing cashback request has been submitted successfully.'),
        ),
      );
      widget.onSubmitted();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
