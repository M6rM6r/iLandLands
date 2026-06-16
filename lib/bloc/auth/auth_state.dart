import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state — before the auth check has run.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Async operation in progress (login / register / logout).
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A user is fully authenticated.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  final User user;

  @override
  List<Object?> get props => <Object?>[user.uid];
}

/// No user is signed in.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An error occurred during an auth operation.
class AuthError extends AuthState {
  const AuthError({required this.message});

  final String message;

  @override
  List<Object?> get props => <Object?>[message];
}
