import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// App startup — check if a user is already signed in.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Email + password sign-in.
class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Create a new account and immediately sign in.
class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });

  final String email;
  final String password;
  final String displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Sign out the current user.
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
