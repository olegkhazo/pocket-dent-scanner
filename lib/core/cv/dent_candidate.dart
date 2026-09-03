import 'package:freezed_annotation/freezed_annotation.dart';

part 'dent_candidate.freezed.dart';
part 'dent_candidate.g.dart';

enum DentSeverity { small, medium, large }

@freezed
class DentCandidate with _$DentCandidate {
  const factory DentCandidate({
    required String id,
    required double normalizedX,
    required double normalizedY,
    required double radiusEstimate,
    required DentSeverity severity,
    required double confidence,
    required int firstFrame,
    required int lastFrame,
    required int supportingFrames,
  }) = _DentCandidate;

  factory DentCandidate.fromJson(Map<String, dynamic> json) =>
      _$DentCandidateFromJson(json);
}
