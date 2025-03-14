import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/root_layout.dart';
import 'screens/videos_screen.dart';
import 'screens/create_screen.dart';
import 'screens/video_result_screen.dart';
import 'screens/avatars_screen.dart';
import 'screens/avatar_customization_screen.dart';
import 'screens/models_screen.dart';
import 'screens/scenes_screen.dart';
import 'screens/create_scene_screen.dart';
import 'screens/personas_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/avatar_provider.dart';
import 'providers/persona_provider.dart';
import 'models/avatar.dart';
import 'providers/scene_provider.dart';
import 'models/persona.dart';
import 'providers/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AvatarProvider()),
        ChangeNotifierProvider(create: (_) => PersonaProvider()),
        ChangeNotifierProvider(create: (_) => SceneProvider()),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          final authProvider = Provider.of<AuthProvider>(context);
          
          final router = GoRouter(
            refreshListenable: authProvider,
            redirect: (context, state) {
              final isAuthenticated = authProvider.isAuthenticated;
              final isLoginRoute = state.uri.path == '/login';
              final isRegisterRoute = state.uri.path == '/register';
              
              if (!isAuthenticated && !isLoginRoute && !isRegisterRoute) {
                return '/login';
              }
              
              if (isAuthenticated && (isLoginRoute || isRegisterRoute)) {
                return '/home';
              }
              
              return null;
            },
            routes: [
              GoRoute(
                path: '/login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(
                path: '/register',
                builder: (context, state) => const RegisterScreen(),
              ),
              GoRoute(
                path: '/home',
                builder: (context, state) => const RootLayout(
                  selectedIndex: 0,
                  child: HomeScreen(),
                ),
              ),
              GoRoute(
                path: '/videos',
                builder: (context, state) => const RootLayout(
                  selectedIndex: 1,
                  child: VideosScreen(),
                ),
              ),
              GoRoute(
                path: '/scenes',
                builder: (context, state) => const RootLayout(
                  selectedIndex: 2,
                  child: ScenesScreen(),
                ),
              ),
              GoRoute(
                path: '/personas',
                builder: (context, state) => const RootLayout(
                  selectedIndex: 3,
                  child: PersonasScreen(),
                ),
              ),
              GoRoute(
                path: '/profile',
                builder: (context, state) => const RootLayout(
                  selectedIndex: 4,
                  child: ProfileScreen(),
                ),
              ),
              GoRoute(
                path: '/video-result',
                builder: (context, state) => VideoResultScreen(
                  taskId: state.extra as String,
                ),
              ),
              GoRoute(
                path: '/avatar-customization',
                builder: (context, state) => AvatarCustomizationScreen(
                  avatar: state.extra as Avatar?,
                ),
              ),
              GoRoute(
                path: '/create-scene',
                builder: (context, state) => CreateSceneScreen(
                  persona: state.extra as Persona,
                ),
              ),
              GoRoute(
                path: '/avatars',
                builder: (context, state) => const AvatarsScreen(),
              ),
            ],
            initialLocation: '/login',
          );

          return MaterialApp.router(
            title: 'Your App Name',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              scaffoldBackgroundColor: settings.isVirtual ? Colors.black87 : Colors.white,
              textTheme: Theme.of(context).textTheme.apply(
                bodyColor: settings.isVirtual ? Colors.white : Colors.black87,
                displayColor: settings.isVirtual ? Colors.white : Colors.black87,
              ),
            ),
            routerConfig: router,
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
