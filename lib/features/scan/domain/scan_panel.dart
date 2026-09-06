enum PanelType {
  frontLeftDoor,
  frontRightDoor,
  rearLeftDoor,
  rearRightDoor,
  hood,
  roof,
  frontFender,
  rearQuarter,
  other,
}

extension PanelTypeLabel on PanelType {
  String get displayName => switch (this) {
        PanelType.frontLeftDoor => 'Front Left Door',
        PanelType.frontRightDoor => 'Front Right Door',
        PanelType.rearLeftDoor => 'Rear Left Door',
        PanelType.rearRightDoor => 'Rear Right Door',
        PanelType.hood => 'Hood',
        PanelType.roof => 'Roof',
        PanelType.frontFender => 'Front Fender',
        PanelType.rearQuarter => 'Rear Quarter',
        PanelType.other => 'Other',
      };

  String get icon => switch (this) {
        PanelType.frontLeftDoor => '🚗',
        PanelType.frontRightDoor => '🚗',
        PanelType.rearLeftDoor => '🚘',
        PanelType.rearRightDoor => '🚘',
        PanelType.hood => '🔲',
        PanelType.roof => '⬛',
        PanelType.frontFender => '◀',
        PanelType.rearQuarter => '▶',
        PanelType.other => '❓',
      };
}
