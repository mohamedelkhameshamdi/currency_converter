import 'package:flutter/material.dart';
import 'services/exchange_service.dart';

void main() => runApp(const CurrencyApp());

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Converter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ConverterPage(),
    );
  }
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _service = ExchangeService();
  final _amountController = TextEditingController(text: '1');

  Map<String, double> _rates = {};
  String _from = 'USD';
  String _to = 'EUR';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rates = await _service.fetchRates(_from);
      if (!mounted) return;
      setState(() => _rates = rates);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load rates. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _swap() {
    setState(() {
      final temp = _from;
      _from = _to;
      _to = temp;
    });
    _loadRates(); // new base currency -> new rates
  }

  Widget _currencyDropdown(String value, List<String> codes, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: codes.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final codes = _rates.keys.toList()..sort();
    final amount = double.tryParse(_amountController.text) ?? 0;
    final rate = _rates[_to];
    final result = rate == null ? null : amount * rate;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Converter'),
        actions: [
          IconButton(onPressed: _loadRates, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _loading
                ? const CircularProgressIndicator()
                : _error != null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!),
                          const SizedBox(height: 12),
                          FilledButton(onPressed: _loadRates, child: const Text('Retry')),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _currencyDropdown(_from, codes, (v) {
                                  setState(() => _from = v);
                                  _loadRates();
                                }),
                              ),
                              IconButton(onPressed: _swap, icon: const Icon(Icons.swap_horiz)),
                              Expanded(
                                child: _currencyDropdown(_to, codes, (v) => setState(() => _to = v)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (result != null) ...[
                            Text(
                              '${result.toStringAsFixed(2)} $_to',
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                            const SizedBox(height: 8),
                            Text('1 $_from = ${rate!.toStringAsFixed(4)} $_to'),
                          ],
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}