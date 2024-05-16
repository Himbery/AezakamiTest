//
//  ViewController.swift
//  AuthTestApp
//
//  Created by Marina Zeylan on 13.05.2024.
//

import UIKit
import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import FirebaseAuth
import FirebaseCore
import SVProgressHUD

class MainViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var mailField: UITextField!
    @IBOutlet weak var passLabel: UILabel!
    @IBOutlet weak var passField: UITextField!
    @IBOutlet weak var authBtn: UIButton!
    @IBOutlet weak var googleSignBtn: GIDSignInButton!
    
    var handle: AuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Auth.auth().currentUser != nil {
            self.performSegue(withIdentifier: "toEditor", sender: self)
        }
        
        self.mailField.delegate = self
        self.passField.delegate = self
        
        titleLabel.text = "Вход"
        mailLabel.text = "Введите адрес электронной почты"
        passLabel.text = "Введите пароль"
        
        authBtn.setTitle("Войти", for: .normal)
        authBtn.layer.cornerRadius = 10
        authBtn.layer.masksToBounds = true
        authBtn.layer.borderWidth = 1
        authBtn.layer.borderColor = UIColor.blueMain.cgColor
        
        mailField.layer.cornerRadius = 10
        mailField.layer.masksToBounds = true
        mailField.layer.borderWidth = 1
        mailField.layer.borderColor = UIColor.blueMain.cgColor
        passField.layer.cornerRadius = 10
        passField.layer.masksToBounds = true
        passField.layer.borderWidth = 1
        passField.layer.borderColor = UIColor.blueMain.cgColor
        
        mailField.placeholder = "email"
        passField.placeholder = "password"
        
        
        authBtn.isEnabled = false
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        handle = Auth.auth().addStateDidChangeListener { auth, user in
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Auth.auth().removeStateDidChangeListener(handle!)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
            if reason == .committed {
                textFieldDidChange()
            }
        }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == passField, let text = textField.text, !text.isEmpty {
            if let text = mailField.text, !text.isEmpty {
                authBtn.isEnabled = true
                authBtn.setTitleColor(.white, for: .normal)
                authBtn.backgroundColor = UIColor.blueMain
            }
        }
        return true
    }
    
    func textFieldDidChange() {
        guard let password = passField.text, !password.isEmpty, let email = mailField.text, !email.isEmpty else {
            authBtn.setTitleColor(UIColor.blueMain, for: UIControl.State.normal)
            authBtn.isEnabled = false
            return
        }
        authBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        authBtn.backgroundColor = UIColor.blueMain
        authBtn.isEnabled = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    
    @IBAction func resetPassword(_ sender: UIButton) {
        SVProgressHUD.show(withStatus: "Ожидание...")
        
        let email = mailField.text
        if email != "" {
            Auth.auth().sendPasswordReset(withEmail: email!, completion: { (error) in
                
                OperationQueue.main.addOperation {
                    if error != nil {
                        
                        SVProgressHUD.dismiss()
                        let alertController = UIAlertController(title: "Неизвестный адрес", message: "Пожалуйста, введите адрес электронной почты, который использовался при регистрации", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            
                            self.dismiss(animated: true, completion: nil)
                        }))
                        self.present(alertController, animated: true, completion: nil)
                        
                    } else {
                        
                        SVProgressHUD.dismiss()
                        let alertController = UIAlertController(title: "Отправка", message: "Письмо было отправлено. Пожалуйста, проверьте свою электронную почту", preferredStyle: .alert)
                        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                            
                            self.dismiss(animated: true, completion: nil)
                        }))
                        self.present(alertController, animated: true, completion: nil)
                    }
                    
                }})
        } else {
            
            SVProgressHUD.dismiss()
            let alertController = UIAlertController(title: "Ошибка!", message: "Введите свой адрес электронной почты.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                
                self.dismiss(animated: true, completion: nil)
            }))
            self.present(alertController, animated: true, completion: nil)
           
        }
    }
    
    
    @IBAction func pushAuth(_ sender: UIButton) {
        if passField.text?.isEmpty ?? true || passField.text == " " &&
            mailField.text?.isEmpty ?? true || mailField.text == " " {
            
            passField.layer.borderColor = CGColor(red: 235/255, green: 112/255, blue: 80/255, alpha: 1)
            mailField.layer.borderColor = CGColor(red: 235/255, green: 112/255, blue: 80/255, alpha: 1)
        } else {
            if mailField.text!.count > 6 && passField.text!.count > 6 {
                if Auth.auth().currentUser != nil {
                    signInUser(password: passField.text!, mail: mailField.text!)
                } else {
                    authUser(password: passField.text!, mail: mailField.text!)
                }
            }
            
        }
    }
    
    @IBAction func pushGoogleSignIn(_ sender: UIButton) {
        performGoogleSignInFlow()
    }
    
    func authUser(password: String, mail: String) {
        Auth.auth().createUser(withEmail: mail, password: password) { authResult, error in
            
            if (error != nil) {
                
            } else {
                
                UserDefaults.standard.setValue(mail, forKey: "userID")
                UserDefaults.standard.synchronize()
                UserDefaults.standard.setValue(password, forKey: "pass")
                UserDefaults.standard.synchronize()
                
                self.performSegue(withIdentifier: "toEditor", sender: self)
                
            }
        }
    }
    
    func signInUser(password: String, mail: String){
       
        Auth.auth().signIn(withEmail: mail, password: password) { [weak self] authResult, error in
//            guard self != nil else { return }
            var errorText: String
            if let x = error {
                  let err = x as NSError
                  switch err.code {
                  case AuthErrorCode.wrongPassword.rawValue:
                     errorText = "Неверный пароль"
                  case AuthErrorCode.invalidEmail.rawValue:
                      errorText = "Неверный email"
//                  case AuthErrorCode.accountExistsWithDifferentCredential.rawValue:
//                      errorText = "accountExistsWithDifferentCredential"
                  case AuthErrorCode.emailAlreadyInUse.rawValue:
                      errorText = "Аккаунт с данной почтой уже существует"
                  default:
                      errorText = "unknown error: \(err.localizedDescription)"
                  }
                
                SVProgressHUD.dismiss()
                let alertController = UIAlertController(title: "Ошибка!", message: errorText, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    
                    self?.dismiss(animated: true, completion: nil)
                }))
                self?.present(alertController, animated: true, completion: nil)
                //return
            } else {
                
                Auth.auth().currentUser?.sendEmailVerification { (error) in
                }
                self?.performSegue(withIdentifier: "toEditor", sender: self)
                
                let user = authResult?.user.email
                
                if mail == user {
                    
                    
                    UserDefaults.standard.setValue(mail, forKey: "userID")
                    UserDefaults.standard.synchronize()
                    UserDefaults.standard.setValue(password, forKey: "pass")
                    UserDefaults.standard.synchronize()
                    
                    
                    
                    self?.performSegue(withIdentifier: "toEditor", sender: self)
                    
                    
                } else {
                    self?.authUser(password: password, mail: mail)
                }
            }
        }
    }

    
    func performGoogleSignInFlow() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [unowned self] result, error in
            
            guard error == nil else {
                print("Error doing Google Sign-In, \(error)")
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString
            else {
                let error = NSError(
                    domain: "GIDSignInError",
                    code: -1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Unexpected sign in result: required authentication data is missing.",
                    ]
                )
              
                print("Error doing Google Sign-In, \(error)")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            signIn(with: credential)
        }
    }
    
    func signIn(with credential: AuthCredential) {
        
        Auth.auth().signIn(with: credential) { result, error in
            if let e = error {
                print(e.localizedDescription)
            }

            print("Signed in with Google")
            
//            self.transitionToUserViewController()
        }
    }
    
    func googleSignOut() {
        GIDSignIn.sharedInstance.signOut()
        print("Google sign out")
    }
    
}

