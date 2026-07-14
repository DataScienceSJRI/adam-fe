import 'package:adam/bloc/auth/logout_bloc.dart';
import 'package:adam/bloc/profile/profile_bloc.dart';
import 'package:adam/data/models/profile_model.dart';
import 'package:adam/data/repositories/logout_repository.dart';
import 'package:adam/data/repositories/profile_repository.dart';
import 'package:adam/ui/screens/login/login_screen.dart';
import 'package:adam/ui/screens/weight_log/weight_log_screen.dart';
import 'package:adam/ui/utils/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Widget _modernField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,

        prefixIcon: Icon(icon, color: const Color(0xFF008C5E)),

        filled: true,
        fillColor: const Color(0xFFF8FAF9),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF008C5E), width: 1.5),
        ),
      ),
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
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

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
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              WeightLogScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF008C5E),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.monitor_weight_outlined,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Log Weight",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        const SizedBox(height: 32),
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
