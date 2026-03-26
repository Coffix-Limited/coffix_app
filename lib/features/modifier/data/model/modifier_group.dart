import 'package:freezed_annotation/freezed_annotation.dart';

part 'modifier_group.g.dart';

@JsonSerializable()
class ModifierGroup {
  final String? docId;
  final List<String> modifierIds;
  final String? name;
  // final bool? required;
  final String? selectionType;

  ModifierGroup({
    this.docId,
    this.modifierIds = const [],
    this.name,
    // this.required,
    this.selectionType,
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) =>
      _$ModifierGroupFromJson(json);
  Map<String, dynamic> toJson() => _$ModifierGroupToJson(this);
}
