import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/closure_repository.dart';
import 'closure_state.dart';

class ClosureCubit extends Cubit<ClosureState> {
  final ClosureRepository repository;
  ClosureCubit(this.repository) : super(const ClosureInitial());

  Future<void> loadDraft(int shopId, String date) async {
    emit(const ClosureLoading());
    try {
      final response = await repository.getDraft(shopId, date);
      emit(
        ClosureDraftLoaded(
          Map<String, dynamic>.from(response['closure'] as Map),
        ),
      );
    } catch (error) {
      emit(ClosureError(error.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> submit(int shopId, Map<String, dynamic> data) async {
    emit(const ClosureLoading());
    try {
      final response = await repository.create(shopId, data);
      final queued = response['queued'] == true;
      emit(ClosureSuccess(published: !queued, queued: queued));
    } catch (error) {
      emit(ClosureError(error.toString().replaceFirst('Exception: ', '')));
    }
  }
}
