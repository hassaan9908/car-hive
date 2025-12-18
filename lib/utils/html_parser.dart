/// Utility class for parsing HTML responses from the vehicle registration API
/// 
/// This parser extracts information from HTML responses and checks for
/// specific messages like "NO RECORD FOUND".
class HtmlParser {
  /// Checks if the HTML response contains the "NO RECORD FOUND" message
  /// 
  /// [html] - The HTML string to check
  /// 
  /// Returns true if "NO RECORD FOUND" is present (case-insensitive)
  static bool isNoRecord(String html) {
    if (html.isEmpty) return false;
    
    // Convert to uppercase for case-insensitive comparison
    final upperHtml = html.toUpperCase();
    
    // Check for the "NO RECORD FOUND" message
    return upperHtml.contains('NO RECORD FOUND') ||
           upperHtml.contains('NO RECORD FOUND.') ||
           upperHtml.contains('NO RECORD FOUND. PLEASE CONTACT');
  }

  /// Extracts a vehicle field value from HTML based on a label
  /// 
  /// This is a future-proof method that can extract values from HTML
  /// even if the API response format changes in the future.
  /// 
  /// [html] - The HTML string to parse
  /// [label] - The label to search for (e.g., "Registration No", "Owner Name")
  /// 
  /// Returns the extracted value or empty string if not found
  static String extractVehicleField(String html, String label) {
    if (html.isEmpty || label.isEmpty) return '';

    try {
      // Normalize the HTML for easier parsing
      final normalizedHtml = html.replaceAll(RegExp(r'\s+'), ' ');

      // Pattern 1: Look for label followed by colon or dash, then value
      // Example: "Registration No: ABC-123" or "Owner Name - John Doe"
      final pattern1 = RegExp(
        '${RegExp.escape(label)}\\s*[:\\-]\\s*([^<\\n]+)',
        caseSensitive: false,
      );
      final match1 = pattern1.firstMatch(normalizedHtml);
      if (match1 != null && match1.groupCount >= 1) {
        final value = match1.group(1)?.trim() ?? '';
        if (value.isNotEmpty) {
          return _cleanValue(value);
        }
      }

      // Pattern 2: Look for label in <td> or <th> followed by value in next <td>
      // Example: <td>Registration No</td><td>ABC-123</td>
      final pattern2 = RegExp(
        '<t[dh][^>]*>\\s*${RegExp.escape(label)}\\s*</t[dh]>\\s*<t[dh][^>]*>\\s*([^<]+)',
        caseSensitive: false,
      );
      final match2 = pattern2.firstMatch(normalizedHtml);
      if (match2 != null && match2.groupCount >= 1) {
        final value = match2.group(1)?.trim() ?? '';
        if (value.isNotEmpty) {
          return _cleanValue(value);
        }
      }

      // Pattern 3: Look for label in <label> or <strong> followed by value
      // Example: <label>Registration No</label> ABC-123
      final pattern3 = RegExp(
        '<(?:label|strong|b)[^>]*>\\s*${RegExp.escape(label)}\\s*</(?:label|strong|b)>\\s*([^<\\n]+)',
        caseSensitive: false,
      );
      final match3 = pattern3.firstMatch(normalizedHtml);
      if (match3 != null && match3.groupCount >= 1) {
        final value = match3.group(1)?.trim() ?? '';
        if (value.isNotEmpty) {
          return _cleanValue(value);
        }
      }

      // Pattern 4: Look for label:value pattern in plain text
      // Example: "Registration No:ABC-123"
      final pattern4 = RegExp(
        '${RegExp.escape(label)}\\s*[:=]\\s*([^<\\n\\r]+)',
        caseSensitive: false,
      );
      final match4 = pattern4.firstMatch(normalizedHtml);
      if (match4 != null && match4.groupCount >= 1) {
        final value = match4.group(1)?.trim() ?? '';
        if (value.isNotEmpty) {
          return _cleanValue(value);
        }
      }

      return '';
    } catch (e) {
      // Return empty string if parsing fails
      return '';
    }
  }

  /// Cleans extracted values by removing extra whitespace and HTML entities
  /// 
  /// [value] - The raw extracted value
  /// 
  /// Returns the cleaned value
  static String _cleanValue(String value) {
    if (value.isEmpty) return '';

    // Remove HTML entities
    String cleaned = value
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    // Remove extra whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Remove common prefixes/suffixes that might be artifacts
    cleaned = cleaned.replaceAll(RegExp(r'^[:\\-]\s*'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s*[:\\-]$'), '');

    return cleaned;
  }

  /// Extracts all potential vehicle fields from HTML
  /// 
  /// This method extracts vehicle data from HTML tables and other structures.
  /// It handles various HTML formats that the API might return.
  /// 
  /// Based on the API response, these are the exact fields returned:
  /// 1. REGISTRATION NO
  /// 2. REGISTRATION DATE
  /// 3. CHASSIS NO
  /// 4. ENGINE NO
  /// 5. BODYTYPE
  /// 6. MAKER-MAKE
  /// 7. COLOR
  /// 8. ENGINE SIZE
  /// 9. PURCHASE DATE
  /// 10. VEHICLE VALUE
  /// 11. YEAR OF MANUFACTURE
  /// 12. PURCHASE TYPE
  /// 13. OWNER NAME
  /// 14. TAX PAID UPTO
  /// 15. VEHICLE STATUS
  /// 
  /// [html] - The HTML string to parse
  /// 
  /// Returns a map of field names to values
  static Map<String, String> extractAllFields(String html) {
    final Map<String, String> fields = {};

    // First, try to extract from HTML tables (most common format)
    final tableFields = _extractFromTable(html);
    if (tableFields.isNotEmpty) {
      fields.addAll(tableFields);
    }

    // Exact fields that the API returns (in order of priority)
    final apiFields = [
      'REGISTRATION NO',
      'REGISTRATION DATE',
      'CHASSIS NO',
      'ENGINE NO',
      'BODYTYPE',
      'MAKER-MAKE',
      'MAKER MAKE',
      'MAKE',
      'COLOR',
      'COLOUR',
      'ENGINE SIZE',
      'PURCHASE DATE',
      'VEHICLE VALUE',
      'YEAR OF MANUFACTURE',
      'PURCHASE TYPE',
      'OWNER NAME',
      'TAX PAID UPTO',
      'TAX PAID UP TO',
      'VEHICLE STATUS',
      'STATUS',
    ];

    // Try exact API field names first
    for (final field in apiFields) {
      final value = extractVehicleField(html, field);
      if (value.isNotEmpty) {
        // Normalize field name for display
        final normalizedName = _normalizeApiFieldName(field);
        if (!fields.containsKey(normalizedName)) {
          fields[normalizedName] = value;
        }
      }
    }

    // Also try common variations as fallback
    final commonFields = [
      'Registration No',
      'Registration Number',
      'Reg No',
      'Registration Date',
      'Reg Date',
      'Owner Name',
      'Owner',
      'Chassis No',
      'Chassis Number',
      'Engine No',
      'Engine Number',
      'Body Type',
      'Bodytype',
      'Make',
      'Model',
      'Color',
      'Colour',
      'Engine Size',
      'Purchase Date',
      'Vehicle Value',
      'Year of Manufacture',
      'Manufacturing Year',
      'Purchase Type',
      'Tax Paid Upto',
      'Tax Paid Up To',
      'Vehicle Status',
    ];

    for (final field in commonFields) {
      final value = extractVehicleField(html, field);
      if (value.isNotEmpty) {
        final normalizedName = _normalizeApiFieldName(field);
        if (!fields.containsKey(normalizedName)) {
          fields[normalizedName] = value;
        }
      }
    }

    return fields;
  }

  /// Normalizes API field names to display-friendly format
  /// 
  /// [field] - The raw field name from API
  /// 
  /// Returns a normalized field name for display
  static String _normalizeApiFieldName(String field) {
    final normalized = field.toUpperCase().trim();
    
    // Map to display-friendly names
    final fieldMap = {
      'REGISTRATION NO': 'Registration No',
      'REGISTRATION DATE': 'Registration Date',
      'CHASSIS NO': 'Chassis No',
      'ENGINE NO': 'Engine No',
      'BODYTYPE': 'Body Type',
      'MAKER-MAKE': 'Maker/Make',
      'MAKER MAKE': 'Maker/Make',
      'MAKE': 'Maker/Make',
      'COLOR': 'Color',
      'COLOUR': 'Color',
      'ENGINE SIZE': 'Engine Size',
      'PURCHASE DATE': 'Purchase Date',
      'VEHICLE VALUE': 'Vehicle Value',
      'YEAR OF MANUFACTURE': 'Year of Manufacture',
      'PURCHASE TYPE': 'Purchase Type',
      'OWNER NAME': 'Owner Name',
      'TAX PAID UPTO': 'Tax Paid Upto',
      'TAX PAID UP TO': 'Tax Paid Upto',
      'VEHICLE STATUS': 'Vehicle Status',
      'STATUS': 'Vehicle Status',
    };

    // Check exact match first
    if (fieldMap.containsKey(normalized)) {
      return fieldMap[normalized]!;
    }

    // Check case-insensitive match
    for (final entry in fieldMap.entries) {
      if (normalized == entry.key.toUpperCase()) {
        return entry.value;
      }
    }

    // If no mapping found, capitalize properly
    final words = field.split(RegExp(r'[\s\-_]+'));
    final capitalized = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    return capitalized;
  }

  /// Extracts vehicle data from HTML tables
  /// 
  /// This method looks for common table structures in HTML and extracts
  /// key-value pairs from table rows.
  /// 
  /// [html] - The HTML string to parse
  /// 
  /// Returns a map of field names to values
  static Map<String, String> _extractFromTable(String html) {
    final Map<String, String> fields = {};
    
    if (html.isEmpty) return fields;

    try {
      // Pattern 1: Extract from <tr><td>Label</td><td>Value</td></tr>
      // This is the most common table format
      final tableRowPattern = RegExp(
        r'<tr[^>]*>.*?<t[dh][^>]*>([^<]+)</t[dh]>.*?<t[dh][^>]*>([^<]+)</t[dh]>.*?</tr>',
        caseSensitive: false,
        dotAll: true,
      );

      final matches = tableRowPattern.allMatches(html);
      for (final match in matches) {
        if (match.groupCount >= 2) {
          final label = _cleanValue(match.group(1) ?? '');
          final value = _cleanValue(match.group(2) ?? '');
          
          if (label.isNotEmpty && value.isNotEmpty && 
              value.length < 200 && // Avoid capturing large HTML blocks
              !value.toLowerCase().contains('placeholder') && // Skip placeholder text
              !value.toLowerCase().contains('enter')) { // Skip "Enter..." text
            // Normalize label
            final normalizedLabel = _normalizeLabel(label);
            if (normalizedLabel.isNotEmpty) {
              fields[normalizedLabel] = value;
            }
          }
        }
      }

      // Pattern 2: Extract from <td>Label:</td><td>Value</td>
      final tdPattern = RegExp(
        r'<t[dh][^>]*>([^:<]+):?\s*</t[dh]>.*?<t[dh][^>]*>([^<]+)</t[dh]>',
        caseSensitive: false,
        dotAll: true,
      );

      final tdMatches = tdPattern.allMatches(html);
      for (final match in tdMatches) {
        if (match.groupCount >= 2) {
          final label = _cleanValue(match.group(1) ?? '');
          final value = _cleanValue(match.group(2) ?? '');
          
          if (label.isNotEmpty && value.isNotEmpty && 
              value.length < 200 && // Avoid capturing large HTML blocks
              !value.toLowerCase().contains('placeholder') && // Skip placeholder text
              !value.toLowerCase().contains('enter')) { // Skip "Enter..." text
            final normalizedLabel = _normalizeLabel(label);
            if (normalizedLabel.isNotEmpty && !fields.containsKey(normalizedLabel)) {
              fields[normalizedLabel] = value;
            }
          }
        }
      }

      // Pattern 3: Extract from div or span structures
      // <div><strong>Label:</strong> Value</div>
      final divPattern = RegExp(
        r'<(?:div|p|span)[^>]*>.*?<(?:strong|b)[^>]*>([^<]+):?\s*</(?:strong|b)>[^<]*([^<]+)',
        caseSensitive: false,
        dotAll: true,
      );

      final divMatches = divPattern.allMatches(html);
      for (final match in divMatches) {
        if (match.groupCount >= 2) {
          final label = _cleanValue(match.group(1) ?? '');
          final value = _cleanValue(match.group(2) ?? '');
          
          if (label.isNotEmpty && value.isNotEmpty && 
              value.length < 200 && // Avoid capturing large HTML blocks
              !value.toLowerCase().contains('placeholder') && // Skip placeholder text
              !value.toLowerCase().contains('enter')) { // Skip "Enter..." text
            final normalizedLabel = _normalizeLabel(label);
            if (normalizedLabel.isNotEmpty && !fields.containsKey(normalizedLabel)) {
              fields[normalizedLabel] = value;
            }
          }
        }
      }

    } catch (e) {
      // If parsing fails, return empty map
      return {};
    }

    return fields;
  }

  /// Normalizes field labels to standard names
  /// 
  /// [label] - The raw label from HTML
  /// 
  /// Returns a normalized label name matching the API's exact field names
  static String _normalizeLabel(String label) {
    if (label.isEmpty) return '';
    
    final normalized = label.trim().toUpperCase();
    
    // Map to the exact API field names (15 fields)
    final labelMap = {
      'REGISTRATION NO': 'Registration No',
      'REG NO': 'Registration No',
      'REGISTRATION NUMBER': 'Registration No',
      'REGISTRATION DATE': 'Registration Date',
      'REG DATE': 'Registration Date',
      'CHASSIS NO': 'Chassis No',
      'CHASSIS NUMBER': 'Chassis No',
      'CHASSIS': 'Chassis No',
      'ENGINE NO': 'Engine No',
      'ENGINE NUMBER': 'Engine No',
      'ENGINE': 'Engine No',
      'BODYTYPE': 'Body Type',
      'BODY TYPE': 'Body Type',
      'MAKER-MAKE': 'Maker/Make',
      'MAKER MAKE': 'Maker/Make',
      'MAKE': 'Maker/Make',
      'MAKER': 'Maker/Make',
      'COLOR': 'Color',
      'COLOUR': 'Color',
      'ENGINE SIZE': 'Engine Size',
      'PURCHASE DATE': 'Purchase Date',
      'VEHICLE VALUE': 'Vehicle Value',
      'VALUE': 'Vehicle Value',
      'YEAR OF MANUFACTURE': 'Year of Manufacture',
      'MANUFACTURING YEAR': 'Year of Manufacture',
      'YEAR': 'Year of Manufacture',
      'PURCHASE TYPE': 'Purchase Type',
      'OWNER NAME': 'Owner Name',
      'OWNER': 'Owner Name',
      'TAX PAID UPTO': 'Tax Paid Upto',
      'TAX PAID UP TO': 'Tax Paid Upto',
      'TAX': 'Tax Paid Upto',
      'VEHICLE STATUS': 'Vehicle Status',
      'STATUS': 'Vehicle Status',
    };

    // Check if we have a mapping
    if (labelMap.containsKey(normalized)) {
      return labelMap[normalized]!;
    }

    // Try case-insensitive match
    for (final entry in labelMap.entries) {
      if (normalized == entry.key.toUpperCase()) {
        return entry.value;
      }
    }

    // If no mapping, capitalize first letter of each word
    final words = normalized.toLowerCase().split(RegExp(r'[\s\-_]+'));
    final capitalized = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    return capitalized;
  }
}


