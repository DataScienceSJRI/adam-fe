import 'package:adam/bloc/auth/logout_bloc.dart';
import 'package:adam/bloc/profile/profile_bloc.dart';
import 'package:adam/data/models/profile_model.dart';
import 'package:adam/data/repositories/logout_repository.dart';
import 'package:adam/data/repositories/profile_repository.dart';
import 'package:adam/ui/screens/login_screen.dart';
import 'package:adam/ui/shared_widgets/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _field(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,

      decoration: InputDecoration(
        hintText: hint,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, ProfileModel profile) {
    final ageController = TextEditingController(text: profile.age.toString());

    final weightController = TextEditingController(
      text: profile.weight.toString(),
    );

    final heightController = TextEditingController(
      text: profile.height.toString(),
    );

    final hba1cController = TextEditingController(
      text: profile.hba1c.toString(),
    );

    final genderController = TextEditingController(text: profile.gender);

    final activityController = TextEditingController(
      text: profile.activityLevel,
    );

    final dietController = TextEditingController(
      text: profile.dietRestrictions,
    );

    showDialog(
      context: context,

      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            "Edit Profile",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                _field(ageController, "Age"),
                const SizedBox(height: 12),

                _field(genderController, "Gender"),
                const SizedBox(height: 12),

                _field(weightController, "Weight"),
                const SizedBox(height: 12),

                _field(heightController, "Height"),
                const SizedBox(height: 12),

                _field(hba1cController, "HbA1c"),
                const SizedBox(height: 12),

                _field(activityController, "Activity Level"),
                const SizedBox(height: 12),

                _field(dietController, "Diet Restrictions"),
              ],
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F5132),
              ),

              onPressed: () async {
                final updatedProfile = ProfileModel(
                  userId: profile.userId,

                  age: int.tryParse(ageController.text) ?? 0,

                  gender: genderController.text,

                  weight: double.tryParse(weightController.text) ?? 0,

                  height: double.tryParse(heightController.text) ?? 0,

                  hba1c: double.tryParse(hba1cController.text) ?? 0,

                  activityLevel: activityController.text,

                  dietRestrictions: dietController.text,

                  breakfastTime: profile.breakfastTime!.isEmpty
                      ? null
                      : profile.breakfastTime,
                  lunchTime: profile.lunchTime!.isEmpty
                      ? null
                      : profile.lunchTime,
                  dinnerTime: profile.dinnerTime!.isEmpty
                      ? null
                      : profile.dinnerTime,
                );

                try {
                  await ProfileRepository().updateProfile(updatedProfile);

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Profile updated successfully"),
                    ),
                  );

                  context.read<ProfileBloc>().add(FetchProfileEvent());
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },

              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LogoutBloc(repository: LogoutRepository())),

        BlocProvider(
          create: (_) =>
              ProfileBloc(repository: ProfileRepository())
                ..add(FetchProfileEvent()),
        ),
      ],

      child: MultiBlocListener(
        listeners: [
          BlocListener<LogoutBloc, LogoutState>(
            listener: (context, state) {
              if (state is LogoutSuccess) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }

              if (state is LogoutFailure) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
          ),
        ],

        child: Scaffold(
          backgroundColor: const Color(0xFFFAFAFA),

          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,

            leading: const Padding(
              padding: EdgeInsets.all(10.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFE6F4EA),
                child: Icon(
                  Icons.person_outline,
                  color: Color(0xFF0F5132),
                  size: 18,
                ),
              ),
            ),

            title: const Text(
              'My Profile',
              style: TextStyle(
                color: Color(0xFF0F5132),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_none,
                  color: Color(0xFF0F5132),
                  size: 24,
                ),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],

            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFE5E7EB), height: 1),
            ),
          ),

          body: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileLoading) {
                return Shimmer.list();
              }

              if (state is ProfileFailure) {
                return Center(child: Text(state.message));
              }

              if (state is ProfileLoaded) {
                final profile = state.profile;

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<ProfileBloc>().add(FetchProfileEvent());

                    // helps show loader visibly
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        const SizedBox(height: 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1.2,
                            ),
                          ),

                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFC9A07E),
                                    width: 2,
                                  ),
                                ),

                                child: const CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Color(0xFFF3F4F6),
                                  child: Icon(
                                    Icons.person,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
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
                                            profile.userId,
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                        ),

                                        GestureDetector(
                                          onTap: () {
                                            _showEditProfileDialog(
                                              context,
                                              profile,
                                            );
                                          },

                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),

                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE6F4EA),

                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),

                                            child: const Row(
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color: Color(0xFF0F5132),
                                                ),

                                                SizedBox(width: 4),

                                                Text(
                                                  "Edit",
                                                  style: TextStyle(
                                                    color: Color(0xFF0F5132),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.assignment_ind_outlined,
                                          size: 14,
                                          color: Color(0xFF6B7280),
                                        ),

                                        const SizedBox(width: 4),

                                        Text(
                                          'Gender: ${profile.gender}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Expanded(
                              //   child: Column(
                              //     crossAxisAlignment:
                              //     CrossAxisAlignment.start,
                              //
                              //     children: [
                              //       Text(
                              //         profile.userId,
                              //         style: const TextStyle(
                              //           fontSize: 20,
                              //           fontWeight: FontWeight.bold,
                              //           color: Color(0xFF111827),
                              //         ),
                              //       ),
                              //
                              //       const SizedBox(height: 4),
                              //
                              //       Row(
                              //         children: [
                              //           const Icon(
                              //             Icons.assignment_ind_outlined,
                              //             size: 14,
                              //             color: Color(0xFF6B7280),
                              //           ),
                              //
                              //           const SizedBox(width: 4),
                              //
                              //           Text(
                              //             'Gender: ${profile.gender}',
                              //             style: TextStyle(
                              //               fontSize: 13,
                              //               color: Colors.grey[600],
                              //             ),
                              //           ),
                              //         ],
                              //       ),
                              //     ],
                              //   ),
                              // ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// HEALTH DETAILS
                        Container(
                          width: double.infinity,

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1.2,
                            ),
                          ),

                          child: Column(
                            children: [
                              _buildMetricRow(
                                'Age',
                                Text(
                                  '${profile.age}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              _buildDivider(),

                              _buildMetricRow(
                                'Weight',
                                Text(
                                  '${profile.weight} kg',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              _buildDivider(),

                              _buildMetricRow(
                                'Height',
                                Text(
                                  '${profile.height} cm',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              _buildDivider(),

                              _buildMetricRow(
                                'HbA1c',
                                Text(
                                  '${profile.hba1c}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              _buildDivider(),

                              _buildMetricRow(
                                'Activity Level',
                                Text(
                                  profile.activityLevel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              _buildDivider(),

                              _buildMetricRow(
                                'Diet Restrictions',
                                Text(
                                  profile.dietRestrictions,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        const SizedBox(height: 32),

                        /// LOGOUT BUTTON
                        BlocBuilder<LogoutBloc, LogoutState>(
                          builder: (context, state) {
                            final isLoading = state is LogoutLoading;

                            return GestureDetector(
                              onTap: isLoading
                                  ? null
                                  : () {
                                      context.read<LogoutBloc>().add(
                                        LogoutRequested(),
                                      );
                                    },

                              child: Container(
                                width: double.infinity,

                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),

                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFFCA5A5),
                                    width: 1,
                                  ),
                                ),

                                child: Center(
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFDC2626),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.logout_outlined,
                                              color: Color(0xFFDC2626),
                                              size: 18,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Sign out',
                                              style: TextStyle(
                                                color: Color(0xFFDC2626),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMetricRow(String title, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),

          valueWidget,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFE5E7EB),
      height: 1,
    );
  }

  Widget _timeTile(String title, String time, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),

      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE6F4EA),

            child: Icon(icon, color: const Color(0xFF0F5132)),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          Text(
            time,
            style: const TextStyle(
              color: Color(0xFF0F5132),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
