import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart' show kDebugMode;

/// Service for encrypting and decrypting sensitive vehicle data
/// 
/// This service uses AES encryption to protect sensitive personal information
/// like registration numbers, chassis numbers, and owner names.
class EncryptionService {
  // Encryption key - In production, this should be stored securely
  // For now, using a fixed key derived from a passphrase
  // In production, consider using Flutter Secure Storage or similar
  static String get _encryptionKey {
    // Generate a consistent key from a passphrase
    // In production, this should be stored securely or generated per user
    const passphrase = 'carhive_vehicle_verification_2024';
    final bytes = utf8.encode(passphrase);
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 32); // AES-256 requires 32 bytes
  }

  static encrypt.IV get _iv {
    // Generate a consistent IV from a passphrase
    // In production, consider storing IV separately or generating per encryption
    const ivPassphrase = 'carhive_iv_2024';
    final bytes = utf8.encode(ivPassphrase);
    final hash = sha256.convert(bytes);
    return encrypt.IV.fromBase64(base64Encode(hash.bytes.take(16).toList()));
  }

  /// Encrypts sensitive vehicle data
  /// 
  /// [data] - The plain text data to encrypt
  /// 
  /// Returns base64 encoded encrypted string
  static String encryptData(String data) {
    if (data.isEmpty) return '';
    
    try {
      final key = encrypt.Key.fromBase64(base64Encode(utf8.encode(_encryptionKey)));
      final iv = _iv;
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      final encrypted = encrypter.encrypt(data, iv: iv);
      return encrypted.base64;
    } catch (e) {
      if (kDebugMode) {
        print('Encryption error: $e');
      }
      // If encryption fails, return empty string (don't store unencrypted data)
      return '';
    }
  }

  /// Decrypts sensitive vehicle data
  /// 
  /// [encryptedData] - The base64 encoded encrypted string
  /// 
  /// Returns the decrypted plain text
  static String decryptData(String encryptedData) {
    if (encryptedData.isEmpty) return '';
    
    try {
      final key = encrypt.Key.fromBase64(base64Encode(utf8.encode(_encryptionKey)));
      final iv = _iv;
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      if (kDebugMode) {
        print('Decryption error: $e');
      }
      return '';
    }
  }

  /// Encrypts a map of sensitive fields
  /// 
  /// [data] - Map containing sensitive fields
  /// 
  /// Returns a new map with encrypted values
  static Map<String, dynamic> encryptFields(Map<String, dynamic> data) {
    final encrypted = <String, dynamic>{};
    
    // Fields that should be encrypted
    const sensitiveFields = [
      'registrationNo',
      'registrationDate',
      'chassisNo',
      'ownerName',
    ];
    
    data.forEach((key, value) {
      if (sensitiveFields.contains(key) && value is String && value.isNotEmpty) {
        encrypted[key] = encryptData(value);
        encrypted['${key}_encrypted'] = true; // Flag to indicate encryption
      } else {
        encrypted[key] = value;
      }
    });
    
    return encrypted;
  }

  /// Decrypts a map of sensitive fields
  /// 
  /// [data] - Map containing encrypted fields
  /// 
  /// Returns a new map with decrypted values
  static Map<String, dynamic> decryptFields(Map<String, dynamic> data) {
    final decrypted = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (key.endsWith('_encrypted')) {
        // Skip the encryption flag
        return;
      }
      
      final encryptedFlag = data['${key}_encrypted'];
      if (encryptedFlag == true && value is String && value.isNotEmpty) {
        decrypted[key] = decryptData(value);
      } else {
        decrypted[key] = value;
      }
    });
    
    return decrypted;
  }

  /// Generates a one-way hash of the registration number for duplicate checking
  /// 
  /// This hash is used to check for duplicate ads without exposing the actual
  /// registration number. The hash is one-way, so the original value cannot
  /// be recovered from it.
  /// 
  /// [registrationNo] - The registration number to hash
  /// 
  /// Returns a SHA-256 hash as a hex string
  static String hashRegistrationNo(String registrationNo) {
    if (registrationNo.isEmpty) return '';
    
    // Normalize the registration number (uppercase, remove asterisk, trim)
    final normalized = registrationNo
        .trim()
        .toUpperCase()
        .replaceAll('*', '');
    
    // Generate SHA-256 hash
    final bytes = utf8.encode(normalized);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
}

