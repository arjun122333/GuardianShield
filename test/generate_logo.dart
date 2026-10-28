import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Generate Guardian Shield App Logo', () async {
    const size = 512.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

    final center = const Offset(size / 2, size / 2);

    // 1. Transparent / Dark Blue Rounded Canvas
    final bgPaint = Paint()..color = const Color(0xFF0F1117);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, size, size), const Radius.circular(120)),
      bgPaint,
    );

    // 2. Outer Cyan/Blue Gradient Ring
    final ringPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(size, size),
        const [Color(0xFF00E5FF), Color(0xFF1565C0)],
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 210),
      -0.8,
      4.8,
      false,
      ringPaint,
    );

    // 3. Central Shield - Left Half (Darker Blue)
    final shieldLeftPath = Path();
    shieldLeftPath.moveTo(size / 2, 80);
    shieldLeftPath.cubicTo(180, 80, 110, 140, 110, 240);
    shieldLeftPath.cubicTo(110, 360, 220, 420, size / 2, 450);
    shieldLeftPath.lineTo(size / 2, 80);
    shieldLeftPath.close();

    final leftShieldPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(110, 80),
        const Offset(256, 450),
        const [Color(0xFF1E3A8A), Color(0xFF0F172A)],
      );
    canvas.drawPath(shieldLeftPath, leftShieldPaint);

    // Central Shield - Right Half (Lighter Blue for 3D Shader Effect)
    final shieldRightPath = Path();
    shieldRightPath.moveTo(size / 2, 80);
    shieldRightPath.cubicTo(332, 80, 402, 140, 402, 240);
    shieldRightPath.cubicTo(402, 360, 292, 420, size / 2, 450);
    shieldRightPath.lineTo(size / 2, 80);
    shieldRightPath.close();

    final rightShieldPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(256, 80),
        const Offset(402, 450),
        const [Color(0xFF2563EB), Color(0xFF1E40AF)],
      );
    canvas.drawPath(shieldRightPath, rightShieldPaint);

    // Shield Border Highlight
    final shieldBorderPaint = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;

    final fullShieldPath = Path()
      ..moveTo(size / 2, 80)
      ..cubicTo(180, 80, 110, 140, 110, 240)
      ..cubicTo(110, 360, 220, 420, size / 2, 450)
      ..cubicTo(292, 420, 402, 360, 402, 240)
      ..cubicTo(402, 140, 332, 80, size / 2, 80)
      ..close();

    canvas.drawPath(fullShieldPath, shieldBorderPaint);

    // 4. White Family Silhouette inside Shield
    final familyPaint = Paint()..color = Colors.white;

    // --- Father (Center Left) ---
    canvas.drawCircle(const Offset(225, 205), 18, familyPaint);
    final fatherBody = Path()
      ..moveTo(225, 230)
      ..lineTo(200, 275)
      ..lineTo(212, 340)
      ..lineTo(225, 340)
      ..lineTo(228, 290)
      ..lineTo(232, 340)
      ..lineTo(245, 340)
      ..lineTo(250, 275)
      ..close();
    canvas.drawPath(fatherBody, familyPaint);

    // --- Mother (Center Right) ---
    canvas.drawCircle(const Offset(287, 210), 17, familyPaint);
    final motherBody = Path()
      ..moveTo(287, 233)
      ..lineTo(265, 280)
      ..lineTo(260, 335)
      ..lineTo(275, 335)
      ..lineTo(287, 290)
      ..lineTo(299, 335)
      ..lineTo(314, 335)
      ..lineTo(309, 280)
      ..close();
    canvas.drawPath(motherBody, familyPaint);

    // --- Children ---
    // Girl 1 (Far Left)
    canvas.drawCircle(const Offset(165, 235), 13, familyPaint);
    final girl1Body = Path()
      ..moveTo(165, 252)
      ..lineTo(148, 295)
      ..lineTo(158, 340)
      ..lineTo(172, 340)
      ..lineTo(182, 295)
      ..close();
    canvas.drawPath(girl1Body, familyPaint);

    // Girl 2 (Far Right)
    canvas.drawCircle(const Offset(347, 235), 13, familyPaint);
    final girl2Body = Path()
      ..moveTo(347, 252)
      ..lineTo(330, 295)
      ..lineTo(340, 340)
      ..lineTo(354, 340)
      ..lineTo(364, 295)
      ..close();
    canvas.drawPath(girl2Body, familyPaint);

    // Child (Middle Center holding hands)
    canvas.drawCircle(const Offset(256, 260), 11, familyPaint);
    final childBody = Path()
      ..moveTo(256, 275)
      ..lineTo(242, 310)
      ..lineTo(250, 345)
      ..lineTo(262, 345)
      ..lineTo(270, 310)
      ..close();
    canvas.drawPath(childBody, familyPaint);

    // Render Picture to Image
    final picture = recorder.endRecording();
    final img = await picture.toImage(512, 512);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // Ensure assets/images directory exists
    final assetsDir = Directory('assets/images');
    if (!assetsDir.existsSync()) {
      assetsDir.createSync(recursive: true);
    }

    // Write app_logo.png
    final logoFile = File('assets/images/app_logo.png');
    logoFile.writeAsBytesSync(buffer);
    print('✅ App Logo generated successfully at: ${logoFile.path}');

    // Copy to Android mipmap resource directories
    final resDir = Directory('android/app/src/main/res');
    if (resDir.existsSync()) {
      for (var dir in ['mipmap-hdpi', 'mipmap-mdpi', 'mipmap-xhdpi', 'mipmap-xxhdpi', 'mipmap-xxxhdpi', 'drawable']) {
        final targetFolder = Directory('android/app/src/main/res/$dir');
        if (!targetFolder.existsSync()) targetFolder.createSync(recursive: true);
        File('android/app/src/main/res/$dir/ic_launcher.png').writeAsBytesSync(buffer);
      }
      print('✅ Copied launcher icon to all Android mipmap directories!');
    }
  });
}
