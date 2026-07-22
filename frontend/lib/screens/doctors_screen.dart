import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/primitives.dart';
import '../data/doctors_data.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedSpecialityId = ""; // empty = All
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorModel> get _filteredDoctors {
    return allDoctors.where((doc) {
      final matchesSpeciality = _selectedSpecialityId.isEmpty || doc.specialityId == _selectedSpecialityId;
      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          doc.name.toLowerCase().contains(q) ||
          doc.speciality.toLowerCase().contains(q) ||
          doc.degrees.toLowerCase().contains(q) ||
          doc.hospital.toLowerCase().contains(q);
      return matchesSpeciality && matchesQuery;
    }).toList();
  }

  void _openAllSpecialitiesSheet() {
    final sheetSearchController = TextEditingController();
    List<MedicalSpeciality> displayedSpecialities = List.from(medicalSpecialities);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void filterSpecialities(String q) {
              final query = q.toLowerCase().trim();
              setSheetState(() {
                displayedSpecialities = medicalSpecialities.where((s) {
                  return s.name.toLowerCase().contains(query);
                }).toList();
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("All Medical Specialities (25)", style: display(size: 18, weight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.mutedFg),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search Bar inside Specialities Sheet
                    TextField(
                      controller: sheetSearchController,
                      onChanged: filterSpecialities,
                      style: body(size: 14),
                      decoration: InputDecoration(
                        hintText: "Search speciality (e.g. Cardiology, Neurology)...",
                        hintStyle: body(size: 13, color: AppColors.mutedFg),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                        filled: true,
                        fillColor: const Color(0xFFF9F7F3),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: GridView.builder(
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.95,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: displayedSpecialities.length,
                        itemBuilder: (context, index) {
                          final spec = displayedSpecialities[index];
                          final isSelected = _selectedSpecialityId == spec.id;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedSpecialityId = isSelected ? "" : spec.id;
                              });
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.secondary : AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isSelected ? AppColors.primary : AppColors.secondary,
                                    child: Icon(
                                      spec.icon,
                                      size: 20,
                                      color: isSelected ? Colors.white : AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    spec.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: body(
                                      size: 11.5,
                                      weight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppColors.primary : AppColors.foreground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openDoctorBookingModal(DoctorModel doctor) {
    int selectedDateIdx = 0;
    String selectedTimeSlot = "10:00 AM";

    final List<Map<String, String>> daysList = [
      {"day": "FRI", "date": "16"},
      {"day": "SAT", "date": "17"},
      {"day": "SUN", "date": "18"},
      {"day": "MON", "date": "19"},
      {"day": "TUE", "date": "20"},
      {"day": "WED", "date": "21"},
    ];

    final List<String> timeSlots = [
      "09:00 AM",
      "10:00 AM",
      "11:00 AM",
      "01:00 PM",
      "02:00 PM",
      "03:00 PM",
      "04:00 PM",
      "05:00 PM",
    ];

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
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
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

                      // Doctor Header Card
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: AppColors.primary,
                            backgroundImage: NetworkImage(doctor.photoUrl),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(doctor.name, style: display(size: 19, weight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "${doctor.degrees} · Exp: ${doctor.experience}",
                                    style: body(size: 12, weight: FontWeight.w600, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text("${doctor.rating} (${doctor.reviewCount})", style: body(size: 12.5, weight: FontWeight.w600)),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.location_on_outlined, size: 15, color: AppColors.mutedFg),
                                    const SizedBox(width: 2),
                                    Text(doctor.distance, style: body(size: 12, color: AppColors.mutedFg)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Speciality Chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: doctor.specialityTags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              tag,
                              style: body(size: 11.5, weight: FontWeight.w600, color: AppColors.primary),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // Doctor Biography
                      Text("Doctor Biography", style: display(size: 16, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                        doctor.biography,
                        style: body(size: 13, color: AppColors.mutedFg).copyWith(height: 1.45),
                      ),
                      const SizedBox(height: 20),

                      // Select Date Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Select Date", style: display(size: 16, weight: FontWeight.w600)),
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined, size: 15, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text("16 Aug, Friday", style: body(size: 12.5, weight: FontWeight.w600, color: AppColors.primary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Horizontal Days Selector Chips
                      SizedBox(
                        height: 68,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: daysList.length,
                          itemBuilder: (context, idx) {
                            final isSel = selectedDateIdx == idx;
                            final dayItem = daysList[idx];
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedDateIdx = idx),
                              child: Container(
                                width: 56,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  color: isSel ? AppColors.primary : AppColors.secondary,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayItem["day"]!,
                                      style: body(
                                        size: 11,
                                        weight: FontWeight.w600,
                                        color: isSel ? Colors.white70 : AppColors.mutedFg,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      dayItem["date"]!,
                                      style: display(
                                        size: 18,
                                        weight: FontWeight.bold,
                                        color: isSel ? Colors.white : AppColors.foreground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Specific Date Picker Button
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.event_outlined, size: 16, color: AppColors.primary),
                        label: Text("Specific Date", style: body(size: 12.5, weight: FontWeight.w600, color: AppColors.primary)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Select Time Section
                      Text("Select Time", style: display(size: 16, weight: FontWeight.w600)),
                      const SizedBox(height: 12),

                      // Time Slots Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: timeSlots.length,
                        itemBuilder: (context, idx) {
                          final slot = timeSlots[idx];
                          final isSel = selectedTimeSlot == slot;
                          final isUnavailable = slot == "09:00 AM";

                          return GestureDetector(
                            onTap: isUnavailable ? null : () => setModalState(() => selectedTimeSlot = slot),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isUnavailable
                                    ? const Color(0xFFEEEEEE)
                                    : isSel
                                        ? AppColors.primary
                                        : AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isUnavailable
                                      ? Colors.transparent
                                      : isSel
                                          ? AppColors.primary
                                          : AppColors.border,
                                ),
                              ),
                              child: Text(
                                slot,
                                style: body(
                                  size: 12.5,
                                  weight: FontWeight.w600,
                                  color: isUnavailable
                                      ? Colors.grey
                                      : isSel
                                          ? Colors.white
                                          : AppColors.foreground,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Book Appointment Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAppointmentScheduledDialog(
                            doctor: doctor,
                            dateStr: "${daysList[selectedDateIdx]['day']} ${daysList[selectedDateIdx]['date']} Aug",
                            timeSlot: selectedTimeSlot,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "BOOK AN APPOINTMENT (₹${doctor.fees})",
                              style: body(size: 15, weight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAppointmentScheduledDialog({
    required DoctorModel doctor,
    required String dateStr,
    required String timeSlot,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 52),
            ),
            const SizedBox(height: 16),
            Text(
              "Appointment Scheduled!",
              style: display(size: 20, weight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "Your appointment with ${doctor.name} has been successfully confirmed.",
              style: body(size: 13, color: AppColors.mutedFg),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.medical_services_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          doctor.speciality,
                          style: body(size: 13, weight: FontWeight.w700, color: AppColors.primary),
                        ),
                      ),
                      Text("₹${doctor.fees}", style: body(size: 13, weight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  const Divider(height: 16, color: AppColors.border),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 15, color: AppColors.mutedFg),
                      const SizedBox(width: 6),
                      Text(dateStr, style: body(size: 12.5, weight: FontWeight.w600)),
                      const Spacer(),
                      const Icon(Icons.access_time_rounded, size: 15, color: AppColors.mutedFg),
                      const SizedBox(width: 6),
                      Text(timeSlot, style: body(size: 12.5, weight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text("Done", style: body(size: 14, weight: FontWeight.w600, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredDoctors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Screen Header
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: ScreenHeader(eyebrow: "NEARBY SPECIALISTS", title: "Find Best Doctors"),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. LOOKING FOR DOCTOR BANNER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0F524A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Looking for\nDoctor?",
                            style: display(size: 24, weight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _openAllSpecialitiesSheet,
                            icon: const Icon(Icons.search_rounded, size: 16, color: AppColors.primary),
                            label: Text(
                              "Find Specialist",
                              style: body(size: 13, weight: FontWeight.bold, color: AppColors.primary),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.medical_information_rounded, size: 44, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. SEARCH BAR
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: body(size: 14.5),
                decoration: InputDecoration(
                  hintText: "Search doctor, speciality or clinic...",
                  hintStyle: body(size: 13.5, color: AppColors.mutedFg),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 3. FIND YOUR DOCTOR (SPECIALITIES LIST)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Find Your Doctor", style: display(size: 18, weight: FontWeight.bold)),
                  GestureDetector(
                    onTap: _openAllSpecialitiesSheet,
                    child: Text(
                      "See All (25)",
                      style: body(size: 13, weight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Horizontal Speciality Chips
              SizedBox(
                height: 98,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: medicalSpecialities.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final spec = medicalSpecialities[index];
                    final isSel = _selectedSpecialityId == spec.id;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSpecialityId = isSel ? "" : spec.id;
                        });
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : AppColors.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? AppColors.primary : AppColors.border,
                                width: isSel ? 2 : 1,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Icon(
                              spec.icon,
                              size: 26,
                              color: isSel ? Colors.white : AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 72,
                            child: Text(
                              spec.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: body(
                                size: 11.5,
                                weight: isSel ? FontWeight.bold : FontWeight.w500,
                                color: isSel ? AppColors.primary : AppColors.foreground,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 4. POPULAR DOCTORS LIST HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedSpecialityId.isEmpty
                        ? "Popular Doctors (50)"
                        : "${medicalSpecialities.firstWhere((s) => s.id == _selectedSpecialityId).name} Specialists",
                    style: display(size: 18, weight: FontWeight.bold),
                  ),
                  if (_selectedSpecialityId.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _selectedSpecialityId = ""),
                      child: Text("Clear Filter", style: body(size: 12.5, color: Colors.red, weight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // DOCTORS VERTICAL LIST
              if (filtered.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppColors.mutedFg),
                        const SizedBox(height: 10),
                        Text("No doctors found matching your query", style: body(size: 14, color: AppColors.mutedFg)),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            backgroundImage: NetworkImage(doc.photoUrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        doc.name,
                                        style: display(size: 16, weight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      "Fees ₹${doc.fees}",
                                      style: body(size: 13, weight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${doc.degrees} · ${doc.speciality}",
                                  style: body(size: 12, color: AppColors.mutedFg),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text("${doc.rating}", style: body(size: 12, weight: FontWeight.bold)),
                                    Text(" (${doc.reviewCount})", style: body(size: 11.5, color: AppColors.mutedFg)),
                                    const Spacer(),
                                    ElevatedButton(
                                      onPressed: () => _openDoctorBookingModal(doc),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        "Book Now",
                                        style: body(size: 12.5, weight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }
}
