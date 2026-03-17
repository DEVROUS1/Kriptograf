import 'package:go_router/go_router.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/markets_screen.dart';
import 'presentation/screens/news_screen.dart';
import 'presentation/screens/portfolio_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/piyasalar',
      builder: (context, state) => const MarketsScreen(),
    ),
    GoRoute(
      path: '/haberler',
      builder: (context, state) => const NewsScreen(),
    ),
    GoRoute(
      path: '/portfoy',
      builder: (context, state) => const PortfolioScreen(),
    ),
  ],
);
