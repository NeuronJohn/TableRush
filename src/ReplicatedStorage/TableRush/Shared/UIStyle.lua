local UIStyle = {}

UIStyle.Colors = {
    Background = Color3.fromRGB(8, 12, 18),
    TableWood = Color3.fromRGB(24, 32, 42),
    TableWoodDark = Color3.fromRGB(9, 13, 20),
    Stone = Color3.fromRGB(68, 78, 88),
    StoneDark = Color3.fromRGB(23, 31, 42),

    Text = Color3.fromRGB(246, 239, 219),
    Muted = Color3.fromRGB(178, 166, 137),
    Ink = Color3.fromRGB(42, 32, 24),

    Card = Color3.fromRGB(238, 221, 177),
    CardDark = Color3.fromRGB(213, 189, 140),

    Gold = Color3.fromRGB(245, 190, 72),
    Red = Color3.fromRGB(220, 82, 67),
    Blue = Color3.fromRGB(72, 178, 225),
    Green = Color3.fromRGB(85, 205, 165),
    Purple = Color3.fromRGB(172, 103, 232),
    Border = Color3.fromRGB(70, 102, 130),
}

UIStyle.Fonts = {
    Heading = Enum.Font.GothamBold,
    Body = Enum.Font.GothamMedium,
}

UIStyle.Text = {
    Desktop = {
        TopBar = 20,
        RoomTitle = 22,
        ActionTitle = 19,
        ActionBody = 13,
        PlayerNumber = 20,
        Small = 12,
    },
    Compact = {
        TopBar = 16,
        RoomTitle = 18,
        ActionTitle = 16,
        ActionBody = 12,
        PlayerNumber = 16,
        Small = 11,
    },
    Mobile = {
        TopBar = 14,
        RoomTitle = 16,
        ActionTitle = 15,
        ActionBody = 11,
        PlayerNumber = 14,
        Small = 10,
    },
}

return UIStyle
