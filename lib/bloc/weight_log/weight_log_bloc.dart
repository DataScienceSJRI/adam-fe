import 'package:adam/data/models/weight_log_model.dart';
import 'package:adam/data/repositories/weight_log_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class WeightEvent {}

class SubmitWeightEvent extends WeightEvent {
  final WeightLogModel weight;

  SubmitWeightEvent(this.weight);
}

class FetchWeightsEvent extends WeightEvent {}

class DeleteWeightEvent extends WeightEvent {
  final String id;

  DeleteWeightEvent(this.id);
}

abstract class WeightState {}

class WeightInitial extends WeightState {}

class WeightLoading extends WeightState {}

class WeightSuccess extends WeightState {
  final List<WeightHistoryModel> weights;

  WeightSuccess(this.weights);
}

class WeightFailure extends WeightState {
  final String message;

  WeightFailure(this.message);
}

class WeightBloc extends Bloc<WeightEvent, WeightState> {
  final WeightRepository repository;

  WeightBloc({required this.repository}) : super(WeightInitial()) {
    on<SubmitWeightEvent>(_submitWeight);
    on<FetchWeightsEvent>(_fetchWeights);
    on<DeleteWeightEvent>(_deleteWeight);
  }

  Future<void> _submitWeight(
    SubmitWeightEvent event,
    Emitter<WeightState> emit,
  ) async {
    try {
      emit(WeightLoading());

      await repository.logWeight(event.weight);

      final data = await repository.fetchWeights();

      emit(WeightSuccess(data));
    } catch (e) {
      emit(WeightFailure(e.toString()));
    }
  }

  Future<void> _fetchWeights(
    FetchWeightsEvent event,
    Emitter<WeightState> emit,
  ) async {
    try {
      emit(WeightLoading());

      final data = await repository.fetchWeights();

      emit(WeightSuccess(data));
    } catch (e) {
      emit(WeightFailure(e.toString()));
    }
  }

  Future<void> _deleteWeight(
    DeleteWeightEvent event,
    Emitter<WeightState> emit,
  ) async {
    try {
      emit(WeightLoading());

      await repository.deleteWeight(event.id);

      final data = await repository.fetchWeights();

      emit(WeightSuccess(data));
    } catch (e) {
      emit(WeightFailure(e.toString()));
    }
  }
}
