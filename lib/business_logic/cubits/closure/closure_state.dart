import 'package:equatable/equatable.dart';

sealed class ClosureState extends Equatable {
  const ClosureState();
  @override
  List<Object?> get props => [];
}

class ClosureInitial extends ClosureState {
  const ClosureInitial();
}

class ClosureLoading extends ClosureState {
  const ClosureLoading();
}

class ClosureDraftLoaded extends ClosureState {
  final Map<String, dynamic> closure;
  const ClosureDraftLoaded(this.closure);
  @override
  List<Object?> get props => [closure];
}

class ClosureSuccess extends ClosureState {
  final bool published;
  final bool queued;
  const ClosureSuccess({required this.published, this.queued = false});
  @override
  List<Object?> get props => [published, queued];
}

class ClosureError extends ClosureState {
  final String message;
  const ClosureError(this.message);
  @override
  List<Object?> get props => [message];
}
