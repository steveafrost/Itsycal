//
//  Created by Sanjay Madan on 6/12/17.
//  Copyright © 2017 mowglii.com. All rights reserved.
//

#import "Themer.h"
#import "Itsycal.h"
#import "MoUtils.h"

// NSUserDefaults key
NSString * const kThemePreference = @"ThemePreference";

// Returns a color that resolves to light in Light Mode
// and dark in Dark Mode.
static NSColor *LightDarkColor(NSColor *light, NSColor *dark)
{
    return [NSColor colorWithName:nil dynamicProvider:^NSColor *(NSAppearance *appearance) {
        BOOL isDark = [appearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]] == NSAppearanceNameDarkAqua;
        return isDark ? dark : light;
    }];
}

static NSColor *RGB(uint32_t hex)
{
    return [NSColor colorWithSRGBRed:((hex >> 16) & 0xFF) / 255.0
                               green:((hex >> 8) & 0xFF) / 255.0
                                blue:(hex & 0xFF) / 255.0
                               alpha:1];
}

// Recursively mark a view hierarchy for redrawing.
static void SetNeedsDisplayRecursively(NSView *view)
{
    view.needsDisplay = YES;
    for (NSView *subview in view.subviews) {
        SetNeedsDisplayRecursively(subview);
    }
}

@implementation Themer

Themer *Theme = nil;

+ (instancetype)shared
{
    static Themer *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[Themer alloc] init];
        Theme = shared;
    });
    return shared;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _themePreference = [[NSUserDefaults standardUserDefaults] integerForKey:kThemePreference];
        [self adjustAppAppearanceForThemePreference];
    }
    return self;
}

- (void)setThemePreference:(ThemePreference)themePref {
    // Validate themePref before setting ivar.
    _themePreference = (themePref < ThemePreferenceSystem || themePref > ThemePreferenceCatppuccinMocha) ? ThemePreferenceSystem : themePref;
    [self adjustAppAppearanceForThemePreference];
    // Colors are dynamic and resolve against the theme when drawn.
    // Switching between themes that share an appearance (e.g. Dark
    // and Catppuccin Mocha) doesn't trigger a redraw, so force one.
    for (NSWindow *window in NSApp.windows) {
        NSView *root = window.contentView.superview ?: window.contentView;
        if (root) SetNeedsDisplayRecursively(root);
    }
}

- (BOOL)isCatppuccin {
    return _themePreference == ThemePreferenceCatppuccin ||
           _themePreference == ThemePreferenceCatppuccinLatte ||
           _themePreference == ThemePreferenceCatppuccinMocha;
}

// Returns a color that resolves to `standard` with the standard themes
// and to the Catppuccin Latte or Mocha color with the Catppuccin themes.
// https://catppuccin.com/palette
- (NSColor *)standard:(NSColor *)standard latte:(uint32_t)latte mocha:(uint32_t)mocha {
    NSColor *catppuccin = LightDarkColor(RGB(latte), RGB(mocha));
    return [NSColor colorWithName:nil dynamicProvider:^NSColor *(NSAppearance *appearance) {
        return [self isCatppuccin] ? catppuccin : standard;
    }];
}

- (void)adjustAppAppearanceForThemePreference {
    switch (_themePreference) {
        case ThemePreferenceSystem:
        case ThemePreferenceCatppuccin:
            NSApp.appearance = nil;
            break;
        case ThemePreferenceDark:
        case ThemePreferenceCatppuccinMocha:
            NSApp.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
            break;
        case ThemePreferenceLight:
        case ThemePreferenceCatppuccinLatte:
        default:
            NSApp.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    }
}

- (NSColor *)agendaDayTextColor {
    // Catppuccin: Subtext 0
    return [self standard:NSColor.secondaryLabelColor latte:0x6c6f85 mocha:0xa6adc8];
}

- (NSColor *)agendaDividerColor {
    // Catppuccin: Surface 0
    return [self standard:NSColor.separatorColor latte:0xccd0da mocha:0x313244];
}

- (NSColor *)agendaDOWTextColor {
    return [self monthTextColor];
}

- (NSColor *)agendaEventDateTextColor {
    // Catppuccin: Subtext 0
    return [self standard:NSColor.secondaryLabelColor latte:0x6c6f85 mocha:0xa6adc8];
}

- (NSColor *)agendaEventTextColor {
    return [self monthTextColor];
}

- (NSColor *)agendaHoverColor {
    return [self highlightedDOWBackgroundColor];
}

- (NSColor *)currentMonthOutlineColor {
    // Catppuccin: Lavender
    return [self standard:LightDarkColor(NSColor.labelColor, NSColor.secondaryLabelColor) latte:0x7287fd mocha:0xb4befe];
}

- (NSColor *)currentMonthTextColor {
    // Catppuccin: Text
    return [self standard:NSColor.labelColor latte:0x4c4f69 mocha:0xcdd6f4];
}

- (NSColor *)DOWTextColor {
    // Catppuccin: Text
    return [self standard:NSColor.labelColor latte:0x4c4f69 mocha:0xcdd6f4];
}

- (NSColor *)highlightedDOWBackgroundColor {
    // Catppuccin: Mantle
    return [self standard:NSColor.secondarySystemFillColor latte:0xe6e9ef mocha:0x181825];
}

- (NSColor *)highlightedDOWTextColor {
    // Catppuccin: Subtext 0
    return [self standard:NSColor.secondaryLabelColor latte:0x6c6f85 mocha:0xa6adc8];
}

- (NSColor *)hoveredCellColor {
    // Catppuccin: Overlay 0
    return [self standard:NSColor.tertiaryLabelColor latte:0x9ca0b0 mocha:0x6c7086];
}

- (NSColor *)mainBackgroundColor {
    // windowBackgroundColor is white in Light Mode. In Dark
    // Mode, use a gray halfway between windowBackgroundColor
    // (0.118) and underPageBackgroundColor (0.157).
    // Catppuccin: Base
    return [self standard:LightDarkColor(NSColor.windowBackgroundColor, [NSColor colorWithWhite:0.137 alpha:1]) latte:0xeff1f5 mocha:0x1e1e2e];
}

- (NSColor *)monthTextColor {
    // Catppuccin: Text
    return [self standard:NSColor.labelColor latte:0x4c4f69 mocha:0xcdd6f4];
}

- (NSColor *)noncurrentMonthTextColor {
    // Catppuccin: Overlay 0
    return [self standard:NSColor.tertiaryLabelColor latte:0x9ca0b0 mocha:0x6c7086];
}

- (NSColor *)pendingBackgroundColor {
    // Catppuccin: Surface 0
    return [self standard:NSColor.secondarySystemFillColor latte:0xccd0da mocha:0x313244];
}

- (NSColor *)resizeHandleBackgroundColor {
    return [self highlightedDOWBackgroundColor];
}

- (NSColor *)resizeHandleForegroundColor {
    // Catppuccin: Overlay 1
    return [self standard:NSColor.secondaryLabelColor latte:0x8c8fa1 mocha:0x7f849c];
}

- (NSColor *)selectedCellColor {
    return [self currentMonthOutlineColor];
}

- (NSColor *)todayCellColor {
    // Catppuccin: Mauve
    return [self standard:NSColor.systemBlueColor latte:0x8839ef mocha:0xcba6f7];
}

- (NSColor *)tooltipBackgroundColor {
    return [self mainBackgroundColor];
}

- (NSColor *)weekTextColor {
    // Catppuccin: Overlay 1
    return [self standard:NSColor.secondaryLabelColor latte:0x8c8fa1 mocha:0x7f849c];
}

@end
