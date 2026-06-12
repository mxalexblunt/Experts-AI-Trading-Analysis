import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_motion.dart';

class ChartScreenshotField extends StatefulWidget {
  const ChartScreenshotField({
    super.key,
    required this.imagePath,
    required this.onImagePicked,
    required this.onRemove,
  });

  final String? imagePath;
  final ValueChanged<PickedChartImage> onImagePicked;
  final VoidCallback onRemove;

  @override
  State<ChartScreenshotField> createState() => _ChartScreenshotFieldState();
}

class _ChartScreenshotFieldState extends State<ChartScreenshotField> {
  static const bool _useE2eFakePicker = bool.fromEnvironment(
    'EXPERTS_E2E_FAKE_PICKER',
  );

  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    if (widget.imagePath != null) {
      return _ScreenshotPreview(
        imagePath: widget.imagePath!,
        onRemove: widget.onRemove,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MotionPressable(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            pressedOpacity: 1,
            onPressed: () => _showImageSourceSheet(context),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.xl),
                boxShadow: AppShadows.card,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    CupertinoIcons.photo,
                    color: AppColors.textTertiary,
                    size: 28,
                  ),
                  const SizedBox(height: AppSpacing.tiny),
                  Text('Add chart screenshot', style: AppTypography.headline),
                  const SizedBox(height: AppSpacing.micro),
                  Text(
                    'TradingView or any clear chart image',
                    style: AppTypography.footnote,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.tiny),
          Text(
            _errorMessage!,
            style: AppTypography.footnote.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }

  void _showImageSourceSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext, rootNavigator: true).pop();
                _pickImage(ImageSource.camera);
              },
              child: const Text('Take Photo'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(sheetContext, rootNavigator: true).pop();
                _pickImage(ImageSource.gallery);
              },
              child: const Text('Choose from Library'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(sheetContext, rootNavigator: true).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _errorMessage = null);
      if (_useE2eFakePicker) {
        final image = await _createE2eImage();
        widget.onImagePicked(image);
        return;
      }

      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      widget.onImagePicked(
        PickedChartImage(
          path: picked.path,
          base64Image: base64Encode(bytes),
          mimeType: picked.mimeType ?? 'image/jpeg',
        ),
      );
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Photo access was not available. Check Camera and Photos permissions in Settings.';
      });
    } on FileSystemException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'The selected image could not be read.';
      });
    }
  }

  Future<PickedChartImage> _createE2eImage() async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
    );
    final file = File(
      '${Directory.systemTemp.path}/experts_e2e_chart_screenshot.png',
    );
    await file.writeAsBytes(bytes);
    return PickedChartImage(
      path: file.path,
      base64Image: base64Encode(bytes),
      mimeType: 'image/png',
    );
  }
}

class PickedChartImage {
  const PickedChartImage({
    required this.path,
    required this.base64Image,
    required this.mimeType,
  });

  final String path;
  final String base64Image;
  final String mimeType;
}

class _ScreenshotPreview extends StatelessWidget {
  const _ScreenshotPreview({required this.imagePath, required this.onRemove});

  static const bool _useE2eFakePicker = bool.fromEnvironment(
    'EXPERTS_E2E_FAKE_PICKER',
  );

  final String imagePath;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_useE2eFakePicker)
          Container(
            height: 150,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              boxShadow: AppShadows.card,
            ),
            child: Text(
              'Test screenshot attached',
              style: AppTypography.footnote,
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: Image.file(
              File(imagePath),
              key: ValueKey(imagePath),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        Positioned(
          top: AppSpacing.tiny,
          right: AppSpacing.tiny,
          child: MotionPressable(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              pressedOpacity: 1,
              onPressed: onRemove,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.68),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 16,
                  color: AppColors.canvasPure,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
