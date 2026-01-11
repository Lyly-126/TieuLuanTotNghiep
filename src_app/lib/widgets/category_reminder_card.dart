// // ============================================================================
// // File: lib/widgets/category_reminder_card.dart
// // Widget hiển thị và cài đặt nhắc nhở cho category
// // ============================================================================
//
// import 'package:flutter/material.dart';
// import '../config/app_colors.dart';
// import '../models/category_reminder_model.dart';
//
// /// Widget cài đặt nhắc nhở cho category
// class CategoryReminderCard extends StatelessWidget {
//   final CategoryReminderModel reminder;
//   final Function(CategoryReminderModel) onUpdate;
//
//   const CategoryReminderCard({
//     Key? key,
//     required this.reminder,
//     required this.onUpdate,
//   }) : super(key: key);
//
//   static const List<String> _dayLabels = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header với toggle
//           _buildHeader(),
//
//           // Nội dung (chỉ hiện khi bật)
//           if (reminder.isEnabled) ...[
//             const SizedBox(height: 20),
//             const Divider(height: 1),
//             const SizedBox(height: 20),
//
//             // Time Picker
//             _buildTimePicker(context),
//             const SizedBox(height: 16),
//
//             // Days selector
//             _buildDaysSelector(),
//
//             // Quick select buttons
//             const SizedBox(height: 12),
//             _buildQuickSelectButtons(),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Row(
//       children: [
//         // Icon
//         Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: reminder.isEnabled
//                 ? AppColors.success.withOpacity(0.1)
//                 : AppColors.textGray.withOpacity(0.1),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Icon(
//             Icons.notifications_active_rounded,
//             color: reminder.isEnabled ? AppColors.success : AppColors.textGray,
//             size: 24,
//           ),
//         ),
//         const SizedBox(width: 12),
//
//         // Title & subtitle
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Nhắc nhở học tập',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.primaryDark,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 reminder.isEnabled && reminder.hasAnyDayEnabled
//                     ? reminder.scheduleDescription
//                     : 'Duy trì thói quen học mỗi ngày',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: reminder.isEnabled ? AppColors.textSecondary : AppColors.textGray,
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         // Toggle switch
//         Switch.adaptive(
//           value: reminder.isEnabled,
//           onChanged: (value) => onUpdate(reminder.copyWith(isEnabled: value)),
//           activeColor: AppColors.success,
//         ),
//       ],
//     );
//   }
//
//   Widget _buildTimePicker(BuildContext context) {
//     return GestureDetector(
//       onTap: () => _showTimePicker(context),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: AppColors.background,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: AppColors.success.withOpacity(0.3)),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.access_time_rounded, color: AppColors.success, size: 22),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Thời gian nhắc nhở',
//                   style: TextStyle(fontSize: 12, color: AppColors.textGray),
//                 ),
//                 Text(
//                   reminder.displayTime,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.primaryDark,
//                   ),
//                 ),
//               ],
//             ),
//             const Spacer(),
//             Icon(Icons.edit_rounded, color: AppColors.textGray, size: 18),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Future<void> _showTimePicker(BuildContext context) async {
//     final TimeOfDay? picked = await showTimePicker(
//       context: context,
//       initialTime: TimeOfDay(hour: reminder.hour, minute: reminder.minute),
//       builder: (context, child) {
//         return Theme(
//           data: Theme.of(context).copyWith(
//             colorScheme: ColorScheme.light(
//               primary: AppColors.success,
//               onPrimary: Colors.white,
//               onSurface: AppColors.primaryDark,
//             ),
//           ),
//           child: child!,
//         );
//       },
//     );
//
//     if (picked != null) {
//       onUpdate(reminder.copyWith(hour: picked.hour, minute: picked.minute));
//     }
//   }
//
//   Widget _buildDaysSelector() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             Text(
//               'Các ngày trong tuần',
//               style: TextStyle(fontSize: 13, color: AppColors.textGray),
//             ),
//             const Spacer(),
//             if (reminder.enabledDaysCount > 0)
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: AppColors.success.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Text(
//                   '${reminder.enabledDaysCount} ngày',
//                   style: TextStyle(
//                     fontSize: 11,
//                     color: AppColors.success,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: List.generate(7, (index) {
//             final isEnabled = reminder.isDayEnabled(index);
//             return GestureDetector(
//               onTap: () => onUpdate(reminder.toggleDay(index)),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 200),
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   color: isEnabled ? AppColors.success : Colors.transparent,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(
//                     color: isEnabled ? AppColors.success : AppColors.textGray.withOpacity(0.3),
//                     width: 1.5,
//                   ),
//                   boxShadow: isEnabled
//                       ? [
//                     BoxShadow(
//                       color: AppColors.success.withOpacity(0.3),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ]
//                       : null,
//                 ),
//                 child: Center(
//                   child: Text(
//                     _dayLabels[index],
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: isEnabled ? Colors.white : AppColors.textGray,
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           }),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildQuickSelectButtons() {
//     return Row(
//       children: [
//         _buildQuickSelectButton('Hàng ngày', '1111111'),
//         const SizedBox(width: 8),
//         _buildQuickSelectButton('Ngày thường', '0111110'),
//         const SizedBox(width: 8),
//         _buildQuickSelectButton('Cuối tuần', '1000001'),
//       ],
//     );
//   }
//
//   Widget _buildQuickSelectButton(String label, String daysPattern) {
//     final isActive = reminder.daysOfWeek == daysPattern;
//     return Expanded(
//       child: InkWell(
//         onTap: () => onUpdate(reminder.copyWith(daysOfWeek: daysPattern)),
//         borderRadius: BorderRadius.circular(8),
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 200),
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           decoration: BoxDecoration(
//             color: isActive ? AppColors.success.withOpacity(0.1) : Colors.transparent,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(
//               color: isActive ? AppColors.success : AppColors.textGray.withOpacity(0.2),
//             ),
//           ),
//           child: Text(
//             label,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
//               color: isActive ? AppColors.success : AppColors.textGray,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }