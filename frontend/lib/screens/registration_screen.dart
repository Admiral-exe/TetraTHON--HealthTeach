import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

class RegistrationScreen extends StatefulWidget {
  final String phoneNumber;
  final Function(Map<String, dynamic> userProfile) onProfileComplete;

  const RegistrationScreen({
    super.key,
    required this.phoneNumber,
    required this.onProfileComplete,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _ageController = TextEditingController();


  String _selectedGender = "Male";
  String _selectedBloodGroup = "O+";
  List<String> _selectedChronicDiseases = [];
  bool _consentAccepted = false;
  String? _validationError;

  // Curated list of chronic conditions based on systemic health matrix
  final List<String> _allChronicDiseases = [
    "Type 2 Diabetes",
    "Type 1 Diabetes",
    "Essential Hypertension",
    "Asthma",
    "COPD (Chronic Obstructive Pulmonary Disease)",
    "Hypothyroidism",
    "Hyperthyroidism",
    "Rheumatoid Arthritis",
    "Osteoarthritis",
    "GERD (Acid Reflux)",
    "Chronic Kidney Disease",
    "Migraine Headache",
    "Coronary Artery Disease",
    "Congestive Heart Failure",
    "Atrial Fibrillation",
    "Sleep Apnea",
    "Psoriasis",
    "Gouty Arthritis",
    "Iron Deficiency Anemia",
    "Irritable Bowel Syndrome (IBS)",
    "Crohn's Disease",
    "Ulcerative Colitis",
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _openChronicDiseasePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _ChronicDiseaseSearchModal(
          allDiseases: _allChronicDiseases,
          initialSelected: List.from(_selectedChronicDiseases),
          onSelectionSaved: (selected) {
            setState(() {
              _selectedChronicDiseases = selected;
            });
          },
        );
      },
    );
  }

  void _submitRegistration() {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText);

    if (firstName.isEmpty || lastName.isEmpty || age == null || age <= 0) {
      setState(() => _validationError = "Please fill in all compulsory fields (*).");
      return;
    }

    if (!_consentAccepted) {
      setState(() => _validationError = "Please accept the Terms & Conditions and Permission notice to continue.");
      return;
    }

    setState(() => _validationError = null);

    // Prepare patient profile JSON payload
    final Map<String, dynamic> patientPayload = {
      "phone_number": widget.phoneNumber,
      "first_name": firstName,
      "last_name": lastName,
      "full_name": "$firstName $lastName",
      "email": _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      "age": age,
      "gender": _selectedGender,
      "blood_group": _selectedBloodGroup,
      "chronic_diseases": _selectedChronicDiseases,
      "consent_given": _consentAccepted,
      "permissions_granted": [
        "Camera",
        "Storage / Files & Media",
        "Microphone",
        "Bluetooth / Nearby Devices"
      ],
    };

    // 1. INSTANT NAVIGATION TO HOME PAGE (Zero UI lag)
    widget.onProfileComplete(patientPayload);

    // 2. BACKGROUND NON-BLOCKING MONGO DB SAVE & PATIENT ID GENERATION
    ApiService.registerPatient(patientPayload).then((response) {
      if (response != null && response.containsKey('patient_id')) {
        debugPrint("[Background Registration Complete] Patient ID: ${response['patient_id']}");
      }
    }).catchError((err) {
      debugPrint("[Background Registration Error] $err");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text("Complete Your Profile", style: display(size: 20, weight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mobile Verified: ${widget.phoneNumber}",
                              style: body(size: 14, weight: FontWeight.w600, color: AppColors.primary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Set up your health profile to receive personalized AI triage and records tracking.",
                              style: body(size: 12, color: AppColors.foreground.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_validationError != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tier3,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.tier3Solid.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.tier3Solid, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_validationError!, style: body(size: 13, color: AppColors.tier3Fg)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // --- Personal Information Section ---
                _sectionHeader("Personal Details"),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: "First Name *",
                        hint: "John",
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: "Surname / Last Name *",
                        hint: "Doe",
                        icon: Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _emailController,
                  label: "Email Address (Optional)",
                  hint: "john.doe@example.com",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField(
                        controller: _ageController,
                        label: "Age (Years) *",
                        hint: "e.g. 32",
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildDropdownField(
                        label: "Gender *",
                        value: _selectedGender,
                        items: ["Male", "Female", "Other", "Prefer not to say"],
                        onChanged: (val) => setState(() => _selectedGender = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildDropdownField(
                  label: "Blood Group *",
                  value: _selectedBloodGroup,
                  items: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"],
                  onChanged: (val) => setState(() => _selectedBloodGroup = val!),
                ),
                const SizedBox(height: 24),

                // --- Medical History Section ---
                _sectionHeader("Medical History (Optional)"),

                InkWell(
                  onTap: _openChronicDiseasePicker,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Chronic Diseases / Pre-existing Conditions",
                                style: body(size: 12, color: AppColors.mutedFg),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedChronicDiseases.isEmpty
                                    ? "Tap to search and select (Optional)"
                                    : _selectedChronicDiseases.join(", "),
                                style: body(
                                  size: 14,
                                  weight: _selectedChronicDiseases.isEmpty
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                  color: _selectedChronicDiseases.isEmpty
                                      ? AppColors.mutedFg
                                      : AppColors.foreground,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down_rounded, color: AppColors.mutedFg),
                      ],
                    ),
                  ),
                ),
                if (_selectedChronicDiseases.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _selectedChronicDiseases.map((disease) {
                      return Chip(
                        label: Text(disease, style: body(size: 12, color: AppColors.primary, weight: FontWeight.w500)),
                        backgroundColor: AppColors.secondary,
                        deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.primary),
                        onDeleted: () {
                          setState(() {
                            _selectedChronicDiseases.remove(disease);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 28),

                // --- App Permissions & Consent Terms Section ---
                _sectionHeader("Required App Permissions & Consent"),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Arogya requires access to the following hardware & device features for optimal diagnostic support:",
                        style: body(size: 13, color: AppColors.foreground.withOpacity(0.9)),
                      ),
                      const SizedBox(height: 12),
                      _permissionTile(Icons.camera_alt_outlined, "Camera", "For scanning medical prescription PDFs and visual symptom triage."),
                      _permissionTile(Icons.folder_open_rounded, "Storage / Files & Media", "For attaching lab reports and downloading clinical PDF summaries."),
                      _permissionTile(Icons.mic_none_rounded, "Microphone", "For ambient voice symptom check-ins and AI audio processing."),
                      _permissionTile(Icons.bluetooth_searching_rounded, "Bluetooth / Nearby Devices", "For connecting smart health monitors (SpO2, Heart Rate, BP)."),
                      const Divider(height: 24, color: AppColors.border),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _consentAccepted,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() => _consentAccepted = val ?? false);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _consentAccepted = !_consentAccepted),
                              child: Text(
                                "I have read and agree to the Terms & Conditions, Privacy Policy, and grant the app permissions listed above.",
                                style: body(size: 13, weight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Complete Setup Action Button
                ElevatedButton(
                  onPressed: _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Complete Setup",
                        style: body(size: 16, weight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    }


  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: display(size: 16, weight: FontWeight.bold, color: AppColors.primary),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: body(size: 13, weight: FontWeight.w500, color: AppColors.foreground)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: body(size: 15, weight: FontWeight.w500),
            decoration: InputDecoration(
              icon: Icon(icon, color: AppColors.mutedFg, size: 20),
              hintText: hint,
              hintStyle: body(size: 14, color: AppColors.mutedFg.withOpacity(0.7)),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: body(size: 13, weight: FontWeight.w500, color: AppColors.foreground)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.mutedFg),
              items: items.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item, style: body(size: 15, weight: FontWeight.w500)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _permissionTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: body(size: 13, weight: FontWeight.w600)),
                Text(subtitle, style: body(size: 12, color: AppColors.mutedFg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Searchable Chronic Disease Bottom Sheet Modal
class _ChronicDiseaseSearchModal extends StatefulWidget {
  final List<String> allDiseases;
  final List<String> initialSelected;
  final ValueChanged<List<String>> onSelectionSaved;

  const _ChronicDiseaseSearchModal({
    required this.allDiseases,
    required this.initialSelected,
    required this.onSelectionSaved,
  });

  @override
  State<_ChronicDiseaseSearchModal> createState() => _ChronicDiseaseSearchModalState();
}

class _ChronicDiseaseSearchModalState extends State<_ChronicDiseaseSearchModal> {
  final _searchController = TextEditingController();
  late List<String> _tempSelected;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredDiseases = widget.allDiseases
        .where((d) => d.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Select Chronic Diseases", style: display(size: 18, weight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                icon: const Icon(Icons.search_rounded, color: AppColors.mutedFg),
                hintText: "Search condition (e.g. Diabetes, Asthma)...",
                hintStyle: body(size: 14, color: AppColors.mutedFg),
                border: InputBorder.none,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: filteredDiseases.isEmpty
                ? Center(
                    child: Text(
                      "No matching conditions found.",
                      style: body(size: 14, color: AppColors.mutedFg),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredDiseases.length,
                    itemBuilder: (ctx, idx) {
                      final item = filteredDiseases[idx];
                      final isChecked = _tempSelected.contains(item);
                      return CheckboxListTile(
                        value: isChecked,
                        activeColor: AppColors.primary,
                        title: Text(item, style: body(size: 14, weight: FontWeight.w500)),
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _tempSelected.add(item);
                            } else {
                              _tempSelected.remove(item);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),

          ElevatedButton(
            onPressed: () {
              widget.onSelectionSaved(_tempSelected);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Done (${_tempSelected.length} Selected)", style: body(size: 15, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
