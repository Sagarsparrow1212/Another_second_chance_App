import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:homelyhope/core/theme/app_theme.dart';
import 'package:homelyhope/features/common/Drawer/pages/dynamic_drawer.dart';
import '../../../../common/widgets/custom_appbar.dart';
import '../../../data/models/jobs/jobs_model.dart';
import '../providers/add_job_provider.dart';
import '../providers/jobs_merchant_provider.dart';
import 'package:homelyhope/core/providers/snackbar_provider.dart';

class AddJobPage extends ConsumerStatefulWidget {
  /// Optional job to edit. If null, the form is in "Add" mode.
  final JobModel? jobToEdit;

  const AddJobPage({super.key, this.jobToEdit});

  @override
  ConsumerState<AddJobPage> createState() => _AddJobPageState();
}

class _AddJobPageState extends ConsumerState<AddJobPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minSalaryController = TextEditingController();
  final _maxSalaryController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;

  /// Check if we're in edit mode
  bool get isEditMode => widget.jobToEdit != null;

  final List<String> _categories = [
    'Retail',
    'Food Service',
    'Warehouse',
    'Warehouse Helper',
    'Delivery Driver',
    'Cleaning',
    'Construction',
    'Customer Service',
    'Administrative',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing
    if (isEditMode) {
      _populateFormWithJobData();
    }
  }

  void _populateFormWithJobData() {
    final job = widget.jobToEdit!;
    _titleController.text = job.title;
    _descriptionController.text = job.description;
    _minSalaryController.text = job.salaryRange?.min.toString() ?? '';
    _maxSalaryController.text = job.salaryRange?.max.toString() ?? '';
    _addressController.text = job.location?.address ?? '';

    // Set category if it exists in our list
    if (_categories.contains(job.category)) {
      _selectedCategory = job.category;
    } else if (job.category.isNotEmpty) {
      // If category doesn't exist in list, add it temporarily
      _categories.add(job.category);
      _selectedCategory = job.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ref.read(snackbarServiceProvider).showError('Please select a category');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final jobData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'salaryRange': {
          'min': int.tryParse(_minSalaryController.text.trim()) ?? 0,
          'max': int.tryParse(_maxSalaryController.text.trim()) ?? 0,
        },
        'location': {'address': _addressController.text.trim()},
      };

      if (isEditMode) {
        // Update existing job
        await ref
            .read(addJobProvider.notifier)
            .updateJob(widget.jobToEdit!.id, jobData);
      } else {
        // Create new job - need merchantId
        final merchantId = await ref.read(merchantIdProvider.future);
        if (merchantId == null) {
          throw Exception('Merchant ID not found');
        }
        await ref.read(addJobProvider.notifier).createJob(jobData, merchantId);
      }

      if (mounted) {
        // Refresh the jobs list
        ref.invalidate(jobsMerchantListProvider);

        ref
            .read(snackbarServiceProvider)
            .showSuccess(
              isEditMode
                  ? 'Job updated successfully!'
                  : 'Job created successfully!',
            );

        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ref.read(snackbarServiceProvider).showError('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      drawer: const AppDrawer(),
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: isEditMode ? 'Edit Job' : 'Add New Job',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: topPadding + 80,
          left: 16,
          right: 16,
          bottom: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isEditMode
                      ? Colors.orange.withValues(alpha: 0.1)
                      : AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isEditMode ? Colors.orange : AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEditMode ? Icons.edit_outlined : Icons.work_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditMode
                                ? 'Edit Job Posting'
                                : 'Create Job Posting',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isEditMode
                                  ? Colors.orange
                                  : AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isEditMode
                                ? 'Update the job details below'
                                : 'Fill in the details to post a new job',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Job Title
              _buildSectionTitle('Job Title', Icons.title),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hintText: 'e.g., Warehouse Associate',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a job title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Category
              _buildSectionTitle('Category', Icons.category_outlined),
              const SizedBox(height: 8),
              _buildDropdown(),
              const SizedBox(height: 20),

              // Description
              _buildSectionTitle('Description', Icons.description_outlined),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hintText:
                    'Describe the job responsibilities, requirements, etc.',
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a job description';
                  }
                  if (value.trim().length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Salary Range
              _buildSectionTitle('Salary Range (\$)', Icons.attach_money),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _minSalaryController,
                      hintText: 'Min',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'to',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxSalaryController,
                      hintText: 'Max',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final min =
                            int.tryParse(_minSalaryController.text) ?? 0;
                        final max = int.tryParse(value) ?? 0;
                        if (max < min) {
                          return 'Max < Min';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Location
              _buildSectionTitle('Location', Icons.location_on_outlined),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _addressController,
                hintText: 'e.g., 123 Main Street, City, State',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isEditMode
                        ? Colors.orange
                        : AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isEditMode
                                  ? Icons.save_outlined
                                  : Icons.add_circle_outline,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isEditMode ? 'Update Job' : 'Create Job',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isEditMode ? Colors.orange : AppTheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isEditMode ? Colors.orange : AppTheme.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      hint: Text(
        'Select a category',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem(value: category, child: Text(category));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isEditMode ? Colors.orange : AppTheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
