import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'career_record.dart';
import 'career_form_screen.dart';
import 'career_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const CareerPathExplorer());
}

const purple = Color(0xFF6D5CE8);
const navy = Color(0xFF172554);

class CareerPathExplorer extends StatelessWidget {
  const CareerPathExplorer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Career Path Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: purple),
        scaffoldBackgroundColor: const Color(0xFFF5F6FF),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text('Unable to connect to your account.')),
          );
        }
        return snapshot.data == null ? const LoginScreen() : const HomeScreen();
      },
    );
  }
}

// ---------------- LOGIN AND REGISTRATION ----------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool registering = true;
  bool loading = false;
  String error = '';

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final auth = FirebaseAuth.instance;

      if (registering) {
        final credential = await auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        error = switch (e.code) {
          'email-already-in-use' => 'This email is already registered.',
          'invalid-email' => 'Please enter a valid email.',
          'weak-password' => 'Password must contain at least 6 characters.',
          'invalid-credential' => 'Incorrect email or password.',
          'operation-not-allowed' =>
            'Enable Email/Password in Firebase Authentication.',
          _ => 'Authentication failed: ${e.code}',
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Could not complete the request. Check Firebase setup.';
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.explore, size: 65, color: purple),
                      const SizedBox(height: 12),
                      const Text(
                        'Career Path Explorer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Discover a career that matches your interests.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      if (registering) ...[
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null ||
                              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.length < 6
                            ? 'Use at least 6 characters'
                            : null,
                      ),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          error,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: loading ? null : submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: purple,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Text(
                          loading
                              ? 'Please wait...'
                              : registering
                                  ? 'Create Account'
                                  : 'Log In',
                        ),
                      ),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () => setState(() {
                                  registering = !registering;
                                  error = '';
                                }),
                        child: Text(
                          registering
                              ? 'Already registered? Log in'
                              : 'New user? Create an account',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- CAREER INFORMATION ----------------

class Career {
  final String title;
  final String field;
  final String description;
  final String skills;
  final String education;
  final IconData icon;

  const Career(
    this.title,
    this.field,
    this.description,
    this.skills,
    this.education,
    this.icon,
  );
}

const careers = <Career>[
  Career(
    'Software Developer',
    'Technology',
    'Build websites, mobile applications and software systems.',
    'Programming, logical thinking, problem-solving, teamwork.',
    'Software Engineering, Computer Science or a related course.',
    Icons.code,
  ),
  Career(
    'Data Analyst',
    'Technology and Business',
    'Analyse information to help organisations make decisions.',
    'Excel, SQL, statistics and communication.',
    'Data Science, Statistics, IT or a related course.',
    Icons.analytics,
  ),
  Career(
    'Cybersecurity Analyst',
    'Technology',
    'Help protect computer systems, networks and data.',
    'Networking, security, investigation and attention to detail.',
    'Cybersecurity, IT or Computer Science.',
    Icons.security,
  ),
  Career(
    'UI/UX Designer',
    'Design and Technology',
    'Design digital products that are easy and enjoyable to use.',
    'Creativity, user research, prototyping and communication.',
    'Design, Human-Computer Interaction or a related course.',
    Icons.design_services,
  ),
  Career(
    'Project Manager',
    'Business',
    'Plan tasks, coordinate teams and help projects meet their goals.',
    'Leadership, planning, organisation and communication.',
    'Project Management, Business or a related course.',
    Icons.assignment,
  ),
  Career(
    'Accountant',
    'Finance',
    'Prepare financial records, budgets and reports.',
    'Numeracy, accuracy, ethics and spreadsheet skills.',
    'Accounting or Finance.',
    Icons.calculate,
  ),
  Career(
    'Teacher',
    'Education',
    'Help students learn knowledge and develop useful skills.',
    'Communication, patience, planning and subject knowledge.',
    'A relevant teaching qualification.',
    Icons.school,
  ),
  Career(
    'Nurse',
    'Healthcare',
    'Provide patient care and work with healthcare professionals.',
    'Empathy, teamwork, communication and attention to detail.',
    'A recognised nursing qualification and registration.',
    Icons.health_and_safety,
  ),
  Career(
    'Entrepreneur',
    'Business',
    'Create a business that solves problems for customers.',
    'Creativity, budgeting, initiative and resilience.',
    'Business knowledge can help; requirements vary by business.',
    Icons.lightbulb,
  ),
];

// ---------------- HOME AND CAREER EXPLORER ----------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  String search = '';
  final Set<String> saved = {};

  User get user => FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    final pages = [
      dashboard(),
      explorer(),
      const QuizScreen(),
      profile(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Career Path Explorer',
          style: TextStyle(color: navy, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (index) => setState(() => tab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            label: 'Career Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget dashboard() {
    final name = user.displayName ?? '';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [navy, purple],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? 'Welcome!' : 'Welcome, $name!',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              const Text(
                'Your future starts here.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Discover careers, explore skills and find your next step.',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => setState(() => tab = 2),
                child: const Text('Find My Career Direction'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Popular career paths',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 12),
        ...careers.take(4).map(careerTile),
      ],
    );
  }

  Widget explorer() {
    final filtered = careers.where((career) {
      final text =
          '${career.title} ${career.field} ${career.skills}'.toLowerCase();
      return text.contains(search.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (value) => setState(() => search = value),
            decoration: const InputDecoration(
              hintText: 'Search careers, fields or skills',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Text('${filtered.length} careers found'),
              const SizedBox(height: 8),
              ...filtered.map(careerTile),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No matching careers found.'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget careerTile(Career career) {
    final isSaved = saved.contains(career.title);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFECE9FF),
          child: Icon(career.icon, color: purple),
        ),
        title: Text(
          career.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        subtitle: Text(career.field),
        trailing: IconButton(
          tooltip: isSaved ? 'Unsave career' : 'Save career',
          icon: Icon(
            isSaved ? Icons.bookmark : Icons.bookmark_border,
            color: purple,
          ),
          onPressed: () {
            setState(() {
              if (isSaved) {
                saved.remove(career.title);
              } else {
                saved.add(career.title);
              }
            });
          },
        ),
        onTap: () => showModalBottomSheet(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(career.icon, color: purple, size: 45),
                const SizedBox(height: 12),
                Text(
                  career.title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: navy,
                  ),
                ),
                Text(career.field),
                const SizedBox(height: 16),
                const Text(
                  'Career description',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(career.description),
                const SizedBox(height: 16),
                const Text(
                  'Important skills',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(career.skills),
                const SizedBox(height: 16),
                const Text(
                  'Education',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(career.education),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => saved.add(career.title));
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('Save Career'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget profile() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CircleAvatar(
          radius: 42,
          backgroundColor: Color(0xFFECE9FF),
          child: Icon(Icons.person, size: 45, color: purple),
        ),
        const SizedBox(height: 16),
        const Text(
          'My Profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 20),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.email, color: purple),
            title: const Text('Email address'),
            subtitle: Text(user.email ?? 'Not available'),
          ),
        ),
        Card(
          color: Colors.white,
          child: ListTile(
            leading: const Icon(Icons.bookmark, color: purple),
            title: const Text('Saved careers'),
            subtitle: Text('${saved.length} careers saved this session'),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'My recent quiz results',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('assessments')
              .orderBy('createdAt', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('Could not load quiz results.');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final results = snapshot.data!.docs;
            if (results.isEmpty) {
              return const Text(
                  'Complete the career quiz to see your results.');
            }
            return Column(
              children: results.map((doc) {
                final data = doc.data();
                return Card(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(Icons.auto_awesome, color: purple),
                    title: Text(
                      data['recommendedField'] ?? 'Career recommendation',
                    ),
                    subtitle: Text(
                      'Interest: ${data['interest'] ?? 'Not specified'}',
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => FirebaseAuth.instance.signOut(),
          icon: const Icon(Icons.logout),
          label: const Text('Log Out'),
        ),
      ],
    );
  }
}

// ---------------- CAREER INTEREST QUIZ ----------------

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String? interest;
  String? strength;
  String? environment;
  String result = '';
  String message = '';
  bool saving = false;

  final interests = const [
    'Building apps and solving technical problems',
    'Analysing data and finding patterns',
    'Helping, teaching or caring for people',
    'Designing creative digital experiences',
    'Organising teams, projects or businesses',
  ];

  final strengths = const [
    'Logical thinking and problem-solving',
    'Creativity and visual communication',
    'Communication and listening',
    'Planning and organisation',
    'Research and attention to detail',
  ];

  final environments = const [
    'Technology or computer workspace',
    'School, hospital or community',
    'Office or business environment',
    'Creative studio',
    'A mix of different environments',
  ];

  String recommendation() {
    if (interest == interests[0]) return 'Technology careers';
    if (interest == interests[1]) return 'Data and analytical careers';
    if (interest == interests[2]) return 'People-focused careers';
    if (interest == interests[3]) return 'Design and creative careers';
    if (interest == interests[4]) return 'Business and management careers';
    return 'Explore different career fields';
  }

  Future<void> finishQuiz() async {
    if (interest == null || strength == null || environment == null) {
      setState(() => message = 'Please answer all three questions.');
      return;
    }

    setState(() {
      saving = true;
      message = '';
    });

    final careerResult = recommendation();

    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('assessments')
          .add({
        'interest': interest,
        'strength': strength,
        'environment': environment,
        'recommendedField': careerResult,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      setState(() {
        result = careerResult;
        message = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        result = careerResult;
        message = 'Result shown, but saving failed. Check Firebase rules.';
      });
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget question(
    String title,
    List<String> options,
    String? selected,
    ValueChanged<String?> onChanged,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: navy,
              ),
            ),
            ...options.map(
              (option) => RadioListTile<String>(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(option),
                value: option,
                groupValue: selected,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (result.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.auto_awesome, size: 65, color: purple),
          const SizedBox(height: 16),
          const Text(
            'Your career direction',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, color: navy),
          ),
          const SizedBox(height: 14),
          Text(
            result,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: purple,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This is a starting suggestion based on your interests, not a final career decision. Explore the related careers, skills and education requirements.',
            textAlign: TextAlign.center,
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() {
              interest = null;
              strength = null;
              environment = null;
              result = '';
              message = '';
            }),
            child: const Text('Take the Quiz Again'),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text(
          'Career Interest Quiz',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose the answers that best describe you.',
        ),
        const SizedBox(height: 18),
        question(
          '1. What do you enjoy most?',
          interests,
          interest,
          (v) => setState(() => interest = v),
        ),
        question(
          '2. What is your strongest skill?',
          strengths,
          strength,
          (v) => setState(() => strength = v),
        ),
        question(
          '3. Where would you prefer to work?',
          environments,
          environment,
          (v) => setState(() => environment = v),
        ),
        if (message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        FilledButton.icon(
          onPressed: saving ? null : finishQuiz,
          icon: const Icon(Icons.auto_awesome),
          label: Text(saving ? 'Saving...' : 'Find My Career Direction'),
          style: FilledButton.styleFrom(
            backgroundColor: purple,
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}
