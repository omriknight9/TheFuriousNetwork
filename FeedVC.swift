
import UIKit
import SwiftKeychainWrapper
import Firebase

class FeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!;
    @IBOutlet weak var capitonField: FancyField!;
    @IBOutlet weak var imageAdd: CircleView!;
    
    
    
    var posts = [Post]();
    var imagePicker: UIImagePickerController!;
    static var imageCache: NSCache<NSString, UIImage> = NSCache();
    var imgSelected = false;
    

    override func viewDidLoad() {
        super.viewDidLoad();
        tableView.delegate = self;
        tableView.dataSource = self;
        
        imagePicker = UIImagePickerController();
        imagePicker.allowsEditing = true;
        imagePicker.delegate = self;
        
        DataService.ds.REF_POSTS.observe(.value, with: { (snapshot) in
            if let snapshot = snapshot.children.allObjects as? [FIRDataSnapshot] {
                for snap in snapshot {
                    print("SNAP: \(snap)");
                    if let postDict = snap.value as? Dictionary <String, AnyObject> {
                        let key = snap.key;
                        let post = Post(postKey: key, postData: postDict);
                        self.posts.append(post);
                    }
                }
            }
            self.tableView.reloadData();
        })
        
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let post = posts[indexPath.row];
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell") as? PostCell {
            
            if let img = FeedVC.imageCache.object(forKey: post.imageUrl as NSString) {
                cell.configureCell(post: post, img: img);
            }else {
                cell.configureCell(post: post, img: nil);
            }
            return cell;
        }else {
            return PostCell();
        }
       
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            imageAdd.image = image;
            imgSelected = true;
        }else {
            print("OMRI: A valid image wasn't selected");
        }
        imagePicker.dismiss(animated: true, completion: nil);
    }
    
    @IBAction func addImageTapped(_ sender: AnyObject) {
        
        present(imagePicker, animated: true, completion: nil);
    }
    
    
    @IBAction func postBtnTapped(_ sender: AnyObject) {
        guard let caption = capitonField.text, caption != "" else {
            let txtAlert = UIAlertController(title: "Alert!", message: "Caption must be entered", preferredStyle: UIAlertControllerStyle.alert);
            txtAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            self.present(txtAlert, animated: true, completion: nil);
            capitonField.layer.borderColor = UIColor.red.cgColor;
            
            print("OMRI: Caption must be entered");
            return
            
        }
        guard let img = imageAdd.image, imgSelected == true else {
            let imgAlert = UIAlertController(title: "Alert!", message: "An img must be selected", preferredStyle: UIAlertControllerStyle.alert);
            imgAlert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil));
            self.present(imgAlert, animated: true, completion: nil);
    
            print("OMRI: An image must be selected");
            
            return
        }
        
        if let imgData = UIImageJPEGRepresentation(img, 0.2) {
            
            let imgUid = NSUUID().uuidString;
            let metadata = FIRStorageMetadata();
            metadata.contentType = "image/jpeg";
            
            DataService.ds.REF_POST_IMAGES.child(imgUid).put(imgData, metadata: metadata) { (metadata, error) in
                if error != nil {
                    print("OMRI: Unable to upload image to Firebase storage");
                }else {
                    print("OMRI: Successfully uploaded image to Firebase storage");
                    let downloadURL = metadata?.downloadURL()?.absoluteString;
                    if let url = downloadURL {
                        self.postToFirebase(imgUrl: url);
                        
                    }
                    
                }
                self.capitonField.layer.borderColor = UIColor.white.cgColor;
                
            }
        }
    }
    
    func postToFirebase(imgUrl: String) {
        let post: Dictionary<String, AnyObject> = [
            "caption": capitonField.text! as AnyObject,
            "imageUrl": imgUrl as AnyObject,
            "likes": 0 as AnyObject
        ]
        
        let firebasePost = DataService.ds.REF_POSTS.childByAutoId();
        firebasePost.setValue(post);
        
        capitonField.text = "";
        imgSelected = false;
        imageAdd.image = UIImage(named: "Camera");
        
        tableView.reloadData();
    }

    @IBAction func signInOutTapped(_ sender: AnyObject) {
        let keychainResult = KeychainWrapper.standard.removeObject(forKey: KEY_UID);
        print("OMRI: ID removed from keychain \(keychainResult)");
        try! FIRAuth.auth()?.signOut()
        
        performSegue(withIdentifier: "goToSignIn", sender: nil);
    }
}
