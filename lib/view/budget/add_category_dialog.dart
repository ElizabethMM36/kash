import 'package:flutter/material.dart';
import 'package:kash/common/color_extension.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key});

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  int _percentage = 5;
  int _selectedColorIndex = 0;

  // Predefined color palette
  final List<int> _colors = [
    0xFF6C5CE7, // Purple
    0xFF00B894, // Green
    0xFF0984E3, // Blue
    0xFFFDCB6E, // Yellow
    0xFFE17055, // Orange
    0xFFE84393, // Pink
    0xFFA29BFE, // Light Purple
    0xFF74B9FF, // Sky Blue
    0xFFFF7675, // Red
    0xFF55EFC4, // Teal
    0xFF00CEC9, // Cyan
    0xFF636E72, // Gray
    0xFFD63031, // Dark Red
    0xFFFD79A8, // Light Pink
    0xFF81ECEC, // Light Cyan
    0xFFFFB8B8, // Salmon
  ];

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'category': _categoryController.text.trim(),
        'percentage': _percentage,
        'colorValue': _colors[_selectedColorIndex],
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: TColor.gray80,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Category",
                    style: TextStyle(
                      color: TColor.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: TColor.gray30),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Name Input
              Text(
                "Category Name",
                style: TextStyle(
                  color: TColor.gray30,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _categoryController,
                style: TextStyle(color: TColor.white),
                decoration: InputDecoration(
                  hintText: "e.g., Education, Pets, Gifts",
                  hintStyle: TextStyle(color: TColor.gray60),
                  filled: true,
                  fillColor: TColor.gray70,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter a category name";
                  }
                  if (value.trim().length < 2) {
                    return "Name must be at least 2 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Percentage Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Monthly Limit",
                    style: TextStyle(
                      color: TColor.gray30,
                      fontSize: 14,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TColor.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$_percentage%",
                      style: TextStyle(
                        color: TColor.secondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: TColor.secondary,
                  inactiveTrackColor: TColor.gray60.withValues(alpha: 0.3),
                  thumbColor: TColor.secondary,
                  overlayColor: TColor.secondary.withValues(alpha: 0.2),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: _percentage.toDouble(),
                  min: 1,
                  max: 50,
                  divisions: 49,
                  onChanged: (value) {
                    setState(() {
                      _percentage = value.toInt();
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Color Picker
              Text(
                "Color",
                style: TextStyle(
                  color: TColor.gray30,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(_colors.length, (index) {
                  final isSelected = _selectedColorIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorIndex = index;
                      });
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(_colors[index]),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: TColor.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Color(_colors[index]).withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TColor.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Add Category",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
