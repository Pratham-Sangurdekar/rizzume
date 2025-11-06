import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_offer.dart';
import 'dart:async';
import 'dart:math';

class FirebaseJobsService {
  static final FirebaseJobsService _instance = FirebaseJobsService._internal();
  factory FirebaseJobsService() => _instance;
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Local stack management for smooth swiping
  final List<JobOffer> _jobStack = [];
  late final StreamController<List<JobOffer>> _stackController;
  bool _isLoadingJobs = false;

  FirebaseJobsService._internal() {
    // Initialize stream controller with initial empty state
    _stackController = StreamController<List<JobOffer>>.broadcast()
      ..add([]); // Seed with empty list so StreamBuilder doesn't show loading forever
  }

  Stream<List<JobOffer>> get jobStackStream => _stackController.stream;

  // Get current job stack
  List<JobOffer> get currentStack => List.unmodifiable(_jobStack);

  // Initialize or refresh the job stack with 9 randomized jobs
  Future<void> loadJobStack({bool forceRefresh = false}) async {
    if (_isLoadingJobs) return;
    if (!forceRefresh && _jobStack.length >= 3) return; // Still have cards, don't reload

    _isLoadingJobs = true;
    
    // Emit loading state
    if (_jobStack.isEmpty) {
      _stackController.add([]);
    }

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        _stackController.add([]);
        return;
      }

      // Get user's swipe history
      final userSwipesDoc = await _db.collection('userJobSwipes').doc(userId).get();
      final swipedJobIds = Set<String>.from(userSwipesDoc.data()?['swipedJobs'] ?? []);

      // Fetch all available jobs (up to 50)
      // Note: Not ordering by postedDate to support jobs from website that may not have this field
      final jobsSnapshot = await _db
          .collection('jobs')
          .limit(50)
          .get();

      print('🔍 Fetched ${jobsSnapshot.docs.length} jobs from Firestore');

      // Filter out swiped jobs and parse all jobs
      final availableJobs = jobsSnapshot.docs
          .where((doc) => !swipedJobIds.contains(doc.id))
          .map((doc) => JobOffer.fromFirestore(doc.data(), doc.id))
          .toList();

      // Sort by postedDate (most recent first) - jobs without valid dates will still be included
      availableJobs.sort((a, b) => b.postedDate.compareTo(a.postedDate));

      print('✅ ${availableJobs.length} jobs available after filtering (${swipedJobIds.length} already swiped)');

      if (availableJobs.isEmpty) {
        _jobStack.clear();
        _stackController.add([]);
        return;
      }

      // Randomize the jobs
      availableJobs.shuffle(Random());

      // Take up to 9 jobs for the stack
      final jobsToAdd = availableJobs.take(9).toList();

      print('🎲 Loading ${jobsToAdd.length} randomized jobs into stack');
      for (var i = 0; i < jobsToAdd.length; i++) {
        print('  Stack [$i]: ${jobsToAdd[i].title}');
      }

      // Clear old stack and add new jobs
      _jobStack.clear();
      _jobStack.addAll(jobsToAdd);

      // Emit the new stack
      _stackController.add(List.unmodifiable(_jobStack));
    } catch (e) {
      print('Error loading job stack: $e');
      _stackController.add([]);
    } finally {
      _isLoadingJobs = false;
    }
  }

  // Remove a job from the stack (called after swipe)
  void _removeFromStack(String jobId) {
    _jobStack.removeWhere((job) => job.id == jobId);
    _stackController.add(List.unmodifiable(_jobStack));

    // Auto-reload if stack is running low
    if (_jobStack.length < 3) {
      loadJobStack();
    }
  }

  // Get available job offers (uses stack system)
  Stream<List<JobOffer>> getAvailableJobs() {
    // Load initial stack if empty
    if (_jobStack.isEmpty && !_isLoadingJobs) {
      loadJobStack();
    }
    
    // Return the stream controller's stream
    return _stackController.stream;
  }

  // Get user's applied jobs (right swipes)
  Stream<List<JobOffer>> getAppliedJobs() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('userJobSwipes')
        .doc(userId)
        .collection('applied')
        .orderBy('swipedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<JobOffer> jobs = [];
      for (var doc in snapshot.docs) {
        final jobId = doc.data()['jobId'];
        final jobDoc = await _db.collection('jobs').doc(jobId).get();
        if (jobDoc.exists) {
          jobs.add(JobOffer.fromFirestore(jobDoc.data()!, jobDoc.id));
        }
      }
      return jobs;
    });
  }

  // Get user's rejected jobs (left swipes)
  Stream<List<JobOffer>> getRejectedJobs() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('userJobSwipes')
        .doc(userId)
        .collection('rejected')
        .orderBy('swipedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<JobOffer> jobs = [];
      for (var doc in snapshot.docs) {
        final jobId = doc.data()['jobId'];
        final jobDoc = await _db.collection('jobs').doc(jobId).get();
        if (jobDoc.exists) {
          jobs.add(JobOffer.fromFirestore(jobDoc.data()!, jobDoc.id));
        }
      }
      return jobs;
    });
  }

  // Swipe right (apply/like)
  Future<void> swipeRight(String jobId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final batch = _db.batch();

    // Add to applied subcollection
    batch.set(
      _db.collection('userJobSwipes').doc(userId).collection('applied').doc(jobId),
      {'jobId': jobId, 'swipedAt': FieldValue.serverTimestamp()},
    );

    // Update main swipe tracking
    batch.set(
      _db.collection('userJobSwipes').doc(userId),
      {
        'swipedJobs': FieldValue.arrayUnion([jobId]),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // Remove from local stack immediately for instant UI update
    _removeFromStack(jobId);
  }

  // Swipe left (reject/pass)
  Future<void> swipeLeft(String jobId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final batch = _db.batch();

    // Add to rejected subcollection
    batch.set(
      _db.collection('userJobSwipes').doc(userId).collection('rejected').doc(jobId),
      {'jobId': jobId, 'swipedAt': FieldValue.serverTimestamp()},
    );

    // Update main swipe tracking
    batch.set(
      _db.collection('userJobSwipes').doc(userId),
      {
        'swipedJobs': FieldValue.arrayUnion([jobId]),
      },
      SetOptions(merge: true),
    );

    await batch.commit();

    // Remove from local stack immediately for instant UI update
    _removeFromStack(jobId);
  }

  // Restore from rejected (undo)
  Future<void> restoreFromRejected(String jobId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final batch = _db.batch();

    // Remove from rejected subcollection
    batch.delete(_db.collection('userJobSwipes').doc(userId).collection('rejected').doc(jobId));

    // Remove from main swipe tracking
    batch.update(
      _db.collection('userJobSwipes').doc(userId),
      {
        'swipedJobs': FieldValue.arrayRemove([jobId]),
      },
    );

    await batch.commit();
  }

  // Clear all swipe history for current user (for testing/reset)
  Future<void> clearSwipeHistory() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    print('🧹 Clearing swipe history for user');

    final batch = _db.batch();

    // Get all applied jobs
    final appliedDocs = await _db
        .collection('userJobSwipes')
        .doc(userId)
        .collection('applied')
        .get();
    
    for (var doc in appliedDocs.docs) {
      batch.delete(doc.reference);
    }

    // Get all rejected jobs
    final rejectedDocs = await _db
        .collection('userJobSwipes')
        .doc(userId)
        .collection('rejected')
        .get();
    
    for (var doc in rejectedDocs.docs) {
      batch.delete(doc.reference);
    }

    // Clear the main swipedJobs array
    batch.set(
      _db.collection('userJobSwipes').doc(userId),
      {'swipedJobs': [], 'lastUpdated': FieldValue.serverTimestamp()},
    );

    await batch.commit();
    
    print('✅ Swipe history cleared');
    
    // Reload the job stack with fresh jobs
    await loadJobStack(forceRefresh: true);
  }

  // Seed dummy job data (call this once to populate Firebase)
  // Only seeds if the jobs collection is empty to avoid overwriting real jobs
  Future<void> seedDummyJobs() async {
    // Check if jobs already exist
    final existingJobsCheck = await _db.collection('jobs').limit(1).get();
    if (existingJobsCheck.docs.isNotEmpty) {
      print('ℹ️ Jobs already exist in Firestore, skipping seeding');
      return;
    }

    print('🌱 Seeding dummy jobs...');
    final List<Map<String, dynamic>> dummyJobs = [
      {
        'title': 'Senior Flutter Developer',
        'company': 'TechCorp Inc.',
        'description': 'We are looking for an experienced Flutter developer to join our mobile team. You will be responsible for developing high-quality mobile applications and collaborating with cross-functional teams.',
        'imageUrl': 'https://images.unsplash.com/photo-1551434678-e076c223a692?w=800',
        'location': 'San Francisco, CA',
        'salary': '\$120k - \$180k',
        'type': 'Full-time',
        'requirements': ['5+ years Flutter experience', 'Strong Dart knowledge', 'REST API integration', 'Git proficiency'],
        'tags': ['Flutter', 'Dart', 'Mobile', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(days: 2)),
      },
      {
        'title': 'UI/UX Designer',
        'company': 'Creative Studios',
        'description': 'Join our design team to create beautiful and intuitive user interfaces. You will work on various projects ranging from mobile apps to web platforms.',
        'imageUrl': 'https://images.unsplash.com/photo-1561070791-2526d30994b5?w=800',
        'location': 'New York, NY',
        'salary': '\$90k - \$130k',
        'type': 'Full-time',
        'requirements': ['3+ years UI/UX experience', 'Figma expertise', 'Portfolio required', 'User research skills'],
        'tags': ['Design', 'UI/UX', 'Figma', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(days: 1)),
      },
      {
        'title': 'Frontend Developer',
        'company': 'WebWorks LLC',
        'description': 'Build responsive and dynamic web applications using modern frameworks. Collaborate with backend developers and designers to deliver exceptional user experiences.',
        'imageUrl': 'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800',
        'location': 'Austin, TX',
        'salary': '\$100k - \$150k',
        'type': 'Full-time',
        'requirements': ['React or Vue.js', 'JavaScript/TypeScript', 'CSS/SASS', 'Responsive design'],
        'tags': ['React', 'JavaScript', 'Frontend', 'Hybrid'],
        'postedDate': DateTime.now().subtract(Duration(days: 3)),
      },
      {
        'title': 'Product Manager',
        'company': 'InnovateCo',
        'description': 'Lead product strategy and execution for our flagship mobile application. Work with engineering, design, and business teams to deliver features that delight users.',
        'imageUrl': 'https://images.unsplash.com/photo-1552664730-d307ca884978?w=800',
        'location': 'Seattle, WA',
        'salary': '\$130k - \$190k',
        'type': 'Full-time',
        'requirements': ['5+ years PM experience', 'Agile methodology', 'Data-driven decision making', 'Strong communication'],
        'tags': ['Product', 'Management', 'Agile', 'On-site'],
        'postedDate': DateTime.now().subtract(Duration(hours: 12)),
      },
      {
        'title': 'Data Scientist',
        'company': 'DataMinds AI',
        'description': 'Apply machine learning and statistical analysis to solve complex business problems. Build predictive models and extract insights from large datasets.',
        'imageUrl': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800',
        'location': 'Boston, MA',
        'salary': '\$140k - \$200k',
        'type': 'Full-time',
        'requirements': ['Python expertise', 'ML frameworks (TensorFlow/PyTorch)', 'SQL proficiency', 'Statistics background'],
        'tags': ['Python', 'ML', 'Data Science', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(days: 4)),
      },
      {
        'title': 'DevOps Engineer',
        'company': 'CloudScale Systems',
        'description': 'Manage and optimize our cloud infrastructure. Implement CI/CD pipelines and ensure high availability and security of our services.',
        'imageUrl': 'https://images.unsplash.com/photo-1667372393119-3d4c48d07fc9?w=800',
        'location': 'Denver, CO',
        'salary': '\$110k - \$160k',
        'type': 'Full-time',
        'requirements': ['AWS/Azure/GCP', 'Docker & Kubernetes', 'CI/CD tools', 'Linux administration'],
        'tags': ['DevOps', 'AWS', 'Kubernetes', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(days: 5)),
      },
      {
        'title': 'Mobile App Developer',
        'company': 'AppMakers Studio',
        'description': 'Develop native iOS and Android applications. Work on exciting projects for clients across various industries.',
        'imageUrl': 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c?w=800',
        'location': 'Los Angeles, CA',
        'salary': '\$95k - \$140k',
        'type': 'Contract',
        'requirements': ['Swift or Kotlin', 'Mobile UI best practices', '3+ years experience', 'App Store submissions'],
        'tags': ['iOS', 'Android', 'Mobile', 'Contract'],
        'postedDate': DateTime.now().subtract(Duration(days: 6)),
      },
      {
        'title': 'Backend Engineer',
        'company': 'ServerSide Tech',
        'description': 'Build scalable backend services and APIs. Design database schemas and optimize performance for millions of users.',
        'imageUrl': 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800',
        'location': 'Chicago, IL',
        'salary': '\$115k - \$170k',
        'type': 'Full-time',
        'requirements': ['Node.js or Python', 'Database design', 'RESTful APIs', 'Microservices architecture'],
        'tags': ['Backend', 'Node.js', 'API', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(days: 7)),
      },
      {
        'title': 'Cybersecurity Analyst',
        'company': 'SecureNet Solutions',
        'description': 'Protect our systems and data from cyber threats. Conduct security audits, implement security measures, and respond to incidents.',
        'imageUrl': 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800',
        'location': 'Washington, DC',
        'salary': '\$105k - \$155k',
        'type': 'Full-time',
        'requirements': ['Security certifications', 'Penetration testing', 'Network security', 'Incident response'],
        'tags': ['Security', 'Cybersecurity', 'Network', 'On-site'],
        'postedDate': DateTime.now().subtract(Duration(days: 8)),
      },
      {
        'title': 'Full Stack Developer',
        'company': 'StartupHub',
        'description': 'Join our fast-paced startup and work on all aspects of our platform. Build features end-to-end and have a direct impact on our growth.',
        'imageUrl': 'https://images.unsplash.com/photo-1504639725590-34d0984388bd?w=800',
        'location': 'Remote',
        'salary': '\$100k - \$145k',
        'type': 'Full-time',
        'requirements': ['React & Node.js', 'PostgreSQL or MongoDB', 'AWS deployment', 'Startup experience preferred'],
        'tags': ['Full Stack', 'React', 'Node.js', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(hours: 8)),
      },
      {
        'title': 'QA Engineer',
        'company': 'QualityFirst Inc.',
        'description': 'Ensure the quality of our software products through comprehensive testing. Write automated tests and work closely with developers.',
        'imageUrl': 'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800',
        'location': 'Portland, OR',
        'salary': '\$85k - \$120k',
        'type': 'Full-time',
        'requirements': ['Test automation', 'Selenium or similar tools', 'API testing', 'Agile environment'],
        'tags': ['QA', 'Testing', 'Automation', 'Hybrid'],
        'postedDate': DateTime.now().subtract(Duration(days: 9)),
      },
      {
        'title': 'Machine Learning Engineer',
        'company': 'AI Innovations',
        'description': 'Develop and deploy machine learning models to production. Work on cutting-edge AI projects in computer vision and NLP.',
        'imageUrl': 'https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800',
        'location': 'Palo Alto, CA',
        'salary': '\$150k - \$220k',
        'type': 'Full-time',
        'requirements': ['Deep learning expertise', 'PyTorch or TensorFlow', 'Model deployment', 'Research background'],
        'tags': ['ML', 'AI', 'Deep Learning', 'On-site'],
        'postedDate': DateTime.now().subtract(Duration(days: 10)),
      },
      {
        'title': 'iOS Developer',
        'company': 'Apple Enthusiasts',
        'description': 'Build beautiful iOS applications using SwiftUI. Work on consumer-facing apps with millions of downloads.',
        'imageUrl': 'https://images.unsplash.com/photo-1621839673705-6617adf9e890?w=800',
        'location': 'Miami, FL',
        'salary': '\$105k - \$155k',
        'type': 'Full-time',
        'requirements': ['Swift & SwiftUI', 'iOS SDK', 'App architecture', 'Performance optimization'],
        'tags': ['iOS', 'Swift', 'SwiftUI', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(days: 11)),
      },
      {
        'title': 'Android Developer',
        'company': 'Droid Masters',
        'description': 'Create amazing Android experiences using Kotlin and Jetpack Compose. Join a team of passionate Android developers.',
        'imageUrl': 'https://images.unsplash.com/photo-1607252650355-f7fd0460ccdb?w=800',
        'location': 'Atlanta, GA',
        'salary': '\$100k - \$145k',
        'type': 'Full-time',
        'requirements': ['Kotlin expertise', 'Jetpack Compose', 'MVVM architecture', 'Material Design'],
        'tags': ['Android', 'Kotlin', 'Jetpack', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(days: 12)),
      },
      {
        'title': 'Blockchain Developer',
        'company': 'CryptoBuilders',
        'description': 'Develop decentralized applications and smart contracts. Work on innovative blockchain solutions in DeFi and NFT spaces.',
        'imageUrl': 'https://images.unsplash.com/photo-1639762681485-074b7f938ba0?w=800',
        'location': 'Remote',
        'salary': '\$130k - \$200k',
        'type': 'Contract',
        'requirements': ['Solidity', 'Web3.js or ethers.js', 'Smart contract auditing', 'Blockchain fundamentals'],
        'tags': ['Blockchain', 'Web3', 'Solidity', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(days: 13)),
      },
      {
        'title': 'Game Developer',
        'company': 'GameForge Studios',
        'description': 'Create immersive gaming experiences using Unity or Unreal Engine. Work on AAA titles and indie games.',
        'imageUrl': 'https://images.unsplash.com/photo-1511512578047-dfb367046420?w=800',
        'location': 'Las Vegas, NV',
        'salary': '\$95k - \$140k',
        'type': 'Full-time',
        'requirements': ['Unity or Unreal Engine', 'C# or C++', '3D graphics', 'Game design principles'],
        'tags': ['Gaming', 'Unity', 'C#', 'On-site'],
        'postedDate': DateTime.now().subtract(Duration(days: 14)),
      },
      {
        'title': 'Technical Writer',
        'company': 'DocuTech',
        'description': 'Create clear and comprehensive technical documentation. Write API docs, tutorials, and user guides for developers.',
        'imageUrl': 'https://images.unsplash.com/photo-1455390582262-044cdead277a?w=800',
        'location': 'Minneapolis, MN',
        'salary': '\$75k - \$110k',
        'type': 'Full-time',
        'requirements': ['Technical writing', 'API documentation', 'Markdown/Git', 'Developer audience'],
        'tags': ['Writing', 'Documentation', 'Technical', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(days: 15)),
      },
      {
        'title': 'Cloud Architect',
        'company': 'SkyHigh Solutions',
        'description': 'Design and implement cloud infrastructure at scale. Lead cloud migration projects and optimize costs.',
        'imageUrl': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800',
        'location': 'Dallas, TX',
        'salary': '\$145k - \$210k',
        'type': 'Full-time',
        'requirements': ['Cloud certifications', 'Multi-cloud experience', 'Terraform/CloudFormation', 'Architecture patterns'],
        'tags': ['Cloud', 'AWS', 'Architecture', 'Hybrid'],
        'postedDate': DateTime.now().subtract(Duration(days: 16)),
      },
      {
        'title': 'React Native Developer',
        'company': 'CrossPlatform Co.',
        'description': 'Build cross-platform mobile apps with React Native. Create reusable components and optimize performance.',
        'imageUrl': 'https://images.unsplash.com/photo-1555066931-4365d14bab8c?w=800',
        'location': 'Phoenix, AZ',
        'salary': '\$100k - \$150k',
        'type': 'Full-time',
        'requirements': ['React Native', 'JavaScript/TypeScript', 'Native modules', 'Redux or MobX'],
        'tags': ['React Native', 'Mobile', 'JavaScript', 'Remote'],
        'postedDate': DateTime.now().subtract(Duration(days: 17)),
      },
      {
        'title': 'Sales Engineer',
        'company': 'TechSales Pro',
        'description': 'Bridge the gap between sales and engineering. Conduct product demos and provide technical expertise to clients.',
        'imageUrl': 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800',
        'location': 'Houston, TX',
        'salary': '\$110k - \$170k + Commission',
        'type': 'Full-time',
        'requirements': ['Technical background', 'Sales experience', 'Demo skills', 'Customer-facing'],
        'tags': ['Sales', 'Technical', 'Demos', 'Hybrid'],
        'postedDate': DateTime.now().subtract(Duration(days: 18)),
      },
    ];

    // Seed new jobs without clearing existing data or swipe history
    final batch = _db.batch();
    for (var job in dummyJobs) {
      final docRef = _db.collection('jobs').doc();
      batch.set(docRef, job);
    }
    await batch.commit();
    print('✅ Seeded ${dummyJobs.length} dummy jobs to Firebase!');
  }
}
