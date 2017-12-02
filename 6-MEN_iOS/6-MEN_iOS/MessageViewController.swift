//
//  MessageViewController.swift
//  6-MEN_iOS
//
//  Created by 横田 貴之 on 2017/12/03.
//  Copyright © 2017年 横田 貴之. All rights reserved.
//

import UIKit

class MessageViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        textView.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func backgroundAction(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
    
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        
        let urlString = "https://7c3uy6hf0h.execute-api.ap-northeast-1.amazonaws.com/prod/app/wear-need/message"
        
        let request = NSMutableURLRequest(url: URL(string: urlString)!)
        
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params:[String:Any] = [
            "user_id": "aaaaaa",
            "send_user_id": "bbbbbb",
            "message" : textView.text
        ]
        
        do{
            request.httpBody = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            
            let task:URLSessionDataTask = URLSession.shared.dataTask(with: request as URLRequest, completionHandler: {(data,response,error) -> Void in
                let resultData = String(data: data!, encoding: .utf8)!
                print("result:\(resultData)")
                print("response:\(String(describing: response))")
                
            })
            task.resume()
        }catch{
            print("Error:\(error)")
            return
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
