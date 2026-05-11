import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String username;
  final String role; // 'admin' atau 'manager'

  const UserEntity({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
  });

  @override
  List<Object?> get props => [id, name, username, role];
}