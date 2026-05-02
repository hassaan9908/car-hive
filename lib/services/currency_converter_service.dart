/// Currency conversion service
/// 
/// Handles conversion between PKR (Pakistani Rupee) and USD (US Dollar)
/// for Stripe payments
class CurrencyConverterService {
  // PKR to USD conversion rate
  // Update this rate as needed (current approximate rate: 1 USD = 280 PKR)
  // You can fetch this from an API or update manually
  static const double _pkrToUsdRate = 280.0;
  
  // USD to PKR conversion rate (inverse)
  static const double _usdToPkrRate = 1.0 / _pkrToUsdRate;

  /// Get current PKR to USD conversion rate
  static double get pkrToUsdRate => _pkrToUsdRate;

  /// Get current USD to PKR conversion rate
  static double get usdToPkrRate => _usdToPkrRate;

  /// Convert PKR amount to USD
  /// 
  /// [pkrAmount] - Amount in Pakistani Rupees
  /// Returns amount in US Dollars (rounded to 2 decimal places)
  static double convertPkrToUsd(double pkrAmount) {
    if (pkrAmount <= 0) return 0.0;
    final usdAmount = pkrAmount / _pkrToUsdRate;
    // Round to 2 decimal places (cents)
    return double.parse(usdAmount.toStringAsFixed(2));
  }

  /// Convert USD amount to PKR
  /// 
  /// [usdAmount] - Amount in US Dollars
  /// Returns amount in Pakistani Rupees (rounded to 2 decimal places)
  static double convertUsdToPkr(double usdAmount) {
    if (usdAmount <= 0) return 0.0;
    final pkrAmount = usdAmount * _pkrToUsdRate;
    // Round to 2 decimal places
    return double.parse(pkrAmount.toStringAsFixed(2));
  }

  /// Format currency amount for display
  /// 
  /// [amount] - Amount to format
  /// [currency] - Currency code ('PKR' or 'USD')
  /// [showSymbol] - Whether to show currency symbol
  static String formatCurrency(
    double amount, {
    String currency = 'PKR',
    bool showSymbol = true,
  }) {
    final formatted = amount.toStringAsFixed(2);
    if (showSymbol) {
      if (currency.toUpperCase() == 'USD') {
        return '\$$formatted';
      } else {
        return '$formatted PKR';
      }
    }
    return formatted;
  }

  /// Get formatted currency pair (PKR and USD)
  /// 
  /// [pkrAmount] - Amount in PKR
  /// Returns formatted string showing both currencies
  static String getCurrencyPair(double pkrAmount) {
    final usdAmount = convertPkrToUsd(pkrAmount);
    return '${formatCurrency(pkrAmount, currency: 'PKR')} (${formatCurrency(usdAmount, currency: 'USD')})';
  }
}

