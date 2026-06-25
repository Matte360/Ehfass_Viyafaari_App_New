import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/business.dart';
import '../models/catalog_item.dart';
import '../services/marketplace_service.dart';
import '../utils/image_crop_helper.dart';

class AddCatalogItemPage extends StatefulWidget {
  const AddCatalogItemPage({
    super.key,
    required this.business,
    required this.isDhivehi,
    this.item,
  });

  final Business business;
  final bool isDhivehi;
  final CatalogItem? item;

  @override
  State<AddCatalogItemPage> createState() => _AddCatalogItemPageState();
}

class _AddCatalogItemPageState extends State<AddCatalogItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  static const List<String> _productCategories = [
    'Apparel & Accessories',
    'Electronics & Office',
    'Home, Garden & Tools',
    'Health & Beauty',
    'Sports & Outdoors',
    'Toys & Hobbies',
    'Food and Beverage',
    'Other',
  ];

  static const List<String> _serviceCategories = [
    'Accounting & Financial',
    'Legal Services',
    'Consulting',
    'Administrative',
    'IT & Cloud Services',
    'Telecommunications',
    'Marketing & Media',
    'Construction & Engineering',
    'Maintenance & Repair',
    'Cleaning Services',
    'Accommodation',
    'Food & Beverage',
    'Transportation',
    'Healthcare',
    'Social & Community Care',
    'Education',
    'Wellness & Beauty',
    'Other',
  ];

  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _priceController;
  late final TextEditingController _oldPriceController;
  late final TextEditingController _quantityController;
  late final TextEditingController _bulkMinController;
  late final TextEditingController _bulkAmountController;
  late final TextEditingController _bulkPercentController;
  late final TextEditingController _descriptionController;

  late String _itemType;
  late bool _promotionActive;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;

  bool get isEditing => widget.item != null;

  String text(String english, String dhivehi) {
    return widget.isDhivehi ? dhivehi : english;
  }

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: widget.isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  List<String> get _categoryOptions => _categoriesForType(_itemType);

  static List<String> _categoriesForType(String itemType) {
    return itemType == 'service' ? _serviceCategories : _productCategories;
  }

  static String _safeCategoryForType(String itemType, String value) {
    final options = _categoriesForType(itemType);
    final trimmed = value.trim();
    if (options.contains(trimmed)) return trimmed;
    return options.last;
  }

  void _changeItemType(String itemType) {
    setState(() {
      _itemType = itemType;
      _categoryController.text = _safeCategoryForType(
        _itemType,
        _categoryController.text,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _itemType = item?.itemType ?? 'product';
    _nameController = TextEditingController(text: item?.name ?? '');
    _categoryController = TextEditingController(
      text: _safeCategoryForType(_itemType, item?.category ?? ''),
    );
    _priceController = TextEditingController(
      text: item == null ? '' : item.priceMvr.toStringAsFixed(2),
    );
    _oldPriceController = TextEditingController(
      text: item == null || item.oldPriceMvr <= 0
          ? ''
          : item.oldPriceMvr.toStringAsFixed(2),
    );
    _promotionActive = item?.promotionActive ?? false;
    _quantityController = TextEditingController(
      text: item == null ? '' : item.quantity.toString(),
    );
    _bulkMinController = TextEditingController(
      text: item == null || item.bulkMinQuantity <= 0
          ? ''
          : item.bulkMinQuantity.toString(),
    );
    _bulkAmountController = TextEditingController(
      text: item == null || item.bulkDiscountAmountMvr <= 0
          ? ''
          : item.bulkDiscountAmountMvr.toStringAsFixed(2),
    );
    _bulkPercentController = TextEditingController(
      text: item == null || item.bulkDiscountPercent <= 0
          ? ''
          : item.bulkDiscountPercent.toStringAsFixed(0),
    );
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _oldPriceController.dispose();
    _quantityController.dispose();
    _bulkMinController.dispose();
    _bulkAmountController.dispose();
    _bulkPercentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final cropped = await pickImageCropAndSet(
      context: context,
      picker: _picker,
      isDhivehi: widget.isDhivehi,
      title: text('Crop Item Image', 'މުދާގެ ފޮޓޯ ކްރޮޕް ކުރޭ'),
      initialMode: ImageCropMode.fourThree,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (cropped == null || !mounted) return;

    setState(() {
      _imageBytes = cropped.bytes;
      _imageName = cropped.fileName;
    });
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!isEditing && (_imageBytes == null || _imageName == null)) {
      _showError(text(
        'Please choose an item or service image.',
        'މުދާ ނުވަތަ ޚިދުމަތުގެ ފޮޓޯއެއް ހޮވާ.',
      ));
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    final quantity = int.tryParse(_quantityController.text.trim());
    final oldPrice = double.tryParse(_oldPriceController.text.trim()) ?? 0;
    final bulkMin = int.tryParse(_bulkMinController.text.trim()) ?? 0;
    final bulkAmount = double.tryParse(_bulkAmountController.text.trim()) ?? 0;
    final bulkPercent = double.tryParse(_bulkPercentController.text.trim()) ?? 0;
    if (price == null || quantity == null) return;

    if (_promotionActive && oldPrice <= price) {
      _showError(text(
        'Old price must be higher than new price.',
        'ކުރީގެ އަގު އާ އަގަށްވުރެ މަތިވާންޖެހޭ.',
      ));
      return;
    }
    if (bulkPercent > 100) {
      _showError(text(
        'Discount percentage cannot be more than 100%.',
        'ޑިސްކައުންޓް ޕަސެންޓޭޖް 100% އަށްވުރެ ބޮޑު ނުވާނެ.',
      ));
      return;
    }

    setState(() => _saving = true);

    try {
      if (isEditing) {
        await MarketplaceService.instance.updateCatalogItem(
          business: widget.business,
          item: widget.item!,
          itemType: _itemType,
          name: _nameController.text,
          category: _categoryController.text.trim(),
          priceMvr: price,
          quantity: quantity,
          description: _descriptionController.text,
          oldPriceMvr: oldPrice,
          promotionActive: _promotionActive,
          bulkMinQuantity: bulkMin,
          bulkDiscountAmountMvr: bulkAmount,
          bulkDiscountPercent: bulkPercent,
          imageBytes: _imageBytes,
          imageFileName: _imageName,
        );
      } else {
        await MarketplaceService.instance.addCatalogItem(
          business: widget.business,
          itemType: _itemType,
          name: _nameController.text,
          category: _categoryController.text.trim(),
          priceMvr: price,
          quantity: quantity,
          description: _descriptionController.text,
          oldPriceMvr: oldPrice,
          promotionActive: _promotionActive,
          bulkMinQuantity: bulkMin,
          bulkDiscountAmountMvr: bulkAmount,
          bulkDiscountPercent: bulkPercent,
          imageBytes: _imageBytes!,
          imageFileName: _imageName!,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            text(
              isEditing ? 'Item updated.' : 'Item added to your business.',
              isEditing
                  ? 'މުދާ އަޕްޑޭޓް ކުރެވިއްޖެ.'
                  : 'ވިޔަފާރިއަށް މުދާ އިތުރުކުރެވިއްޖެ.',
            ),
            style: style(color: Colors.white),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 7),
        content: Text(message, style: style(color: Colors.white)),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return text('This field is required.', 'މި ފީލްޑް ފުރާ.');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          widget.isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            text(
              isEditing ? 'Edit Item or Service' : 'Add Item or Service',
              isEditing
                  ? 'މުދާ ނުވަތަ ޚިދުމަތް ބަދަލުކުރޭ'
                  : 'މުދާ ނުވަތަ ޚިދުމަތް އިތުރުކުރޭ',
            ),
            style: style(fontWeight: FontWeight.bold),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              InkWell(
                onTap: _saving ? null : _pickImage,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 230,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                      : widget.item?.imageUrl.isNotEmpty == true
                          ? Image.network(
                              widget.item!.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _imagePlaceholder(),
                            )
                          : _imagePlaceholder(),
                ),
              ),
              const SizedBox(height: 18),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'product',
                    icon: const Icon(Icons.inventory_2_rounded),
                    label: Text(text('Product', 'މުދާ'), style: style()),
                  ),
                  ButtonSegment(
                    value: 'service',
                    icon: const Icon(Icons.design_services_rounded),
                    label: Text(text('Service', 'ޚިދުމަތް'), style: style()),
                  ),
                ],
                selected: {_itemType},
                onSelectionChanged: _saving
                    ? null
                    : (value) => _changeItemType(value.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                validator: _required,
                decoration: InputDecoration(
                  labelText: text('Name', 'ނަން'),
                  prefixIcon: const Icon(Icons.label_rounded),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _safeCategoryForType(
                  _itemType,
                  _categoryController.text,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return text('Please choose a category.', 'ބާވަތެއް ހޮވާ.');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: _itemType == 'service'
                      ? text('Service Category', 'ޚިދުމަތުގެ ބާވަތް')
                      : text('Product Category', 'މުދާގެ ބާވަތް'),
                  prefixIcon: const Icon(Icons.category_rounded),
                ),
                items: _categoryOptions
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category, style: style()),
                      ),
                    )
                    .toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _categoryController.text = value);
                      },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final price = double.tryParse(value?.trim() ?? '');
                        if (price == null || price <= 0) {
                          return text('Invalid price', 'ރަނގަޅު އަގެއް ލިޔޭ');
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: _promotionActive
                            ? text('Current / new price (MVR)', 'މިހާރުގެ / އާ އަގު (MVR)')
                            : text('Price (MVR)', 'އަގު (MVR)'),
                        helperText: _promotionActive
                            ? text('This is the sale price clients will pay.', 'މިއީ ކްލައިންޓު ދައްކާ ސޭލް އަގެވެ.')
                            : null,
                        prefixIcon: const Icon(Icons.payments_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final quantity = int.tryParse(value?.trim() ?? '');
                        if (quantity == null || quantity < 0) {
                          return text('Invalid quantity', 'ރަނގަޅު ޢަދަދެއް ލިޔޭ');
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: _itemType == 'service'
                            ? text('Available slots', 'ލިބެން ހުރި ޖާގަ')
                            : text('Quantity', 'ޢަދަދު'),
                        prefixIcon: const Icon(Icons.numbers_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _promotionActive,
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _promotionActive = value),
                        secondary: const Icon(Icons.local_offer_rounded),
                        title: Text(
                          text('Sale promotion', 'ސޭލް ޕްރޮމޯޝަން'),
                          style: style(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          text(
                            'Show old price with a red line and new price to clients.',
                            'ކްލައިންޓަށް ކުރީގެ އަގު ރަތް ލައިންއާއި އާ އަގު ދައްކާ.',
                          ),
                          style: style(fontSize: 12),
                        ),
                      ),
                      if (_promotionActive) ...[
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _oldPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (!_promotionActive) return null;
                            final oldPrice = double.tryParse(value?.trim() ?? '');
                            final newPrice = double.tryParse(_priceController.text.trim());
                            if (oldPrice == null || newPrice == null || oldPrice <= newPrice) {
                              return text(
                                'Old price must be higher than new price',
                                'ކުރީގެ އަގު އާ އަގަށްވުރެ މަތިވާންޖެހޭ',
                              );
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: text('Before / old price (MVR)', 'ކުރީގެ އަގު (MVR)'),
                            helperText: text('This price will show crossed with a red line.', 'މި އަގު ރަތް ލައިންއަކާއެކު ކްރޮސްކޮށް ފެންނާނެ.'),
                            prefixIcon: const Icon(Icons.price_change_rounded),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.discount_rounded),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              text('Bulk discount', 'ބައި ޑިސްކައުންޓް'),
                              style: style(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        text(
                          'Example: if customer takes 10 items, give MVR 5 off or 5% off.',
                          'މިސާލު: 10 އައިޓަމް ނަގާނަމަ MVR 5 ނުވަތަ 5% ޑިސްކައުންޓް.',
                        ),
                        style: style(fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bulkMinController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: text('Minimum quantity', 'މަދުވެގެން ޢަދަދު'),
                          hintText: '10',
                          prefixIcon: const Icon(Icons.format_list_numbered_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _bulkAmountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: text('Discount MVR', 'ޑިސްކައުންޓް MVR'),
                                prefixIcon: const Icon(Icons.money_off_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _bulkPercentController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: text('Discount %', 'ޑިސްކައުންޓް %'),
                                prefixIcon: const Icon(Icons.percent_rounded),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                validator: _required,
                minLines: 5,
                maxLines: 8,
                decoration: InputDecoration(
                  labelText: text('Description', 'ތަފްޞީލު'),
                  alignLabelWithHint: true,
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    text(
                      isEditing ? 'Save Changes' : 'Publish Item',
                      isEditing ? 'ބަދަލުތައް ސޭވްކުރޭ' : 'މުދާ ޝާއިޢުކުރޭ',
                    ),
                    style: style(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_rounded, size: 56),
        const SizedBox(height: 10),
        Text(
          text('Choose image', 'ފޮޓޯ ހޮވާ'),
          style: style(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
