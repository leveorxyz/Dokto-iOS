//
//  PaymentManager.swift
//  Dokto
//
//  Created by Rupak on 10/24/21.
//

import UIKit
import RaveSDK
import PaystackCheckout
import Stripe
import PayPalCheckout

enum PaymentStatus {
    case success, failure, dismiss
}

class PaymentManager {
    
    var paymentCompletion: ((PaymentStatus) -> ())?
    var paymentSheet : PaymentSheet?
    var paypalButton: PayPalButton?
}

//MARK: FlutterWave related methods
extension PaymentManager: RavePayProtocol {
    
    func checkoutWithFlutterWave() {
        let config = RaveConfig.sharedConfig()
        config.country = "NG" // Country Code
        config.currencyCode = "NGN" // Currency
        config.email = "zahinjason220434@gmail.com" // Customer's email
        config.isStaging = false // Toggle this for staging and live environment
        config.phoneNumber = "081312121212" //Phone number
        config.transcationRef = "ref" // transaction ref
        config.firstName = "Jason"
        config.lastName = "Haque"
        config.meta = [["metaname":"sdk", "metavalue":"ios"]]
        
        config.publicKey = "FLWPUBK_TEST-cef158ec1b1213690fbeeccb930be993-X" //Public key
        config.encryptionKey = "FLWSECK_TEST6207416b757f" //Encryption key
        
        
        let controller = NewRavePayViewController()
        let nav = UINavigationController(rootViewController: controller)
        controller.amount = "120"
        controller.delegate = self
        UIApplication.topViewController()?.present(nav, animated: true)
    }
    
    func tranasctionSuccessful(flwRef: String?, responseData: [String : Any]?) {
        //print("Successfully paid with rave \(flwRef!) \n \(responseData!)")
        guard let response = responseData else{
            return
        }
        
        //request for backend verification
        let body = [
            "transaction_reference" : response["id"] ?? "1234567",
            "id" : "1"
        ]
        verifyPaypalWithBackend(path: Constants.Api.Payment.flutterWave, body: body) { [weak self] success in
            self?.paymentCompletion?(success ? .success : .failure)
        }
    }
    
    func tranasctionFailed(flwRef: String?, responseData: [String : Any]?) {
        print("Failed to pay with rave \(flwRef!) \n \(responseData!)")
        self.paymentCompletion?(.failure)
    }
    
    func onDismiss() {
        print("Rave pay Dismissed")
        self.paymentCompletion?(.dismiss)
    }
}

//MARK: Paystack related methods
extension PaymentManager: CheckoutProtocol {
    
    func checkoutWithPaystack(){
        let paymentParams = TransactionParams(amount: 5000, email: "zahinjason5580@gmail.com", key: "pk_test_713bcb21dc58d4b28153758b43412415d45f7571", currency: .ngn, channels: [.qr, .ussd,.card,.bank,.bankTransfer])
        let checkoutVC = CheckoutViewController(params: paymentParams, delegate: self)
        checkoutVC.navigationItem.title = "Pay with Paystack"
        UIApplication.topViewController()?.present(checkoutVC, animated: true, completion: nil)
    }
    
    func onSuccess(response: TransactionResponse) {
        print("Successfully paid with reference : \(response.reference)")
        
        //request for backend verification
        let body = [
            "transaction_reference" : response.reference,
            "id" : response.id
        ]
        verifyPaypalWithBackend(path: Constants.Api.Payment.paystack, body: body) { [weak self] success in
            self?.paymentCompletion?(success ? .success : .failure)
        }
    }
    
    func onError(error: Error?) {
        print("An error occured : \(error!.localizedDescription)")
        self.paymentCompletion?(.failure)
    }
    
    func onDimissal() {
        print("Pay stack Dismissed")
        self.paymentCompletion?(.dismiss)
    }
}


//MARK: Stripe related methods
extension PaymentManager {
    
    func checkoutWithStripe() {
        // MARK: Start the checkout process
        if let topController = UIApplication.topViewController() {
            self.paymentSheet?.present(from: topController) { [weak self] paymentResult in
                // MARK: Handle the payment result
                switch paymentResult {
                case .completed:
                    print("Your order is confirmed")
                    self?.paymentCompletion?(.success)
                case .canceled:
                    print("Canceled!")
                    self?.paymentCompletion?(.dismiss)
                case .failed(let error):
                    print("Payment failed: \n\(error.localizedDescription)")
                    self?.paymentCompletion?(.failure)
                }
            }
        } else {
            self.paymentCompletion?(.failure)
        }
    }
    
    func prepareStripePayment(_ completion: @escaping(_ success: Bool) -> ()){
        guard let checkoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout") else {
            return
        }
        var request = URLRequest(url: checkoutUrl)
        request.httpMethod = "POST"
        let task = URLSession.shared.dataTask(
            with: request,
            completionHandler: { [weak self] (data, response, error) in
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        as? [String: Any],
                      let customerId = json["customer"] as? String,
                      let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                      let paymentIntentClientSecret = json["paymentIntent"] as? String,
                      let publishableKey = json["publishableKey"] as? String,
                      
                        let self = self
                else {
                    // Handle error
                    completion(false)
                    return
                }
                // MARK: Set your Stripe publishable key - this allows the SDK to make requests to Stripe for your account
                STPAPIClient.shared.publishableKey = publishableKey
                
                // MARK: Create a PaymentSheet instance
                var configuration = PaymentSheet.Configuration()
                configuration.merchantDisplayName = "Dokto"
                //configuration.applePay = .init(
                // merchantId: "com.foo.example", merchantCountryCode: "US")
                configuration.customer = .init(
                    id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
                //configuration.returnURL = "payments-example://stripe-redirect"
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: paymentIntentClientSecret,
                    configuration: configuration)
                
                DispatchQueue.main.async {
                    //self.buyButton.isEnabled = true
                    completion(true)
                }
            })
        task.resume()
    }
}

//MARK: Paypal related methods
extension PaymentManager {
    
    func initiatePaypalButton() {
        self.paypalButton = PayPalButton()
    }
    
    func checkoutWithPaypal() {
        configurePayPalCheckout()
        
        //update delay time
        var delayTime = 1.0
        if self.paypalButton != nil {
            delayTime = 0
        } else {
            self.paypalButton = PayPalButton()
        }
        
        //fire touch event
        DispatchQueue.main.asyncAfter(deadline: .now()+delayTime) {
            self.paypalButton?.sendActions(for: .touchUpInside)
        }
    }
    
    func configurePayPalCheckout() {
        Checkout.setCreateOrderCallback { createOrderAction in
            let amount = PurchaseUnit.Amount(currencyCode: .usd, value: "\(100.0)")
            let purchaseUnit = PurchaseUnit(amount: amount)
            let order = OrderRequest(intent: .capture, purchaseUnits: [purchaseUnit])
            
            createOrderAction.create(order: order)
        }
        
        //show cancel alert
        Checkout.setOnCancelCallback {
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
//                AlertManager.show(title: "You have cancelled your payment")
                self.paymentCompletion?(.dismiss)
            }
        }
        
        Checkout.setOnApproveCallback { approval in
            approval.actions.capture { [weak self] (response, error) in
                if error != nil {
                    debugPrint("Paypal error: Something went wrong, try again later")
                    self?.paymentCompletion?(.failure)
                } else if response?.data.status.lowercased() == "completed" {
                    let body = [
                        "transaction_reference" : "1234567",
                        "id" : "1"
                    ]
                    self?.verifyPaypalWithBackend(path: Constants.Api.Payment.paypal,
                                                  body: body, { success in
                        self?.paymentCompletion?(success ? .success : .failure)
                    })
                } else {
                    self?.paymentCompletion?(.failure)
                }
            }
        }
    }
}

//MARK: Payment verification related methods
extension PaymentManager {
    
    func verifyPaypalWithBackend(path: String, body: [String:Any], _ completion: @escaping(_ success: Bool) -> ()) {
        let request = RMRequestModel()
        request.path = path
        request.body = body
        request.method = .post
        
        RequestManager.request(request: request, type: PaymentResponseDetails.self) { response, error in
            if let _ = response.first {
                debugPrint("Payment verified")
                completion(true)
            } else {
                debugPrint("Payment verification failed")
                completion(false)
            }
        }
    }
}

