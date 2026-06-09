local UIStyle = {}

UIStyle.Colors = {
    Background = Color3.fromRGB(13, 11, 10),
    TableWood = Color3.fromRGB(70, 44, 27),
    TableWoodDark = Color3.fromRGB(43, 28, 20),
    Stone = Color3.fromRGB(92, 88, 78),
    StoneDark = Color3.fromRGB(47, 47, 43),

    Text = Color3.fromRGB(246, 239, 219),
    Muted = Color3.fromRGB(178, 166, 137),
    Ink = Color3.fromRGB(42, 32, 24),

    Card = Color3.fromRGB(238, 221, 177),
    CardDark = Color3.fromRGB(213, 189, 140),

    Gold = Color3.fromRGB(245, 190, 72),
    Red = Color3.fromRGB(220, 82, 67),
    Blue = Color3.fromRGB(87, 165, 240),
    Green = Color3.fromRGB(89, 197, 129),
    Purple = Color3.fromRGB(172, 103, 232),
    Border = Color3.fromRGB(124, 91, 52),
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
