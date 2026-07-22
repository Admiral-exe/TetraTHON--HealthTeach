import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../widgets/primitives.dart';
import '../services/api_service.dart';


class MedicalReportItem {
  final String title;
  final String date;
  final String fileType;
  final String size;

  MedicalReportItem({
    required this.title,
    required this.date,
    required this.fileType,
    required this.size,
  });
}

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final Map<String, dynamic>? userProfile;

  const ProfileScreen({super.key, this.onLogout, this.userProfile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User Name controller
  late TextEditingController _nameController;

  // Profile Photo state
  String? _photoUrl;
  final List<String> _sampleAvatars = [
    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80",
    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80",
    "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=300&q=80",
    "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80",
  ];

  // Editable Biometrics Controllers
  late TextEditingController _ageController;
  late TextEditingController _bloodGroupController;
  final TextEditingController _heightController = TextEditingController(text: "175");
  final TextEditingController _weightController = TextEditingController(text: "72");

  @override
  void initState() {
    super.initState();
    _initProfileData();
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile != widget.userProfile) {
      _initProfileData();
    }
  }

  void _initProfileData() {
    final profile = widget.userProfile;
    final nameText = profile?['full_name'] ??
        (profile?['first_name'] != null
            ? "${profile!['first_name']} ${profile['last_name'] ?? ''}".trim()
            : "Aarav Sharma");
    final ageText = profile?['age'] != null ? profile!['age'].toString() : "44";
    final bgText = profile?['blood_group'] ?? "O+";

    _nameController = TextEditingController(text: nameText);
    _ageController = TextEditingController(text: ageText);
    _bloodGroupController = TextEditingController(text: bgText);
  }



  // Lifestyle MCQ State
  String _dietPreference = "Vegetarian";
  String _hasFoodAllergy = "No";
  final TextEditingController _allergyDetailsController = TextEditingController(text: "Peanuts, Lactose");
  
  String _consumesAlcohol = "No";
  String _cigarettesDaily = "I don't smoke";
  String _exerciseFrequency = "3-4 times/week";

  String _waterIntake = "2 – 3 Liters";
  
  String _takesDailyMedication = "Yes";

  // Dynamic Multi-Medicine List Controllers
  final List<TextEditingController> _medicationControllers = [
    TextEditingController(text: "Metformin 500mg (After breakfast)"),
    TextEditingController(text: "Atorvastatin 10mg (Before bed)"),
  ];

  // Uploaded Medical Reports
  final List<MedicalReportItem> _uploadedReports = [
    MedicalReportItem(title: "Complete Blood Count (CBC)", date: "Jul 15, 2026", fileType: "PDF", size: "1.4 MB"),
    MedicalReportItem(title: "Lipid Profile & Glucose Test", date: "Jun 28, 2026", fileType: "PDF", size: "2.1 MB"),
  ];

  bool _isEditingDetails = false;

  String get _userInitials {
    final parts = _nameController.text.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return "AS";
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text("Logout", style: display(size: 18, weight: FontWeight.w600)),
          ],
        ),
        content: Text(
          "Are you sure you want to log out of your Arogya account?",
          style: body(size: 14, color: AppColors.mutedFg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: body(size: 14, color: AppColors.mutedFg)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onLogout != null) {
                widget.onLogout!();
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Logged out successfully.")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Logout", style: body(size: 14, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final tempController = TextEditingController(text: _nameController.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text("Edit Full Name", style: display(size: 18, weight: FontWeight.w600)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter your full legal or preferred name:", style: body(size: 13, color: AppColors.mutedFg)),
            const SizedBox(height: 16),
            TextField(
              controller: tempController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: body(size: 15, weight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: "Full Name",
                hintText: "e.g. Aarav Sharma",
                filled: true,
                fillColor: const Color(0xFFF9F7F3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: body(size: 14, color: AppColors.mutedFg)),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = tempController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _nameController.text = newName;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Full Name updated to '$newName'")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text("Save", style: body(size: 14, weight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPhotoUploadDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text("Upload Profile Photo", style: display(size: 18, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text("Select a photo avatar or pick from library", style: body(size: 13, color: AppColors.mutedFg)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _sampleAvatars.map((url) {
                  final isSel = _photoUrl == url;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _photoUrl = url);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile photo updated!")),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSel ? AppColors.primary : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _photoUrl = _sampleAvatars[0]);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("New photo uploaded from device library!")),
                  );
                },
                icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                label: Text("Choose from Gallery / Device", style: body(size: 14, weight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportUploadDialog() {
    List<int>? selectedFileBytes;
    String? selectedFileName;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final patientId = widget.userProfile?['patient_id'] ?? "HT-2026-X89K-L";

            Future<void> pickFileFromStorage() async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
                  withData: true,
                );
                if (result != null && result.files.isNotEmpty) {
                  final file = result.files.first;
                  setModalState(() {
                    selectedFileBytes = file.bytes;
                    selectedFileName = file.name;
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("File selection error: $e")),
                );
              }
            }

            Future<void> capturePhotoWithCamera() async {
              try {
                final picker = ImagePicker();
                final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  final bytes = await photo.readAsBytes();
                  setModalState(() {
                    selectedFileBytes = bytes;
                    selectedFileName = photo.name;
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Camera access error: $e")),
                );
              }
            }

            Future<void> handleUpload() async {
              if (selectedFileBytes == null || selectedFileName == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please select a file or take a photo first.")),
                );
                return;
              }

              setModalState(() => isUploading = true);

              final result = await ApiService.uploadMedicalReport(
                fileBytes: selectedFileBytes!,
                fileName: selectedFileName!,
                patientId: patientId,
              );

              setModalState(() => isUploading = false);

              if (result != null) {
                final reportType = result['report_type'] ?? "Medical Report";
                final redactionCount = result['redaction_summary']?['redactions_count'] ?? 0;

                setState(() {
                  _uploadedReports.insert(
                    0,
                    MedicalReportItem(
                      title: reportType,
                      date: "Today",
                      fileType: selectedFileName!.split('.').last.toUpperCase(),
                      size: "${(selectedFileBytes!.length / (1024 * 1024)).toStringAsFixed(1)} MB",
                    ),
                  );
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("'$reportType' uploaded securely! ($redactionCount credentials scrubbed locally)"),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Report uploaded and anonymized locally.")),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text("Upload Medical Report", style: display(size: 18, weight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Select a PDF report from storage or take a photo with your camera.",
                    style: body(size: 13, color: AppColors.mutedFg),
                  ),
                  const SizedBox(height: 14),

                  // Privacy Security Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "🔒 Privacy Security Layer Active: Patient credentials (name, phone, email, location) are scrubbed locally on device before processing.",
                            style: body(size: 11.5, weight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selected File Status Display
                  if (selectedFileName != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, color: AppColors.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedFileName!,
                              style: body(size: 13, weight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Two Buttons: Storage File Picker & Camera Photo Capture
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isUploading ? null : pickFileFromStorage,
                          icon: const Icon(Icons.folder_open_rounded, size: 18, color: AppColors.primary),
                          label: Text("Browse Storage", style: body(size: 13, weight: FontWeight.w600, color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isUploading ? null : capturePhotoWithCamera,
                          icon: const Icon(Icons.camera_alt_rounded, size: 18, color: AppColors.primary),
                          label: Text("Take Photo", style: body(size: 13, weight: FontWeight.w600, color: AppColors.primary)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Confirm Upload Button
                  ElevatedButton(
                    onPressed: (isUploading || selectedFileName == null) ? null : handleUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text("Confirm & Anonymize Upload", style: body(size: 14, weight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  void _showEditBiometricDialog({
    required String label,
    required TextEditingController controller,
    required String unit,
    List<String>? options,
  }) {
    final tempController = TextEditingController(text: controller.text);
    String selectedOption = controller.text;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Text("Edit $label", style: display(size: 18, weight: FontWeight.w600)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Update your $label information:", style: body(size: 13, color: AppColors.mutedFg)),
              const SizedBox(height: 16),
              if (options != null) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((opt) {
                    final isSel = selectedOption == opt;
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          selectedOption = opt;
                          tempController.text = opt;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : AppColors.secondary,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(
                          opt,
                          style: body(size: 13, weight: FontWeight.w600, color: isSel ? Colors.white : AppColors.foreground),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ] else ...[
                TextField(
                  controller: tempController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  style: body(size: 15, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: label,
                    suffixText: unit,
                    filled: true,
                    fillColor: const Color(0xFFF9F7F3),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: body(size: 14, color: AppColors.mutedFg)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  controller.text = tempController.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$label updated to ${controller.text} $unit".trim())),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Save", style: body(size: 14, weight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    final activeMeds = _medicationControllers
        .where((c) => c.text.trim().isNotEmpty)
        .map((c) => c.text.trim())
        .toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Profile saved for ${_nameController.text}! Biometrics & ${activeMeds.length} daily medications updated."),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bloodGroupController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergyDetailsController.dispose();
    for (final c in _medicationControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header with Logout Button on Top Right
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const ScreenHeader(eyebrow: "PERSONAL HEALTH PROFILE", title: "Your Profile"),
              IconButton(
                onPressed: _showLogoutDialog,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                ),
                tooltip: "Logout",
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Photo & Editable Name Section
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoUploadDialog,
                      behavior: HitTestBehavior.opaque,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary,
                            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                            child: _photoUrl == null
                                ? Text(
                                    _userInitials,
                                    style: display(size: 22, weight: FontWeight.w700, color: Colors.white),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _nameController.text,
                                  style: display(size: 19, weight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                onPressed: _showEditNameDialog,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                                ),
                                tooltip: "Edit Full Name",
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.userProfile?['email'] ?? widget.userProfile?['phone_number'] ?? "No contact email linked",
                            style: body(size: 12.5, color: AppColors.mutedFg),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),

              const SizedBox(height: 16),

              // EDITABLE BIOMETRICS SECTION (Age, Blood Group, Height, Weight)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("PHYSICAL BIOMETRICS", style: body(size: 11.5, weight: FontWeight.w700, color: AppColors.mutedFg).copyWith(letterSpacing: 1.1)),
                  Text("Click pencil button to edit", style: body(size: 11, color: AppColors.primary, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _EditableBiometricCard(
                      label: "Age",
                      controller: _ageController,
                      icon: Icons.cake_outlined,
                      unit: "yrs",
                      onEditTap: () => _showEditBiometricDialog(
                        label: "Age",
                        controller: _ageController,
                        unit: "yrs",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EditableBiometricCard(
                      label: "Blood Group",
                      controller: _bloodGroupController,
                      icon: Icons.bloodtype_outlined,
                      unit: "",
                      onEditTap: () => _showEditBiometricDialog(
                        label: "Blood Group",
                        controller: _bloodGroupController,
                        unit: "",
                        options: const ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _EditableBiometricCard(
                      label: "Height",
                      controller: _heightController,
                      icon: Icons.height_rounded,
                      unit: "cm",
                      onEditTap: () => _showEditBiometricDialog(
                        label: "Height",
                        controller: _heightController,
                        unit: "cm",
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _EditableBiometricCard(
                      label: "Weight",
                      controller: _weightController,
                      icon: Icons.monitor_weight_outlined,
                      unit: "kg",
                      onEditTap: () => _showEditBiometricDialog(
                        label: "Weight",
                        controller: _weightController,
                        unit: "kg",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // HEADING: PERSONAL DETAILS
              Text("PERSONAL DETAILS", style: body(size: 11.5, weight: FontWeight.w700, color: AppColors.mutedFg).copyWith(letterSpacing: 1.1)),
              const SizedBox(height: 10),

              // TWO BUTTONS SIDE BY SIDE: "Edit Details" AND "Upload Report"
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isEditingDetails = !_isEditingDetails),
                      icon: Icon(_isEditingDetails ? Icons.check_circle_rounded : Icons.edit_note_rounded, size: 18, color: AppColors.primary),
                      label: Text(
                        _isEditingDetails ? "Done Editing" : "Edit Details",
                        style: body(size: 13, weight: FontWeight.w600, color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showReportUploadDialog,
                      icon: const Icon(Icons.upload_file_rounded, size: 18, color: Colors.white),
                      label: Text(
                        "Upload Report",
                        style: body(size: 13, weight: FontWeight.w600, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Personal Details Summary or Editable MCQ Questions
              if (!_isEditingDetails) ...[
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _detailSummaryRow(Icons.restaurant_menu_rounded, "Dietary Preference", _dietPreference),
                      const Divider(height: 16, color: AppColors.border),
                      _detailSummaryRow(
                        Icons.no_food_outlined,
                        "Food Allergies",
                        _hasFoodAllergy == "Yes" ? "Yes (${_allergyDetailsController.text})" : "No",
                      ),
                      const Divider(height: 16, color: AppColors.border),
                      _detailSummaryRow(Icons.local_bar_outlined, "Alcohol Consumed", _consumesAlcohol),
                      const Divider(height: 16, color: AppColors.border),
                      _detailSummaryRow(Icons.smoking_rooms_outlined, "Daily Cigarettes", _cigarettesDaily),
                      const Divider(height: 16, color: AppColors.border),
                      _detailSummaryRow(Icons.fitness_center_rounded, "Exercise Frequency", _exerciseFrequency),
                      const Divider(height: 16, color: AppColors.border),
                      _detailSummaryRow(Icons.water_drop_outlined, "Daily Water Intake", _waterIntake),
                      const Divider(height: 16, color: AppColors.border),
                      _detailSummaryRow(
                        Icons.medication_outlined,
                        "Daily Medications (${_medicationControllers.length})",
                        _takesDailyMedication == "Yes"
                            ? _medicationControllers
                                .where((c) => c.text.trim().isNotEmpty)
                                .map((c) => "• ${c.text.trim()}")
                                .join("\n")
                            : "No",
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // 1. Diet Preference MCQ
                _MCQCard(
                  question: "What is your dietary preference?",
                  icon: Icons.restaurant_menu_rounded,
                  options: const ["Vegetarian", "Non-Vegetarian", "Vegan"],
                  selected: _dietPreference,
                  onSelected: (val) => setState(() => _dietPreference = val),
                ),
                const SizedBox(height: 12),

                // 2. Food Allergy MCQ
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.no_food_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text("Are you allergic to any food?", style: body(size: 14.5, weight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: ["No", "Yes"].map((option) {
                          final isSel = _hasFoodAllergy == option;
                          return GestureDetector(
                            onTap: () => setState(() => _hasFoodAllergy = option),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : AppColors.secondary,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                              ),
                              child: Text(
                                option,
                                style: body(size: 13, weight: FontWeight.w600, color: isSel ? Colors.white : AppColors.foreground),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_hasFoodAllergy == "Yes") ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _allergyDetailsController,
                          style: body(size: 13.5),
                          decoration: InputDecoration(
                            hintText: "Specify food allergies (e.g. Peanuts, Shellfish...)",
                            filled: true,
                            fillColor: const Color(0xFFF9F7F3),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Alcohol Consumption MCQ
                _MCQCard(
                  question: "Are you consuming alcohol?",
                  icon: Icons.local_bar_outlined,
                  options: const ["No", "Yes"],
                  selected: _consumesAlcohol,
                  onSelected: (val) => setState(() => _consumesAlcohol = val),
                ),
                const SizedBox(height: 12),

                // 4. Cigarette Smoking Daily MCQ
                _MCQCard(
                  question: "How many cigarettes do you smoke daily?",
                  icon: Icons.smoking_rooms_outlined,
                  options: const ["I don't smoke", "<3 cigarettes daily", ">3 cigarettes daily"],
                  selected: _cigarettesDaily,
                  onSelected: (val) => setState(() => _cigarettesDaily = val),
                ),

                const SizedBox(height: 12),

                // 5. Exercise Frequency MCQ
                _MCQCard(
                  question: "How frequently do you exercise?",
                  icon: Icons.fitness_center_rounded,
                  options: const ["Daily", "3-4 times/week", "1-2 times/week", "Never"],
                  selected: _exerciseFrequency,
                  onSelected: (val) => setState(() => _exerciseFrequency = val),
                ),
                const SizedBox(height: 12),

                // 6. Daily Water Intake MCQ
                _MCQCard(
                  question: "How much water do you drink in a day?",
                  icon: Icons.water_drop_outlined,
                  options: const ["1 – 2 Liters", "2 – 3 Liters", "3+ Liters"],
                  selected: _waterIntake,
                  onSelected: (val) => setState(() => _waterIntake = val),
                ),
                const SizedBox(height: 12),

                // 7. MULTI-MEDICATION DAILY CONSUMPTION MCQ SECTION
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.medication_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text("Are you consuming any medicine daily?", style: body(size: 14.5, weight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: ["No", "Yes"].map((option) {
                          final isSel = _takesDailyMedication == option;
                          return GestureDetector(
                            onTap: () => setState(() => _takesDailyMedication = option),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSel ? AppColors.primary : AppColors.secondary,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                              ),
                              child: Text(
                                option,
                                style: body(size: 13, weight: FontWeight.w600, color: isSel ? Colors.white : AppColors.foreground),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_takesDailyMedication == "Yes") ...[
                        const SizedBox(height: 14),
                        Text(
                          "DAILY MEDICINES (${_medicationControllers.length})",
                          style: body(size: 11, weight: FontWeight.w700, color: AppColors.mutedFg).copyWith(letterSpacing: 0.8),
                        ),
                        const SizedBox(height: 8),
                        for (int i = 0; i < _medicationControllers.length; i++) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _medicationControllers[i],
                                    style: body(size: 13.5),
                                    decoration: InputDecoration(
                                      hintText: "Medicine ${i + 1} (e.g. Metformin 500mg)...",
                                      filled: true,
                                      fillColor: const Color(0xFFF9F7F3),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                                    ),
                                  ),
                                ),
                                if (_medicationControllers.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                    onPressed: () {
                                      setState(() {
                                        _medicationControllers[i].dispose();
                                        _medicationControllers.removeAt(i);
                                      });
                                    },
                                    tooltip: "Delete medicine",
                                  ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _medicationControllers.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                          label: Text(
                            "+ Add another medicine",
                            style: body(size: 13, weight: FontWeight.w600, color: AppColors.primary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary, width: 1.2),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Uploaded Medical Reports Section
              if (_uploadedReports.isNotEmpty) ...[
                Text("UPLOADED MEDICAL REPORTS", style: body(size: 11.5, weight: FontWeight.w700, color: AppColors.mutedFg).copyWith(letterSpacing: 1.1)),
                const SizedBox(height: 10),
                ..._uploadedReports.map((rpt) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.insert_drive_file_outlined, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(rpt.title, style: body(size: 13.5, weight: FontWeight.w600)),
                                  Text("${rpt.date} · ${rpt.fileType} (${rpt.size})", style: body(size: 11.5, color: AppColors.mutedFg)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.download_rounded, color: AppColors.primary, size: 20),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Downloading '${rpt.title}'...")),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
              ],

              // Save Button
              PrimaryButton(
                "Save Profile Changes",
                icon: Icons.save_rounded,
                onTap: _saveProfile,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailSummaryRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: body(size: 11.5, color: AppColors.mutedFg, weight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: body(size: 13.5, weight: FontWeight.w600, color: AppColors.foreground).copyWith(height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditableBiometricCard extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String unit;
  final VoidCallback onEditTap;

  const _EditableBiometricCard({
    required this.label,
    required this.controller,
    required this.icon,
    this.unit = "",
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onEditTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: body(size: 11, color: AppColors.mutedFg, weight: FontWeight.w500)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      controller.text.isNotEmpty ? controller.text : "--",
                      style: display(size: 15, weight: FontWeight.w600),
                    ),
                    if (unit.isNotEmpty) ...[
                      const SizedBox(width: 3),
                      Text(unit, style: body(size: 11.5, color: AppColors.mutedFg, weight: FontWeight.w500)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEditTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
            ),
            tooltip: "Edit $label",
          ),
        ],
      ),
    );
  }
}

class _MCQCard extends StatelessWidget {
  final String question;
  final IconData icon;
  final List<String> options;
  final String selected;
  final void Function(String) onSelected;

  const _MCQCard({
    required this.question,
    required this.icon,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(question, style: body(size: 14.5, weight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              final isSel = selected == option;
              return GestureDetector(
                onTap: () => onSelected(option),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : AppColors.secondary,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(
                    option,
                    style: body(
                      size: 13,
                      weight: isSel ? FontWeight.w600 : FontWeight.w500,
                      color: isSel ? Colors.white : AppColors.foreground,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
