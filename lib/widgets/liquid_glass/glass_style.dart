/// Visual style variants matching LiquidGlass specification
enum GlassStyle {
  /// Floating panel with prominent depth (Modal sheets, bottom sheets, full player).
  sheet,

  /// Contained surface with medium depth (Cards, list items, shloka container).
  card,

  /// Compact surface tuned for interactive controls & action buttons.
  button,

  /// Inline element for toolbars, search bars, and navigation chrome.
  toolbar,

  /// Full-height navigation surface with a thicker material.
  sidebar,

  /// Full-coverage overlay with maximum blur.
  overlay,
}

extension GlassStyleExtension on GlassStyle {
  double get defaultCornerRadius {
    switch (this) {
      case GlassStyle.sheet:
        return 24.0;
      case GlassStyle.card:
        return 16.0;
      case GlassStyle.button:
        return 12.0;
      case GlassStyle.toolbar:
        return 12.0;
      case GlassStyle.sidebar:
        return 20.0;
      case GlassStyle.overlay:
        return 0.0;
    }
  }

  double get blurSigma {
    switch (this) {
      case GlassStyle.sheet:
        return 24.0;
      case GlassStyle.card:
        return 16.0;
      case GlassStyle.button:
        return 12.0;
      case GlassStyle.toolbar:
        return 18.0;
      case GlassStyle.sidebar:
        return 28.0;
      case GlassStyle.overlay:
        return 36.0;
    }
  }

  double get borderOpacity {
    switch (this) {
      case GlassStyle.sheet:
      case GlassStyle.card:
      case GlassStyle.sidebar:
        return 0.28;
      case GlassStyle.button:
      case GlassStyle.toolbar:
        return 0.20;
      case GlassStyle.overlay:
        return 0.12;
    }
  }

  double get shadowRadius {
    switch (this) {
      case GlassStyle.sheet:
        return 20.0;
      case GlassStyle.card:
        return 10.0;
      case GlassStyle.button:
        return 6.0;
      case GlassStyle.toolbar:
        return 4.0;
      case GlassStyle.sidebar:
        return 14.0;
      case GlassStyle.overlay:
        return 0.0;
    }
  }

  double get shadowOffsetY {
    switch (this) {
      case GlassStyle.sheet:
        return 8.0;
      case GlassStyle.card:
        return 4.0;
      case GlassStyle.button:
        return 2.0;
      case GlassStyle.toolbar:
        return 2.0;
      case GlassStyle.sidebar:
        return 6.0;
      case GlassStyle.overlay:
        return 0.0;
    }
  }

  double get shadowOpacity {
    switch (this) {
      case GlassStyle.sheet:
        return 0.22;
      case GlassStyle.card:
        return 0.14;
      case GlassStyle.button:
        return 0.10;
      case GlassStyle.toolbar:
        return 0.08;
      case GlassStyle.sidebar:
        return 0.18;
      case GlassStyle.overlay:
        return 0.0;
    }
  }

  double get tintOpacity {
    switch (this) {
      case GlassStyle.button:
      case GlassStyle.toolbar:
        return 0.18;
      case GlassStyle.sheet:
      case GlassStyle.card:
      case GlassStyle.sidebar:
        return 0.14;
      case GlassStyle.overlay:
        return 0.10;
    }
  }

  double get fillOpacity {
    switch (this) {
      case GlassStyle.sheet:
        return 0.70;
      case GlassStyle.card:
        return 0.75;
      case GlassStyle.button:
        return 0.80;
      case GlassStyle.toolbar:
        return 0.72;
      case GlassStyle.sidebar:
        return 0.82;
      case GlassStyle.overlay:
        return 0.88;
    }
  }
}
