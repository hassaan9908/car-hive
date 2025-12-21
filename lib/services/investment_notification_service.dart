import 'package:cloud_firestore/cloud_firestore.dart';

/// Investment Notification Service
/// 
/// Handles notifications for investment-related events
/// TODO: Integrate with Firebase Cloud Messaging for push notifications
class InvestmentNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Notify user about investment event
  Future<void> notifyUser({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? vehicleInvestmentId,
    String? investmentId,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Create notification document
      await _firestore.collection('investment_notifications').add({
        'userId': userId,
        'type': type,
        'title': title,
        'message': message,
        'vehicleInvestmentId': vehicleInvestmentId,
        'investmentId': investmentId,
        'data': data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // TODO: Send push notification via FCM
      // await _sendPushNotification(userId, title, message, data);
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Notify investment created
  Future<void> notifyInvestmentCreated(String vehicleInvestmentId) async {
    // Notify potential investors (could be done via admin or system)
    // For now, we'll just log it
    print('Investment created: $vehicleInvestmentId');
  }

  /// Notify investment made
  Future<void> notifyInvestmentMade({
    required String vehicleInvestmentId,
    required String investorUserId,
    required double amount,
  }) async {
    try {
      // Get vehicle initiator
      final vehicleDoc = await _firestore
          .collection('investment_vehicles')
          .doc(vehicleInvestmentId)
          .get();
      
      if (vehicleDoc.exists) {
        final initiatorId = vehicleDoc.data()?['initiatorUserId'] as String?;
        
        if (initiatorId != null && initiatorId != investorUserId) {
          await notifyUser(
            userId: initiatorId,
            type: 'investment_made',
            title: 'New Investment Received',
            message: 'Someone invested ${amount.toStringAsFixed(0)} PKR in your investment opportunity',
            vehicleInvestmentId: vehicleInvestmentId,
          );
        }
      }
    } catch (e) {
      print('Error notifying investment made: $e');
    }
  }

  /// Notify funding complete
  Future<void> notifyFundingComplete(String vehicleInvestmentId) async {
    try {
      // Get all investors
      final investments = await _firestore
          .collection('investments')
          .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in investments.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) {
          await notifyUser(
            userId: userId,
            type: 'funding_complete',
            title: 'Investment Fully Funded!',
            message: 'The investment opportunity has reached its funding goal',
            vehicleInvestmentId: vehicleInvestmentId,
          );
        }
      }
    } catch (e) {
      print('Error notifying funding complete: $e');
    }
  }

  /// Notify vehicle sold
  Future<void> notifyVehicleSold({
    required String vehicleInvestmentId,
    required double salePrice,
  }) async {
    try {
      // Get all investors
      final investments = await _firestore
          .collection('investments')
          .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in investments.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) {
          await notifyUser(
            userId: userId,
            type: 'vehicle_sold',
            title: 'Vehicle Sold',
            message: 'The vehicle has been sold for ${salePrice.toStringAsFixed(0)} PKR. Profit distribution will begin soon.',
            vehicleInvestmentId: vehicleInvestmentId,
            data: {'salePrice': salePrice},
          );
        }
      }
    } catch (e) {
      print('Error notifying vehicle sold: $e');
    }
  }

  /// Notify profit distributed
  Future<void> notifyProfitDistributed({
    required String userId,
    required String vehicleInvestmentId,
    required double profitAmount,
  }) async {
    await notifyUser(
      userId: userId,
      type: 'profit_distributed',
      title: 'Profit Distributed',
      message: 'You received ${profitAmount.toStringAsFixed(0)} PKR in profit distribution',
      vehicleInvestmentId: vehicleInvestmentId,
      data: {'profitAmount': profitAmount},
    );
  }

  /// Notify shares listed
  Future<void> notifySharesListed({
    required String vehicleInvestmentId,
    required double sharePercentage,
    required double askingPrice,
  }) async {
    // Notify potential buyers (could be all users or interested users)
    // For now, we'll just log it
    print('Shares listed: $sharePercentage% at $askingPrice PKR');
  }

  /// Notify shares sold
  Future<void> notifySharesSold({
    required String sellerUserId,
    required String buyerUserId,
    required String vehicleInvestmentId,
    required double soldPrice,
  }) async {
    // Notify seller
    await notifyUser(
      userId: sellerUserId,
      type: 'shares_sold',
      title: 'Shares Sold',
      message: 'Your shares have been sold for ${soldPrice.toStringAsFixed(0)} PKR',
      vehicleInvestmentId: vehicleInvestmentId,
      data: {'soldPrice': soldPrice},
    );

    // Notify buyer
    await notifyUser(
      userId: buyerUserId,
      type: 'shares_purchased',
      title: 'Shares Purchased',
      message: 'You have successfully purchased shares',
      vehicleInvestmentId: vehicleInvestmentId,
      data: {'purchasePrice': soldPrice},
    );
  }

  /// Notify deadline approaching
  Future<void> notifyDeadlineApproaching({
    required String vehicleInvestmentId,
    required DateTime deadline,
  }) async {
    try {
      // Get initiator
      final vehicleDoc = await _firestore
          .collection('investment_vehicles')
          .doc(vehicleInvestmentId)
          .get();
      
      if (vehicleDoc.exists) {
        final initiatorId = vehicleDoc.data()?['initiatorUserId'] as String?;
        
        if (initiatorId != null) {
          final daysLeft = deadline.difference(DateTime.now()).inDays;
          await notifyUser(
            userId: initiatorId,
            type: 'deadline_approaching',
            title: 'Deadline Approaching',
            message: 'Your investment opportunity expires in $daysLeft days',
            vehicleInvestmentId: vehicleInvestmentId,
          );
        }
      }

      // Get all investors
      final investments = await _firestore
          .collection('investments')
          .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
          .where('status', isEqualTo: 'active')
          .get();

      final daysLeft = deadline.difference(DateTime.now()).inDays;
      for (final doc in investments.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) {
          await notifyUser(
            userId: userId,
            type: 'deadline_approaching',
            title: 'Investment Deadline Approaching',
            message: 'The investment opportunity expires in $daysLeft days',
            vehicleInvestmentId: vehicleInvestmentId,
          );
        }
      }
    } catch (e) {
      print('Error notifying deadline approaching: $e');
    }
  }

  /// Notify investment expired
  Future<void> notifyInvestmentExpired(String vehicleInvestmentId) async {
    try {
      // Get all investors
      final investments = await _firestore
          .collection('investments')
          .where('vehicleInvestmentId', isEqualTo: vehicleInvestmentId)
          .where('status', isEqualTo: 'active')
          .get();

      for (final doc in investments.docs) {
        final userId = doc.data()['userId'] as String?;
        if (userId != null) {
          await notifyUser(
            userId: userId,
            type: 'investment_expired',
            title: 'Investment Expired',
            message: 'The investment opportunity has expired. Refunds will be processed.',
            vehicleInvestmentId: vehicleInvestmentId,
          );
        }
      }
    } catch (e) {
      print('Error notifying investment expired: $e');
    }
  }

  /// Get user notifications
  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('investment_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('investment_notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Mark all notifications as read for user
  Future<void> markAllAsRead(String userId) async {
    final notifications = await _firestore
        .collection('investment_notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}

