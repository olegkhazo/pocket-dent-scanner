import 'package:image/image.dart' as img;

import 'cv_config.dart';

// Detects stripe centerlines using Version C: sample intensity perpendicular
// to stripe direction, find local maxima per row.
class StripeDetector {
  final CvConfig config;

  const StripeDetector(this.config);

  // Returns centerlines[stripe_idx][row] = x position (or -1 if not tracked).
  // Processes vertical stripes (scans horizontally per row).
  List<List<double>> detect(img.Image gray) {
    final width = gray.width;
    final height = gray.height;

    // Step 1: for each row, find local maxima of brightness.
    // perRowMaxima[row] = sorted list of x positions of local maxima.
    final perRowMaxima = List<List<int>>.generate(height, (_) => []);

    for (var y = 0; y < height; y++) {
      final row = _extractRow(gray, y);
      final smoothed = _smooth1D(row, config.blurRadius);
      perRowMaxima[y] = _localMaxima(smoothed);
    }

    // Step 2: link maxima across rows into stripe tracks.
    // Each track is a list of (row → x) mappings.
    return _buildCenterlines(perRowMaxima, width, height);
  }

  List<double> _extractRow(img.Image gray, int y) {
    return List<double>.generate(
      gray.width,
      (x) => gray.getPixel(x, y).luminance,
    );
  }

  // Simple box smoothing.
  List<double> _smooth1D(List<double> row, int radius) {
    if (radius <= 0) return row;
    final result = List<double>.filled(row.length, 0);
    for (var i = 0; i < row.length; i++) {
      var sum = 0.0;
      var count = 0;
      for (var k = -radius; k <= radius; k++) {
        final idx = i + k;
        if (idx >= 0 && idx < row.length) {
          sum += row[idx];
          count++;
        }
      }
      result[i] = sum / count;
    }
    return result;
  }

  List<int> _localMaxima(List<double> row) {
    final maxima = <int>[];
    for (var i = 1; i < row.length - 1; i++) {
      if (row[i] > row[i - 1] && row[i] > row[i + 1] && row[i] > 0.3) {
        maxima.add(i);
      }
    }
    return maxima;
  }

  List<List<double>> _buildCenterlines(
      List<List<int>> perRowMaxima, int width, int height) {
    // tracks[stripe_idx][row] = x (or -1 if gap)
    final tracks = <List<double>>[];

    for (var y = 0; y < height; y++) {
      final maxima = perRowMaxima[y];
      if (maxima.isEmpty) continue;

      if (tracks.isEmpty) {
        // First row: initialize one track per maximum.
        for (final x in maxima) {
          final track = List<double>.filled(height, -1);
          track[y] = x.toDouble();
          tracks.add(track);
        }
        continue;
      }

      // Match maxima to existing tracks by proximity.
      final maxGap = config.maxStripeGap * 2.0;
      final matched = List<bool>.filled(maxima.length, false);

      for (final track in tracks) {
        // Find the last known x for this track.
        double lastX = -1;
        for (var r = y - 1; r >= 0 && r >= y - config.maxStripeGap; r--) {
          if (track[r] >= 0) {
            lastX = track[r];
            break;
          }
        }
        if (lastX < 0) continue;

        // Find closest unmatched maximum within maxGap.
        var bestDist = maxGap;
        var bestIdx = -1;
        for (var m = 0; m < maxima.length; m++) {
          if (matched[m]) continue;
          final dist = (maxima[m] - lastX).abs();
          if (dist < bestDist) {
            bestDist = dist;
            bestIdx = m;
          }
        }

        if (bestIdx >= 0) {
          track[y] = maxima[bestIdx].toDouble();
          matched[bestIdx] = true;
        }
      }

      // Create new tracks for unmatched maxima.
      for (var m = 0; m < maxima.length; m++) {
        if (!matched[m]) {
          final track = List<double>.filled(height, -1);
          track[y] = maxima[m].toDouble();
          tracks.add(track);
        }
      }
    }

    // Filter: keep only tracks with enough valid rows.
    return tracks
        .where((t) => t.where((x) => x >= 0).length >= config.minStripeLength)
        .toList();
  }
}
