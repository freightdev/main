import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:fed_tms/core/routers/index.dart';


final appRouterProvider = Provider<GoRouter>((ref) {
  return ref.watch(routerProvider);
});
