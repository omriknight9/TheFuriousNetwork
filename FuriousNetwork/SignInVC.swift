

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Firebase
import SwiftKeychainWrapper

class SignInVC: UIViewController {
    
    
    @IBOutlet weak var emailField: FancyField!;
    @IBOutlet weak var pwdField: FancyField!;

    override func viewDidLoad() {
        super.viewDidLoad();
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let _ = KeychainWrapper.standard.string(forKey: KEY_UID) {
            print("OMRI: ID found in keychain");
            performSegue(withIdentifier: "goToFeed", sender: nil);
        }
    }

    @IBAction func facebookBtnTapped(_ sender: AnyObject) {
        
        let facebookLogin = FBSDKLoginManager();
        
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                
                let facebookAlert = UIAlertController(title: "Alert!", message: "Unable to authenticate with Facebook", preferredStyle: UIAlertControllerStyle.alert);
                facebookAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
                self.present(facebookAlert, animated: true, completion: nil);

                
                print("OMRI: Unable to authenticate with Facebook - \(error)");
            }else if result?.isCancelled == true {
                print("OMRI: User cancelled Facbook authentication");
            }else {
                print("OMRI: Successfully authenticated with Facebook");
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString);
                self.firebaseAuth(credential);
            }
        }
        
    }
    
    func firebaseAuth(_ credential: FIRAuthCredential) {
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            if error != nil {

                print("OMRI: Unable to authenthcate with Firebase - \(error)");
            }else {
                print("OMRI: Successfully authenticated with Firebase");
                if let user = user {
                    let userData = ["provider": credential.provider];
                    self.completeSignIn(id: user.uid, userData: userData);
                    
                }
                
            }
        })
    }

    @IBAction func signInTapped(_ sender: AnyObject) {
        if let email = emailField.text, let pwd = pwdField.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: pwd, completion: { (user, error) in
                if error == nil {
                    print("OMRI: Email user authenticated with Firebase");
                    if let user = user {
                        let userData = ["provider": user.providerID];
                        self.completeSignIn(id: user.uid, userData: userData);
                    }
                    
                } else {
                    FIRAuth.auth()?.createUser(withEmail: email, password: pwd, completion: { (user, error) in
                        if error != nil {
                            
                            let firebaseAlert = UIAlertController(title: "Unable to authenthcate with Firebase.", message: "1. Your password needs to have at least 6 characters. 2. The email must be valid.", preferredStyle: UIAlertControllerStyle.alert);
                            firebaseAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
                            self.present(firebaseAlert, animated: true, completion: nil);
                            
                            print("OMRI: Unable to authenticate with Firebase using email");
                        } else {
                            print("OMRI: Successfully authenticated with Firebase");
                            if let user = user {
                                let userData = ["provider": user.providerID]
                                self.completeSignIn(id: user.uid, userData: userData);
                            }
                            
                        }
                    })
                }
            })
        }
    }
    
    func completeSignIn(id: String, userData: Dictionary<String, String>) {
        DataService.ds.createFirebaseDBUser(uid: id, userData: userData);
        let keychainResult = KeychainWrapper.standard.set(id, forKey: KEY_UID);
        print("OMRI: data saved to keychain \(keychainResult)");
        performSegue(withIdentifier: "goToFeed", sender: nil);
    }
}

