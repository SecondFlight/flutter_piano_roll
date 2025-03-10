import 'package:flutter/widgets.dart';
import 'package:flutter_piano_roll/helpers.dart';
import 'package:provider/provider.dart';
import 'package:flutter_piano_roll/pattern.dart';

class PianoRollGrid extends StatelessWidget {
  const PianoRollGrid({
    Key? key,
    required this.keyHeight,
    required this.keyValueAtTop,
  }) : super(key: key);

  final double keyValueAtTop;
  final double keyHeight;

  @override
  Widget build(BuildContext context) {
    var pattern = context.watch<Pattern>();
    var timeView = context.watch<TimeView>();

    return ClipRect(
      child: CustomPaint(
        painter: PianoRollBackgroundPainter(
          keyHeight: keyHeight,
          keyValueAtTop: keyValueAtTop,
          pattern: pattern,
          timeViewStart: timeView.start,
          timeViewEnd: timeView.end,
        ),
      ),
    );
  }
}

class PianoRollBackgroundPainter extends CustomPainter {
  PianoRollBackgroundPainter({
    required this.keyHeight,
    required this.keyValueAtTop,
    required this.pattern,
    required this.timeViewStart,
    required this.timeViewEnd,
  });

  final double keyHeight;
  final double keyValueAtTop;
  final Pattern pattern;
  final double timeViewStart;
  final double timeViewEnd;

  @override
  void paint(Canvas canvas, Size size) {
    var black = Paint();
    black.color = const Color(0xFF000000);

    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF000000).withOpacity(0.2),
    );

    // Horizontal lines

    var linePointer = ((keyValueAtTop * keyHeight) % keyHeight);

    while (linePointer < size.height) {
      canvas.drawRect(Rect.fromLTWH(0, linePointer, size.width, 1), black);
      linePointer += keyHeight;
    }

    // Vertical lines

    var minorDivisionChanges = getDivisionChanges(
      viewWidthInPixels: size.width,
      minPixelsPerSection: 8,
      snap: DivisionSnap(division: Division(multiplier: 1, divisor: 4)),
      defaultTimeSignature: pattern.baseTimeSignature,
      timeSignatureChanges: pattern.timeSignatureChanges,
      ticksPerQuarter: pattern.ticksPerBeat,
      timeViewStart: timeViewStart,
      timeViewEnd: timeViewEnd,
    );

    paintVerticalLines(
      canvas: canvas,
      timeViewStart: timeViewStart,
      timeViewEnd: timeViewEnd,
      divisionChanges: minorDivisionChanges,
      size: size,
      paint: black,
    );

    // Draws everything since canvas.saveLayer() with the color provided in
    // canvas.saveLayer(). This means that overlapping lines won't be darker,
    // even though the whole thing is rendered with opacity.
    canvas.restore();

    var majorDivisionChanges = getDivisionChanges(
      viewWidthInPixels: size.width,
      minPixelsPerSection: 20,
      snap: DivisionSnap(division: Division(multiplier: 1, divisor: 1)),
      defaultTimeSignature: pattern.baseTimeSignature,
      timeSignatureChanges: pattern.timeSignatureChanges,
      ticksPerQuarter: pattern.ticksPerBeat,
      timeViewStart: timeViewStart,
      timeViewEnd: timeViewEnd,
    );

    var majorVerticalLinePaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.22);

    paintVerticalLines(
      canvas: canvas,
      timeViewStart: timeViewStart,
      timeViewEnd: timeViewEnd,
      divisionChanges: majorDivisionChanges,
      size: size,
      paint: majorVerticalLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant PianoRollBackgroundPainter oldDelegate) {
    return oldDelegate.keyHeight != keyHeight ||
        oldDelegate.keyValueAtTop != keyValueAtTop ||
        oldDelegate.timeViewStart != timeViewStart ||
        oldDelegate.timeViewEnd != timeViewEnd;
  }
}

void paintVerticalLines({
  required Canvas canvas,
  required double timeViewStart,
  required double timeViewEnd,
  required List<DivisionChange> divisionChanges,
  required Size size,
  required Paint paint,
}) {
  var i = 0;
  // There should always be at least one division change. The first change
  // should always represent the base time signature for the pattern (or the
  // first time signature change, if its position is 0).
  var timePtr =
      (timeViewStart / divisionChanges[0].divisionRenderSize).floor() *
          divisionChanges[0].divisionRenderSize;

  while (timePtr < timeViewEnd) {
    // This shouldn't happen, but safety first
    if (i >= divisionChanges.length) break;

    var thisDivision = divisionChanges[i];
    var nextDivisionStart = 0x7FFFFFFFFFFFFFFF; // int max

    if (i < divisionChanges.length - 1) {
      nextDivisionStart = divisionChanges[i + 1].offset;
    }

    if (timePtr >= nextDivisionStart) {
      timePtr = nextDivisionStart;
      i++;
      continue;
    }

    while (timePtr < nextDivisionStart && timePtr < timeViewEnd) {
      var x = timeToPixels(
          timeViewStart: timeViewStart,
          timeViewEnd: timeViewEnd,
          viewPixelWidth: size.width,
          time: timePtr.toDouble());

      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), paint);

      timePtr += thisDivision.divisionRenderSize;
    }

    i++;
  }
}
