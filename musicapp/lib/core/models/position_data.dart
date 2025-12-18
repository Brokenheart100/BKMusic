import 'package:equatable/equatable.dart';

class PositionData extends Equatable {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  const PositionData(this.position, this.bufferedPosition, this.duration);

  @override
  List<Object?> get props => [position, bufferedPosition, duration];

  // 便捷工厂方法：空状态
  factory PositionData.empty() =>
      const PositionData(Duration.zero, Duration.zero, Duration.zero);
}
