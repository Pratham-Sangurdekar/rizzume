import 'package:flutter/material.dart';
import '../../models/job_offer.dart';
import '../../services/firebase_jobs_service.dart';
import 'matches_tab.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final FirebaseJobsService _jobsService = FirebaseJobsService();
  late TabController _historyTabController;

  @override
  bool get wantKeepAlive => true; // Keep state alive when switching tabs

  @override
  void initState() {
    super.initState();
    _historyTabController = TabController(length: 2, vsync: this);
    // Load job stack on init (no need to seed dummy jobs anymore)
    _jobsService.loadJobStack(forceRefresh: true);
  }

  @override
  void dispose() {
    _historyTabController.dispose();
    super.dispose();
  }

  void _showJobsHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _JobsHistoryModal(
        jobsService: _jobsService,
        tabController: _historyTabController,
      ),
    );
  }

  void _showApplications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Applications',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Applications list
              Expanded(
                child: const MatchesTab(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return SafeArea(
      child: Column(
        children: [
          // Header with folder button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Job Offers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.work_history, color: Colors.white, size: 28),
                      onPressed: _showApplications,
                      tooltip: 'My Applications',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.folder_open, color: Colors.white, size: 28),
                      onPressed: _showJobsHistory,
                      tooltip: 'View History',
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<JobOffer>>(
              stream: _jobsService.getAvailableJobs(),
              builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final offers = snapshot.data ?? [];
              
              // Debug: Print the job count and titles
              print('📊 Jobs loaded: ${offers.length}');
              for (var i = 0; i < offers.length && i < 10; i++) {
                print('  Job $i: ${offers[i].title} (ID: ${offers[i].id})');
              }
              
              if (offers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.work_off, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No more job offers',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check back later for new opportunities!',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              // Show up to 3 cards in stack for better UX (only show 2-3 at a time)
              final visibleCount = offers.length > 3 ? 3 : offers.length;
              
              // Random tilts for visual interest (but top card is straight)
              final cardRotations = [0.0, -0.03, 0.02]; // Top card = 0.0 (straight), others slightly tilted
              
              print('🃏 Displaying $visibleCount cards from ${offers.length} total offers');
              
              // Get screen width for centering
              final screenWidth = MediaQuery.of(context).size.width;
              final cardWidth = screenWidth * 0.9; // Card takes 90% of screen width
              
              return Stack(
                alignment: Alignment.center,
                children: List.generate(visibleCount, (i) {
                  // In Flutter Stack, later children are painted on top
                  // We want offers[0] to be the top swipeable card (last rendered)
                  // So we generate from last to first: offers[2], offers[1], offers[0]
                  final cardIndex = visibleCount - 1 - i; // i=0 -> offers[2], i=2 -> offers[0]
                  final offer = offers[cardIndex];
                  final isTop = cardIndex == 0; // offers[0] is the top card
                  
                  // All cards same size (scale = 1.0), top card is straight (0.0), others with random tilts
                  final rotation = cardIndex < cardRotations.length ? cardRotations[cardIndex] : 0.0;
                  
                  // Slight offset for depth perception (only a few pixels)
                  final offsetY = (visibleCount - 1 - cardIndex) * 4.0; // Minimal vertical offset
                  final offsetX = (visibleCount - 1 - cardIndex) * 2.0; // Slight horizontal shift

                  print('  Card $i: ${offer.title} (cardIndex=$cardIndex, isTop=$isTop, rotation=${rotation.toStringAsFixed(2)}, offset=($offsetX,$offsetY))');

                  return Positioned(
                    top: 20.0 + offsetY,
                    left: (screenWidth - cardWidth) / 2 + offsetX, // Center the card horizontally
                    child: Transform.rotate(
                      angle: rotation,
                      child: isTop
                          ? Dismissible(
                              key: ValueKey(offer.id),
                              direction: DismissDirection.horizontal,
                              onDismissed: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  await _jobsService.swipeRight(offer.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Applied to ${offer.title}!'),
                                        backgroundColor: Colors.green,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                } else if (direction == DismissDirection.endToStart) {
                                  await _jobsService.swipeLeft(offer.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Passed on ${offer.title}'),
                                        backgroundColor: Colors.red.withValues(alpha: 0.8),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                }
                              },
                              background: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 40),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.favorite, color: Colors.green, size: 48),
                                        const SizedBox(height: 8),
                                        Text('APPLY', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              secondaryBackground: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 40),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.close, color: Colors.red, size: 48),
                                        const SizedBox(height: 8),
                                        Text('PASS', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              child: _buildCard(offer, isTop),
                            )
                          : IgnorePointer(child: _buildCard(offer, isTop)),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildCard(JobOffer offer, bool isTop) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Stack(
              children: [
                Image.network(
                  offer.imageUrl,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    height: 240,
                    color: Colors.grey[300],
                    child: const Icon(Icons.work, size: 80, color: Colors.grey),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      offer.type,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),

            // Content section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and company
                    Text(
                      offer.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.business, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            offer.company,
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Location and salary
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  offer.location,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                            Text(
                              offer.salary,
                              style: TextStyle(fontSize: 14, color: Colors.green[700], fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: offer.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFF6C63FF).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6C63FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Description
                    Text(
                      'About the role',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offer.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                    ),

                    const SizedBox(height: 20),

                    // Requirements
                    Text(
                      'Requirements',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 8),
                    ...offer.requirements.map((req) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle, size: 16, color: Color(0xFF6C63FF)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  req,
                                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Jobs History Modal
class _JobsHistoryModal extends StatefulWidget {
  final FirebaseJobsService jobsService;
  final TabController tabController;

  const _JobsHistoryModal({
    required this.jobsService,
    required this.tabController,
  });

  @override
  State<_JobsHistoryModal> createState() => _JobsHistoryModalState();
}

class _JobsHistoryModalState extends State<_JobsHistoryModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Job History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: widget.tabController,
            indicatorColor: const Color(0xFF6C63FF),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
            tabs: const [
              Tab(text: 'Applied', icon: Icon(Icons.favorite)),
              Tab(text: 'Passed', icon: Icon(Icons.close)),
            ],
          ),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: widget.tabController,
              children: [
                _buildAppliedTab(),
                _buildRejectedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppliedTab() {
    return StreamBuilder<List<JobOffer>>(
      stream: widget.jobsService.getAppliedJobs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.work_outline, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'No applications yet',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return _buildJobHistoryCard(job, true);
          },
        );
      },
    );
  }

  Widget _buildRejectedTab() {
    return StreamBuilder<List<JobOffer>>(
      stream: widget.jobsService.getRejectedJobs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final jobs = snapshot.data ?? [];
        if (jobs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 80, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  'No passed jobs',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];
            return _buildJobHistoryCard(job, false);
          },
        );
      },
    );
  }

  Widget _buildJobHistoryCard(JobOffer job, bool isApplied) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isApplied ? Colors.green : Colors.red).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                job.imageUrl,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  width: 70,
                  height: 70,
                  color: Colors.grey,
                  child: const Icon(Icons.work, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Job info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.company,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          job.location,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isApplied ? Colors.green : Colors.red).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isApplied ? Icons.check : Icons.close,
                color: isApplied ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
