import 'package:flutter/material.dart';
import './add_events_screen.dart';
import './member_approval_screen.dart';
import './announcement1_screen.dart';
import './view_donations_screen.dart';
import './registrations_screen.dart';
import './gallery_upload_screen.dart';
import './add_committee_payment.dart';
import './view_committee_payments.dart';
import './admin_verify_payments.dart';
import './send_payment_request_screen.dart'; // ✅ New import

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildTile(context, "📅 Add Events", Icons.event, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEventsScreen()),
              );
            }),
            _buildTile(context, "✅ Approve Members", Icons.verified_user, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ApproveMembersScreen()),
              );
            }),
            _buildTile(context, "📣 Announcements", Icons.campaign, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageAnnouncementsScreen(),
                ),
              );
            }),
            _buildTile(context, "💰 Donations", Icons.volunteer_activism, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminDonationsScreen()),
              );
            }),
            _buildTile(context, "📝 Registrations", Icons.assignment, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegistrationsScreen()),
              );
            }),
            _buildTile(context, "🖼️ Gallery", Icons.photo_library, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GalleryUploadScreen()),
              );
            }),
            _buildTile(context, "➕ Add Payment", Icons.add_card, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddCommitteePaymentScreen(),
                ),
              );
            }),
            _buildTile(
              context,
              "📤 Send Payment Request",
              Icons.request_page,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SendPaymentRequestScreen(), // ✅ New screen
                  ),
                );
              },
            ),
            _buildTile(context, "📋 View Payments", Icons.receipt_long, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ViewCommitteePaymentsScreen(),
                ),
              );
            }),
            _buildTile(context, "🧾 Verify Payments", Icons.verified, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminVerifyPaymentsScreen(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade100,
        foregroundColor: Colors.black87,
        elevation: 5,
        padding: const EdgeInsets.all(8.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
