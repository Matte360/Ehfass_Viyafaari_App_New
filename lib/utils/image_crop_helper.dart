import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickedCroppedImage {
  const PickedCroppedImage({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

enum ImageCropMode {
  original,
  square,
  fourThree,
  wide,
}

extension ImageCropModeLabel on ImageCropMode {
  String label({required bool isDhivehi}) {
    switch (this) {
      case ImageCropMode.original:
        return isDhivehi ? 'އޮރިޖިނަލް' : 'Original';
      case ImageCropMode.square:
        return isDhivehi ? 'ސްކުއެއާ' : 'Square';
      case ImageCropMode.fourThree:
        return isDhivehi ? '4:3' : '4:3';
      case ImageCropMode.wide:
        return isDhivehi ? 'ބެނަރ' : 'Wide';
    }
  }
}

Future<PickedCroppedImage?> pickImageCropAndSet({
  required BuildContext context,
  required ImagePicker picker,
  required bool isDhivehi,
  required String title,
  ImageSource source = ImageSource.gallery,
  ImageCropMode initialMode = ImageCropMode.square,
  int imageQuality = 88,
  double maxWidth = 1800,
}) async {
  final image = await picker.pickImage(
    source: source,
    imageQuality: imageQuality,
    maxWidth: maxWidth,
  );

  if (image == null) return null;

  final bytes = await image.readAsBytes();
  if (!context.mounted) return null;

  return showDialog<PickedCroppedImage>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ImageCropDialog(
      originalBytes: bytes,
      originalFileName: image.name,
      title: title,
      isDhivehi: isDhivehi,
      initialMode: initialMode,
    ),
  );
}

class _ImageCropDialog extends StatefulWidget {
  const _ImageCropDialog({
    required this.originalBytes,
    required this.originalFileName,
    required this.title,
    required this.isDhivehi,
    required this.initialMode,
  });

  final Uint8List originalBytes;
  final String originalFileName;
  final String title;
  final bool isDhivehi;
  final ImageCropMode initialMode;

  @override
  State<_ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<_ImageCropDialog> {
  late ImageCropMode _mode;
  Uint8List? _previewBytes;
  bool _loading = true;
  Object? _error;

  bool get isDhivehi => widget.isDhivehi;

  String text(String english, String dhivehi) => isDhivehi ? dhivehi : english;

  TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: isDhivehi ? 'Faruma' : null,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _buildPreview();
  }

  Future<void> _buildPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final bytes = await cropImageBytes(
        widget.originalBytes,
        mode: _mode,
      );
      if (!mounted) return;
      setState(() => _previewBytes = bytes);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMode(ImageCropMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    _buildPreview();
  }

  @override
  Widget build(BuildContext context) {
    final previewBytes = _previewBytes;

    return Directionality(
      textDirection: isDhivehi ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        title: Text(widget.title, style: style(fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                text(
                  'Choose the crop shape, preview the image, then tap Crop & Set.',
                  'ކްރޮޕް ޝޭޕް ހޮވާ، ޕްރިވިއު ބަލާ، އެއަށްފަހު Crop & Set އަށް ފިއްތާ.',
                ),
                style: style(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ImageCropMode.values.map((mode) {
                  return ChoiceChip(
                    selected: _mode == mode,
                    label: Text(mode.label(isDhivehi: isDhivehi)),
                    onSelected: (_) => _changeMode(mode),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 260,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : _error != null
                          ? Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                _error.toString(),
                                textAlign: TextAlign.center,
                                style: style(color: Colors.red),
                              ),
                            )
                          : previewBytes == null
                              ? Text(text('No preview', 'ޕްރިވިއުއެއް ނެތް'), style: style())
                              : Image.memory(
                                  previewBytes,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(text('Cancel', 'ކެންސަލް'), style: style()),
          ),
          FilledButton.icon(
            onPressed: previewBytes == null || _loading
                ? null
                : () {
                    Navigator.pop(
                      context,
                      PickedCroppedImage(
                        bytes: previewBytes,
                        fileName: _mode == ImageCropMode.original
                            ? widget.originalFileName
                            : _croppedFileName(widget.originalFileName),
                      ),
                    );
                  },
            icon: const Icon(Icons.crop_rounded),
            label: Text(text('Crop & Set', 'ކްރޮޕް އަދި ސެޓް'), style: style(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _croppedFileName(String originalName) {
    final clean = originalName.trim().isEmpty ? 'image' : originalName.trim();
    final base = clean.contains('.') ? clean.substring(0, clean.lastIndexOf('.')) : clean;
    final safeBase = base.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${safeBase}_cropped.png';
  }
}

Future<Uint8List> cropImageBytes(
  Uint8List bytes, {
  required ImageCropMode mode,
}) async {
  if (mode == ImageCropMode.original) return bytes;

  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;

  final sourceWidth = image.width.toDouble();
  final sourceHeight = image.height.toDouble();
  final targetRatio = switch (mode) {
    ImageCropMode.square => 1.0,
    ImageCropMode.fourThree => 4 / 3,
    ImageCropMode.wide => 16 / 9,
    ImageCropMode.original => sourceWidth / sourceHeight,
  };

  double cropWidth = sourceWidth;
  double cropHeight = cropWidth / targetRatio;

  if (cropHeight > sourceHeight) {
    cropHeight = sourceHeight;
    cropWidth = cropHeight * targetRatio;
  }

  final left = (sourceWidth - cropWidth) / 2;
  final top = (sourceHeight - cropHeight) / 2;
  final sourceRect = ui.Rect.fromLTWH(left, top, cropWidth, cropHeight);

  const maxOutputSide = 1600.0;
  final scale = math.min(1.0, maxOutputSide / math.max(cropWidth, cropHeight));
  final outputWidth = math.max(1, (cropWidth * scale).round());
  final outputHeight = math.max(1, (cropHeight * scale).round());

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final targetRect = ui.Rect.fromLTWH(0, 0, outputWidth.toDouble(), outputHeight.toDouble());

  canvas.drawImageRect(
    image,
    sourceRect,
    targetRect,
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );

  final picture = recorder.endRecording();
  final croppedImage = await picture.toImage(outputWidth, outputHeight);
  final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

  image.dispose();
  croppedImage.dispose();

  if (byteData == null) {
    throw StateError('Could not crop this image. Please try another image.');
  }

  return byteData.buffer.asUint8List();
}
