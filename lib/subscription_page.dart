import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String subscriptionId = 'tbcure_1m_50'; // <-- replace with your real product id
final Set<String> _kIds = <String>{subscriptionId};

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _purchasePending = false;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    // 1) Check local subscription state
    await _checkSubscriptionStatus();

    // 2) Listen to purchase updates
    _purchaseSub = _inAppPurchase.purchaseStream.listen(
      _listenToPurchaseUpdated,
      onError: (err) => debugPrint('purchaseStream error: $err'),
    );

    // 3) Init store (queries products)
    await _initStoreInfo();

    // 4) Attempt restore (detects already purchased subscriptions)
    // Note: this will produce events on the purchaseStream which we listen to above.
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Error calling restorePurchases: $e');
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }

  /// Check persisted subscription flag
  Future<void> _checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final subscribed = prefs.getBool('isSubscribed') ?? false;
    if (subscribed) {
      // Already subscribed — go to next screen
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, '/roleSelection');
        });
      }
    } else {
      setState(() => _isSubscribed = false);
    }
  }

  /// Query product info
  Future<void> _initStoreInfo() async {
    setState(() => _loading = true);

    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      debugPrint('In-app purchases not available');
      setState(() => _loading = false);
      return;
    }

    final response = await _inAppPurchase.queryProductDetails(_kIds);
    if (response.error != null) {
      debugPrint('ProductDetailsResponse error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products not found: ${response.notFoundIDs}');
    }

    setState(() {
      _products = response.productDetails;
      _loading = false;
    });
  }

  /// Purchase stream handler
  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          setState(() => _purchasePending = true);
          debugPrint('Purchase pending: ${purchase.productID}');
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
        // IMPORTANT: Verify purchase with your server before granting access.
          await _handleVerifiedPurchase(purchase);
          break;

        case PurchaseStatus.error:
          setState(() => _purchasePending = false);
          debugPrint('Purchase error: ${purchase.error}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Purchase error: ${purchase.error?.message ?? 'Unknown'}')),
            );
          }
          break;

        default:
          break;
      }

      // Complete the purchase (after verification/handling)
      if (purchase.pendingCompletePurchase) {
        try {
          await _inAppPurchase.completePurchase(purchase);
        } catch (e) {
          debugPrint('Error completing purchase: $e');
        }
      }
    }
  }

  /// Verification + local persist of subscription
  Future<void> _handleVerifiedPurchase(PurchaseDetails purchase) async {
    debugPrint('Received purchase to verify: ${purchase.productID}');

    // TODO: send purchase.verificationData.serverVerificationData (or purchaseToken)
    // to your backend and validate against Google Play / App Store servers.
    // Only mark subscription active if server verifies the token.
    //
    // Example: POST /verify { userId, productId, receipt/purchaseToken }
    //
    // For testing/local only (NOT secure): mark as subscribed immediately.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSubscribed', true);

    setState(() {
      _purchasePending = false;
      _isSubscribed = true;
    });

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/roleSelection');
    }
  }

  /// Start purchase flow
  Future<void> _buySubscription() async {
    if (_isSubscribed) {
      // Already subscribed locally — no need to buy again.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already subscribed.')),
      );
      return;
    }

    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subscription not available at the moment.')),
      );
      return;
    }

    final product = _products.firstWhere((p) => p.id == subscriptionId, orElse: () => _products.first);
    final purchaseParam = PurchaseParam(productDetails: product);

    setState(() => _purchasePending = true);

    try {
      // If your plugin version supports buySubscription, prefer that:
      // await _inAppPurchase.buySubscription(purchaseParam: purchaseParam);
      //
      // Fallback (works on many versions):
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error initiating purchase: $e');
      setState(() => _purchasePending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not start purchase. Try again later.')),
        );
      }
    }
  }

  /// Manual restore button (users like this)
  Future<void> _restorePurchases() async {
    setState(() => _purchasePending = true);
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      debugPrint('Restore failed: $e');
      setState(() => _purchasePending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore failed.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final priceText = (_products.isNotEmpty) ? "Subscribe Now (${_products.first.price})" : "Subscribe Now";

    return Scaffold(
      appBar: AppBar(title: const Text('Subscribe to Continue')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Welcome to TbCure!\n\nSubscribe to unlock all features and continue using the app.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 30),
              if (_purchasePending) const CircularProgressIndicator(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_purchasePending || _isSubscribed) ? null : _buySubscription,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: Text(_isSubscribed ? 'Subscribed' : priceText),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _purchasePending ? null : _restorePurchases,
                child: const Text('Restore purchases'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}