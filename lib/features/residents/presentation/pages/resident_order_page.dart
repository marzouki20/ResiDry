import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../orders/presentation/order_data.dart';
import '../../data/residence_locator.dart';
import '../../mock/residents_mock_data.dart';

class ResidentOrderPage extends StatefulWidget {
  const ResidentOrderPage({super.key, required this.resident});

  final ResidentProfile resident;

  @override
  State<ResidentOrderPage> createState() => _ResidentOrderPageState();
}

class _ResidentOrderPageState extends State<ResidentOrderPage> {
  static const _categories = ['Nettoyage', 'Repassage', 'Teinture', 'Sport'];
  static const _catalog = <_CatalogItem>[
    _CatalogItem(
      'cleaning-shirt',
      'Nettoyage',
      'Chemise',
      2.0,
      Icons.dry_cleaning,
    ),
    _CatalogItem(
      'cleaning-pants',
      'Nettoyage',
      'Pantalon',
      3.0,
      Icons.checkroom,
    ),
    _CatalogItem('cleaning-short', 'Nettoyage', 'Short', 3.0, Icons.short_text),
    _CatalogItem('cleaning-jeans', 'Nettoyage', 'Jean', 3.5, Icons.checkroom),
    _CatalogItem('cleaning-jacket', 'Nettoyage', 'Veste', 5.0, Icons.checkroom),
    _CatalogItem('cleaning-coat', 'Nettoyage', 'Manteau', 7.0, Icons.checkroom),
    _CatalogItem('cleaning-sweater', 'Nettoyage', 'Pull', 4.0, Icons.checkroom),
    _CatalogItem('cleaning-skirt', 'Nettoyage', 'Jupe', 3.5, Icons.checkroom),
    _CatalogItem(
      'cleaning-cap',
      'Nettoyage',
      'Casquette',
      3.5,
      Icons.sports_baseball,
    ),
    _CatalogItem(
      'ironing-shirt',
      'Repassage',
      'Chemise repassée',
      2.5,
      Icons.checkroom,
    ),
    _CatalogItem(
      'ironing-dress',
      'Repassage',
      'Robe repassée',
      5.0,
      Icons.woman,
    ),
    _CatalogItem(
      'ironing-pants',
      'Repassage',
      'Pantalon repassé',
      3.5,
      Icons.checkroom,
    ),
    _CatalogItem(
      'ironing-jacket',
      'Repassage',
      'Veste repassée',
      5.5,
      Icons.checkroom,
    ),
    _CatalogItem(
      'ironing-skirt',
      'Repassage',
      'Jupe repassée',
      4.0,
      Icons.checkroom,
    ),
    _CatalogItem(
      'dyeing-basic',
      'Teinture',
      'Teinture standard',
      8.0,
      Icons.water_drop,
    ),
    _CatalogItem(
      'dyeing-shirt',
      'Teinture',
      'Chemise à teindre',
      7.0,
      Icons.water_drop,
    ),
    _CatalogItem(
      'dyeing-pants',
      'Teinture',
      'Pantalon à teindre',
      9.0,
      Icons.water_drop,
    ),
    _CatalogItem(
      'dyeing-jacket',
      'Teinture',
      'Veste à teindre',
      12.0,
      Icons.water_drop,
    ),
    _CatalogItem(
      'sport-shoes',
      'Sport',
      'Chaussures de sport',
      6.0,
      Icons.directions_run,
    ),
    _CatalogItem(
      'sport-jersey',
      'Sport',
      'Maillot de sport',
      3.5,
      Icons.sports_soccer,
    ),
    _CatalogItem(
      'sport-tracksuit',
      'Sport',
      'Survêtement',
      6.0,
      Icons.directions_run,
    ),
    _CatalogItem(
      'sport-bag',
      'Sport',
      'Sac de sport',
      7.0,
      Icons.shopping_bag_outlined,
    ),
  ];

  final _quantities = <String, int>{};
  final _noteController = TextEditingController();
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  String _category = _categories.first;
  int _step = 0;
  DateTime _collectionDate = DateTime.now().add(const Duration(days: 1));
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 2));
  String _paymentMethod = 'À la livraison';
  bool _isDetectingAddress = false;
  bool _useGpsAddress = false;

  String get _pickupAddress => _addressController.text.trim();

  String get _pickupCity => _cityController.text.trim();

  List<_CatalogItem> get _visibleItems =>
      _catalog.where((item) => item.category == _category).toList();

  List<_CatalogItem> get _selectedItems =>
      _catalog.where((item) => (_quantities[item.id] ?? 0) > 0).toList();

  int get _itemCount => _quantities.values.fold(0, (sum, count) => sum + count);

  double get _itemsTotal => _catalog.fold(0, (total, item) {
    return total + item.price * (_quantities[item.id] ?? 0);
  });

  double get _deliveryFee => _itemCount == 0 ? 0 : 7.0;

  double get _total => _itemsTotal + _deliveryFee;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: widget.resident.residenceAddress,
    );
    _cityController = TextEditingController(text: widget.resident.city);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _step == 0
              ? 'Choisir les articles'
              : _step == 1
              ? 'Planifier la collecte'
              : 'Valider la commande',
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _step == 0
            ? _catalogStep()
            : _step == 1
            ? _planningStep()
            : _confirmationStep(),
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _catalogStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _welcomeHeader(),
        const SizedBox(height: 20),
        const Text(
          'Catégories',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 94,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, index) {
              final category = _categories[index];
              final selected = category == _category;
              return InkWell(
                onTap: () => setState(() => _category = category),
                borderRadius: BorderRadius.circular(18),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 108,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.cyan : const Color(0xFFF0FAFD),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? AppColors.cyan : AppColors.line,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _categoryIcon(category),
                        color: selected ? Colors.white : AppColors.navy,
                        size: 27,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? Colors.white : AppColors.navy,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Articles',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ..._visibleItems.map(_catalogCard),
      ],
    );
  }

  Widget _welcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF9F9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: AppColors.navy,
            child: Icon(
              Icons.local_laundry_service_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Bonjour ${widget.resident.firstName}, que souhaitez-vous faire laver ?',
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catalogCard(_CatalogItem item) {
    final quantity = _quantities[item.id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: quantity > 0 ? AppColors.cyan : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(item.icon, color: AppColors.navy, size: 27),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(2)} DT',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          _quantityButton(
            icon: Icons.remove,
            onPressed: quantity == 0
                ? null
                : () => setState(() => _quantities[item.id] = quantity - 1),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _quantityButton(
            icon: Icons.add,
            onPressed: () =>
                setState(() => _quantities[item.id] = quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton.filled(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.line,
        ),
      ),
    );
  }

  Widget _planningStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _addressCard(),
        const SizedBox(height: 14),
        _dateCard(
          title: 'Date de ramassage',
          date: _collectionDate,
          onTap: () => _pickDate(isCollection: true),
          icon: Icons.calendar_month_outlined,
        ),
        const SizedBox(height: 14),
        _dateCard(
          title: 'Date de livraison souhaitée',
          date: _deliveryDate,
          onTap: () => _pickDate(isCollection: false),
          icon: Icons.local_shipping_outlined,
        ),
        const SizedBox(height: 14),
        _sectionCard(
          icon: Icons.notes_rounded,
          title: 'Remarque',
          child: TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Écrivez votre message ici',
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _addressCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.navy),
              SizedBox(width: 10),
              Text(
                'Adresse de ramassage',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isDetectingAddress ? null : _detectAddress,
                  icon: _isDetectingAddress
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_outlined),
                  label: const Text('Utiliser le GPS'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _useGpsAddress = false),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Saisir manuellement'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            onChanged: (_) => setState(() => _useGpsAddress = false),
            decoration: const InputDecoration(
              labelText: 'Adresse',
              hintText: 'Rue et numéro',
              prefixIcon: Icon(Icons.home_outlined),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cityController,
            onChanged: (_) => setState(() => _useGpsAddress = false),
            decoration: const InputDecoration(
              labelText: 'Ville',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Résidence : ${widget.resident.residenceName} • Appartement ${widget.resident.apartmentNumber}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          if (_useGpsAddress)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'Adresse détectée automatiquement par le GPS.',
                style: TextStyle(color: Colors.green, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _detectAddress() async {
    setState(() => _isDetectingAddress = true);
    try {
      final residence = await ResidenceLocator.detectNearest();
      if (!mounted) return;
      if (residence == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aucune résidence connue n’a été détectée à proximité. Vous pouvez saisir l’adresse manuellement.',
            ),
          ),
        );
        return;
      }
      setState(() {
        _addressController.text = residence.address.isEmpty
            ? residence.name
            : residence.address;
        _cityController.text = residence.city;
        _useGpsAddress = true;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d’utiliser le GPS. Vérifiez la permission ou saisissez l’adresse manuellement.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDetectingAddress = false);
    }
  }

  Widget _confirmationStep() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _summaryCard(),
        const SizedBox(height: 20),
        const Text(
          'Mode de paiement',
          style: TextStyle(
            color: AppColors.navy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          'Mon solde',
          'Carte bancaire',
          'À la livraison',
        ].map((method) => _paymentCard(method)),
      ],
    );
  }

  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cyan,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _summaryRow('Articles', '$_itemCount'),
          _summaryRow('Prix', '${_itemsTotal.toStringAsFixed(2)} DT'),
          _summaryRow('Livraison', '${_deliveryFee.toStringAsFixed(2)} DT'),
          const Divider(color: Colors.white70),
          _summaryRow('Total', '${_total.toStringAsFixed(2)} DT', bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: bold ? 18 : 15,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: bold ? 20 : 15,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(String method) {
    final selected = method == _paymentMethod;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF9F9) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.cyan : AppColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              method == 'À la livraison'
                  ? Icons.payments_outlined
                  : method == 'Carte bancaire'
                  ? Icons.credit_card_outlined
                  : Icons.account_balance_wallet_outlined,
              color: AppColors.navy,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppColors.cyan),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.navy),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _dateCard({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: _sectionCard(
        icon: icon,
        title: title,
        child: Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
          style: const TextStyle(color: AppColors.navy, fontSize: 16),
        ),
      ),
    );
  }

  Widget _bottomBar() {
    final label = _step == 0
        ? 'Suivant'
        : _step == 1
        ? 'Continuer'
        : 'Valider la commande';
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_itemCount article${_itemCount == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  Text(
                    '${_total.toStringAsFixed(2)} DT',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: _itemCount == 0
                  ? null
                  : () {
                      if (_step < 2) {
                        setState(() => _step++);
                      } else {
                        _submitOrder();
                      }
                    },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate({required bool isCollection}) async {
    final current = isCollection ? _collectionDate : _deliveryDate;
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: current,
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isCollection) {
        _collectionDate = date;
        if (!_deliveryDate.isAfter(date)) {
          _deliveryDate = date.add(const Duration(days: 1));
        }
      } else {
        _deliveryDate = date;
      }
    });
  }

  void _submitOrder() {
    final id = 'CMD-${DateTime.now().millisecondsSinceEpoch}';
    final quantity = _itemCount;
    final type = _selectedItems.map((item) => item.name).join(', ');
    addManagedOrder(
      ManagedOrder(
        id: id,
        resident: widget.resident.fullName,
        apartment: widget.resident.apartmentNumber,
        locker: 'À attribuer',
        laundryCompany: 'À attribuer',
        status: 'Nouvelle',
        laundryType: type,
        quantity: quantity,
        weight: quantity * 0.5,
        createdAt: DateTime.now(),
        collectionAt: _collectionDate,
        deliveryAt: _deliveryDate,
        price: _total,
        notes:
            'Adresse : $_pickupAddress, $_pickupCity. Appartement : ${widget.resident.apartmentNumber}. Paiement : $_paymentMethod. ${_noteController.text.trim()}'
                .trim(),
      ),
    );
    Navigator.of(context).pop(true);
  }

  IconData _categoryIcon(String category) => switch (category) {
    'Nettoyage' => Icons.local_laundry_service_outlined,
    'Repassage' => Icons.checkroom_outlined,
    'Teinture' => Icons.water_drop_outlined,
    _ => Icons.sports_outlined,
  };
}

class _CatalogItem {
  const _CatalogItem(this.id, this.category, this.name, this.price, this.icon);

  final String id;
  final String category;
  final String name;
  final double price;
  final IconData icon;
}
