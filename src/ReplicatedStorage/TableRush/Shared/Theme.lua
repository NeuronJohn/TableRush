-- Compatibility alias for older duplicate client scripts.
-- Current Table Rush code uses UIStyle.
local UIStyle = require(script.Parent.UIStyle)

local Theme = {}

Theme.Colors = {
    Background = UIStyle.Colors.Background,
    Panel = Color3.fromRGB(25, 21, 18),
    PanelSoft = Color3.fromRGB(38, 31, 25),
    Border = UIStyle.Colors.Border,
    Text = UIStyle.Colors.Text,
    Muted = UIStyle.Colors.Muted,
    Card = UIStyle.Colors.Card,
    Ink = UIStyle.Colors.Ink,
    Accent = UIStyle.Colors.Gold,
    AccentBlue = UIStyle.Colors.Blue,
    Success = UIStyle.Colors.Green,
    Danger = UIStyle.Colors.Red,
    Warning = UIStyle.Colors.Gold,
    Purple = UIStyle.Colors.Purple,
}

Theme.Fonts = {
    Heading = UIStyle.Fonts.Heading,
    Body = UIStyle.Fonts.Body,
}

return Theme
