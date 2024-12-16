import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

final List<String> malaysianStates = [
  'Johor',
  'Kedah',
  'Kelantan',
  'Melaka',
  'Negeri Sembilan',
  'Pahang',
  'Perak',
  'Perlis',
  'Pulau Pinang',
  'Sabah',
  'Sarawak',
  'Selangor',
  'Terengganu',
  'Wilayah Persekutuan'
];

// Capture image
Future<XFile?> pickImage() async {
  final ImagePicker picker = ImagePicker();
  try {
    return await picker.pickImage(source: ImageSource.camera);
  } catch (_) {
    return await picker.pickImage(source: ImageSource.gallery);
  }
}

// Extract text from image
Future<String> extractTextFromImage(XFile image) async {
  final inputImage = InputImage.fromFilePath(image.path);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final recognizedText = await textRecognizer.processImage(inputImage);
  await textRecognizer.close();

  return recognizedText.text;
}

// Extract name
String extractName(List<String> lines) {
  for (String line in lines) {
    final cleanLine = line.trim();

    // Skip lines with known non-name patterns
    if (cleanLine.isEmpty ||
        cleanLine.toUpperCase().contains('KAD PENGENALAN') ||
        RegExp(r'^[A-Z]+[0-9]+$').hasMatch(cleanLine)) {
      continue;
    }

    // Match lines that resemble full names
    if (RegExp(r'^[A-Za-z\s]+(?: bin | binti )?[A-Za-z\s]+$',
            caseSensitive: false)
        .hasMatch(cleanLine)) {
      return cleanLine;
    }
  }
  return 'Name not found';
}

// Extract address
String extractAddress(List<String> lines) {
  List<String> addressLines = [];
  bool isAddressSection = false;

  for (String line in lines) {
    final cleanLine = line.trim();

    // Start address section after IC number
    if (!isAddressSection) {
      if (cleanLine.contains(RegExp(r'\d{6}-\d{2}-\d{4}'))) {
        isAddressSection = true;
        continue;
      }
    } else {
      // Add lines to address until a state or postal code is found
      final containsState = malaysianStates.any(
        (state) => cleanLine.toLowerCase().contains(state.toLowerCase()),
      );
      final containsPostalCode = RegExp(r'\b\d{5}\b').hasMatch(cleanLine);

      if (containsState || containsPostalCode) {
        addressLines.add(cleanLine);
        break;
      }

      // Collect other valid address lines
      if (cleanLine.length > 5) {
        addressLines.add(cleanLine);
      }
    }
  }

  return addressLines.isNotEmpty
      ? addressLines.join(', ').trim()
      : 'Address not found';
}

// Parse MyKad data
Map<String, String> parseMyKadData(String extractedText) {
  final icNumberRegex = RegExp(r'\b\d{6}-\d{2}-\d{4}\b');

  String extractICNumber(String text) =>
      icNumberRegex.firstMatch(text)?.group(0) ?? 'IC Number not found';

  String deriveDOBFromIC(String icNumber) {
    if (icNumber.length == 14) {
      final year = icNumber.substring(0, 2);
      final month = icNumber.substring(2, 4);
      final day = icNumber.substring(4, 6);
      final prefix = int.parse(year) > 30 ? '19' : '20';
      return '$day-$month-$prefix$year';
    }
    return 'Invalid DOB';
  }

  final lines = extractedText.split('\n');
  return {
    'name': extractName(lines),
    'icNumber': extractICNumber(extractedText),
    'dob': deriveDOBFromIC(extractICNumber(extractedText)),
    'address': extractAddress(lines),
  };
}

// Scan and populate MyKad information to form fields
Future<void> scanAndPopulateMyKad(
    BuildContext context,
    TextEditingController nameController,
    TextEditingController icNumberController,
    TextEditingController dobController,
    TextEditingController addressController) async {
  try {
    final XFile? image = await pickImage();
    if (image != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      final extractedText = await extractTextFromImage(image);
      final data = parseMyKadData(extractedText);

      nameController.text = data['name'] ?? '';
      icNumberController.text = data['icNumber'] ?? '';
      dobController.text = data['dob'] ?? '';
      addressController.text = data['address'] ?? '';

      Navigator.of(context).pop(); // Remove loading indicator

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('MyKad data extracted successfully!')),
      );
    }
  } catch (e) {
    Navigator.of(context).pop(); // Ensure loading indicator is removed

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error extracting MyKad data: $e')),
    );
  }
}
