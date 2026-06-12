import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/shipment_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/location_picker_screen.dart';

/// Create shipment screen with multi-step form
class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key});

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Form controllers
  final _pickupLocationController = TextEditingController();
  final _dropLocationController = TextEditingController();
  final _cargoTypeController = TextEditingController();
  final _cargoWeightController = TextEditingController();
  final _specialInstructionsController = TextEditingController();

  // Form values
  String _priority = 'LOW';
  double _pickupLat = 12.9716; // Default to Bangalore
  double _pickupLng = 77.5946;
  double _dropLat = 13.0358;
  double _dropLng = 77.5970;

  int _currentStep = 0;

  final List<String> _cargoTypes = [
    'Electronics',
    'Industrial Machinery',
    'Textiles',
    'Automotive Parts',
    'FMCG Products',
    'Pharmaceuticals',
    'Steel & Metal',
    'Agricultural Products',
    'Furniture',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _pickupLocationController.dispose();
    _dropLocationController.dispose();
    _cargoTypeController.dispose();
    _cargoWeightController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitShipment();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        // Locations are set via map, no need to validate text fields
        return true;
      case 1:
        if (_cargoTypeController.text.isEmpty) {
          _showError('Please select cargo type');
          return false;
        }
        if (_cargoWeightController.text.isEmpty) {
          _showError('Please enter cargo weight');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  void _submitShipment() async {
    final provider = context.read<ShipmentProvider>();

    // Provide default location strings if empty
    final pickupText = _pickupLocationController.text.isEmpty
        ? 'Lat: ${_pickupLat.toStringAsFixed(4)}, Lng: ${_pickupLng.toStringAsFixed(4)}'
        : _pickupLocationController.text;

    final dropText = _dropLocationController.text.isEmpty
        ? 'Lat: ${_dropLat.toStringAsFixed(4)}, Lng: ${_dropLng.toStringAsFixed(4)}'
        : _dropLocationController.text;

    final shipment = await provider.createShipment(
      pickupLat: _pickupLat,
      pickupLng: _pickupLng,
      pickupLocation: pickupText,
      dropLat: _dropLat,
      dropLng: _dropLng,
      dropLocation: dropText,
      cargoType: _cargoTypeController.text,
      cargoWeight: double.tryParse(_cargoWeightController.text) ?? 0,
      specialInstructions: _specialInstructionsController.text.isEmpty
          ? null
          : _specialInstructionsController.text,
      priority: _priority,
    );

    if (shipment != null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shipment created successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else if (provider.error != null && mounted) {
      _showError(provider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Shipment')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),

            // Form pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildLocationStep(),
                  _buildCargoStep(),
                  _buildReviewStep(),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStepDot(0, 'Location'),
          _buildStepLine(0),
          _buildStepDot(1, 'Cargo'),
          _buildStepLine(1),
          _buildStepDot(2, 'Review'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : AppTheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppTheme.primary : AppTheme.surfaceLight,
              width: 2,
            ),
          ),
          child: Center(
            child: isActive && !isCurrent
                ? const Icon(Icons.check, size: 18, color: Colors.black)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.black : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.caption.copyWith(
            color: isActive ? AppTheme.textPrimary : AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int afterStep) {
    final isActive = _currentStep > afterStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? AppTheme.primary : AppTheme.surfaceLight,
      ),
    );
  }

  Future<void> _openLocationPicker({required bool isPickup}) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLat: isPickup ? _pickupLat : _dropLat,
          initialLng: isPickup ? _pickupLng : _dropLng,
          title: isPickup ? 'Select Pickup Location' : 'Select Drop Location',
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (isPickup) {
          _pickupLat = result['lat'];
          _pickupLng = result['lng'];
          _pickupLocationController.text = result['address'];
        } else {
          _dropLat = result['lat'];
          _dropLng = result['lng'];
          _dropLocationController.text = result['address'];
        }
      });
    }
  }

  Widget _buildLocationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where are you shipping?', style: AppTheme.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Tap on the fields below to select locations on the map',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Pickup Location
          Text('Pickup Location', style: AppTheme.labelLarge),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openLocationPicker(isPickup: true),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _pickupLocationController,
                decoration: InputDecoration(
                  hintText: 'Tap to select pickup location',
                  prefixIcon: Container(
                    margin: const EdgeInsets.only(left: 12, right: 8),
                    child: const CircleAvatar(
                      radius: 8,
                      backgroundColor: AppTheme.success,
                    ),
                  ),
                  suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40),
                ),
                maxLines: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Drop Location
          Text('Drop Location', style: AppTheme.labelLarge),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _openLocationPicker(isPickup: false),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dropLocationController,
                decoration: InputDecoration(
                  hintText: 'Tap to select drop location',
                  prefixIcon: Container(
                    margin: const EdgeInsets.only(left: 12, right: 8),
                    child: const CircleAvatar(
                      radius: 8,
                      backgroundColor: AppTheme.error,
                    ),
                  ),
                  suffixIcon: const Icon(Icons.arrow_forward_ios, size: 16),
                  prefixIconConstraints: const BoxConstraints(minWidth: 40),
                ),
                maxLines: 2,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap the fields above to open an interactive map where you can search or select exact locations',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCargoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What are you shipping?', style: AppTheme.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Provide details about your cargo',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Cargo Type
          Text('Cargo Type', style: AppTheme.labelLarge),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _cargoTypeController.text.isEmpty
                ? null
                : _cargoTypeController.text,
            decoration: const InputDecoration(
              hintText: 'Select cargo type',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            dropdownColor: AppTheme.surface,
            items: _cargoTypes.map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _cargoTypeController.text = value ?? '';
              });
            },
          ),
          const SizedBox(height: 24),

          // Cargo Weight
          const SizedBox(height: 24),
          CustomInputField(
            label: 'Cargo Weight (Tonnes)',
            controller: _cargoWeightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            hintText: 'Enter weight in tonnes',
            prefixIcon: Icons.scale_outlined,
          ),
          const SizedBox(height: 24),

          // Priority
          Text('Priority', style: AppTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPriorityChip('LOW', 'Standard'),
              const SizedBox(width: 8),
              _buildPriorityChip('MEDIUM', 'Express'),
              const SizedBox(width: 8),
              _buildPriorityChip('HIGH', 'Urgent'),
            ],
          ),
          const SizedBox(height: 24),

          // Special Instructions
          const SizedBox(height: 24),
          CustomInputField(
            label: 'Special Instructions (Optional)',
            controller: _specialInstructionsController,
            maxLines: 3,
            hintText: 'Any special handling requirements...',
            prefixIcon: Icons.note_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String value, String label) {
    final isSelected = _priority == value;
    Color color;
    switch (value) {
      case 'HIGH':
        color = AppTheme.error;
        break;
      case 'MEDIUM':
        color = AppTheme.warning;
        break;
      default:
        color = AppTheme.success;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _priority = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppTheme.surfaceLight,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review your shipment', style: AppTheme.headingSmall),
          const SizedBox(height: 8),
          Text(
            'Please verify all details before submitting',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 24),

          // Route summary
          _buildReviewCard('Route', Icons.route, [
            _buildReviewItem('From', _pickupLocationController.text),
            _buildReviewItem('To', _dropLocationController.text),
          ]),
          const SizedBox(height: 16),

          // Cargo summary
          _buildReviewCard('Cargo Details', Icons.inventory_2_outlined, [
            _buildReviewItem('Type', _cargoTypeController.text),
            _buildReviewItem('Weight', '${_cargoWeightController.text} Tonnes'),
            _buildReviewItem('Priority', _priority),
            if (_specialInstructionsController.text.isNotEmpty)
              _buildReviewItem(
                'Instructions',
                _specialInstructionsController.text,
              ),
          ]),
          const SizedBox(height: 16),

          // Price estimate placeholder
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Price will be calculated using our AI pricing model after submission',
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(String title, IconData icon, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.labelLarge),
            ],
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: AppTheme.caption)),
          Expanded(child: Text(value, style: AppTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Consumer<ShipmentProvider>(
        builder: (context, provider, _) => Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: CustomButton(
                  text: 'Back',
                  isOutlined: true,
                  onPressed: _previousStep,
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: _currentStep == 2 ? 'Create Shipment' : 'Continue',
                isLoading: provider.isLoading,
                onPressed: _nextStep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
