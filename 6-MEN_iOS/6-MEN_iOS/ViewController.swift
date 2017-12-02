//
//  ViewController.swift
//  6-MEN_iOS
//
//  Created by 横田 貴之 on 2017/12/02.
//  Copyright © 2017年 横田 貴之. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation
import MapKit

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralManagerDelegate, UITextFieldDelegate, CBPeripheralDelegate, CLLocationManagerDelegate, MKMapViewDelegate {
    var myLocationManager = CLLocationManager()
    
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var peripheralManager: CBPeripheralManager!
    
    var peripherals = Dictionary<String,CBPeripheral>()
    var peripheralRSSIs = Dictionary<CBPeripheral,NSNumber>()
    
    var isMyLocation = false
    
    @IBOutlet weak var myMapView: MKMapView!
    @IBOutlet weak var screenView: UIView!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var usersView: UIView!
    @IBOutlet weak var userImage1: UIButton!
    @IBOutlet weak var userImage2: UIButton!
    @IBOutlet weak var userImage3: UIButton!
    @IBOutlet weak var userImage4: UIButton!
    @IBOutlet weak var userImage5: UIButton!
    @IBOutlet weak var userImage6: UIButton!

    @IBOutlet weak var targetUserImage: UIButton!
    @IBOutlet weak var targetUserProfile: UIButton!
    @IBOutlet weak var targetUserMessage: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        // Do any additional setup after loading the view, typically from a nib.
    
        self.myLocationManager = CLLocationManager() // インスタンスの生成
        self.myLocationManager.delegate = self
        self.myMapView.delegate = self
        
        //セキュリティ認証のステータスを取得
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.notDetermined {
            // まだ承認が得られていない場合は、認証ダイアログを表示
            myLocationManager.requestAlwaysAuthorization()
        }
        //現在地取得の開始
        myLocationManager.startUpdatingLocation()
    }
    
    // GPSから値を取得した際に呼び出されるメソッド
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if isMyLocation {return}
        
        // 配列から現在座標を取得（配列locationsの中から最新のものを取得する）
        let myLocation = locations.last! as CLLocation
        //Pinに表示するためにはCLLocationCoordinate2Dに変換してあげる必要がある
        let currentLocation = myLocation.coordinate
//        //ピンの生成と配置
//        let pin = MKPointAnnotation()
//        pin.coordinate = currentLocation
//        pin.title = "現在地"
//        self.myMapView.addAnnotation(pin)
        
        //アプリ起動時の表示領域の設定
        //delta数字を大きくすると表示領域も広がる。数字を小さくするとより詳細な地図が得られる。
        let mySpan = MKCoordinateSpan(latitudeDelta: 0.0, longitudeDelta: 0.0)
        let myRegion = MKCoordinateRegionMake(currentLocation, mySpan) 
        myMapView.region = myRegion
        
        isMyLocation = true
    }
    
    //GPSの取得に失敗したときの処理
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            // アプリケーションに関してまだ選択されていない
            self.myLocationManager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            print("位置情報取得(起動時のみ)が許可されました")
            break
        case .denied:
            print("位置情報取得が拒否されました")
            break
        case .restricted:
            break
        case .authorizedAlways:
            break
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //  接続状況が変わるたびに呼ばれる
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print ("state: \(central.state)")
    }
    
    //  スキャン開始
    @IBAction func startScan(_ sender: UIButton) {
        
        screenView.isHidden = !screenView.isHidden
        usersView.isHidden = !usersView.isHidden
        
        if usersView.isHidden {
            targetUserImage.isHidden = true
            targetUserProfile.isHidden = true
            targetUserMessage.isHidden = true
        }
        
        
        //  2.3
        //  centralManager.scanForPeripheralsWithServices(nil, options: nil)
        centralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    //  スキャン結果を取得
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let id = peripheral.identifier.description
        self.peripherals[id] = peripheral
        self.centralManager.connect(peripheral, options: nil)
    }
    
    //  スキャン終了
    @IBAction func stopScan(_ sender: UIButton) {
        centralManager.stopScan()
    }
    
    
    //  接続成功時に呼ばれる
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate=self
        peripheral.readRSSI()
        print("Connect success!")
        
    }
    
    //  接続失敗時に呼ばれる
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let id = peripheral.identifier.description
        peripherals.removeValue(forKey: id)
        print("Connect failed...")
    }
    @IBAction func sendMessage(_ sender: UIButton) {
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
    
    //  ペリフェラルのStatusが変化した時に呼ばれる
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        print("periState\(peripheral.state)")
    }
    @IBAction func startAdvertite(_ sender: UIButton) {
        let advertisementData = [CBAdvertisementDataLocalNameKey: "Test Device"]
        let serviceUUID = CBUUID(string: "0000")
        let service = CBMutableService(type: serviceUUID, primary: true)
        let charactericUUID = CBUUID(string: "0001")
        let characteristic = CBMutableCharacteristic(type: charactericUUID, properties: CBCharacteristicProperties.read, value: nil, permissions: CBAttributePermissions.readable)
        service.characteristics = [characteristic]
        self.peripheralManager.add(service)
        peripheralManager.startAdvertising(advertisementData)
    }
    
    //  サービス追加結果の取得
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if error != nil {
            print("Service Add Failed...")
            return
        }
        print("Service Add Sucsess!")
    }
    
    //  アドバタイズ開始処理の結果を取得
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print(error)
            print("***Advertising ERROR")
            return
        }
        print("Advertising success")
    }
    
    //  アドバタイズ終了
    @IBAction func stopArvertisement(_ sender: UIButton) {
        peripheralManager.stopAdvertising()
    }
    
    //  service検索開始
    @IBAction func getService(_ sender: UIButton) {
//        peripheral.delegate = self
//        peripheral.discoverServices(nil)
    }
    
    //  service検索結果取得
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else{
            print("error")
            return
        }
        print("\(services.count)個のサービスを発見。\(services)")
        
        //  サービスを見つけたらすぐにキャラクタリスティックを取得
        for obj in services {
            peripheral.discoverCharacteristics(nil, for: obj)
        }
    }
    
    //  キャラクタリスティック検索結果取得
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            print("\(characteristics.count)個のキャラクタリスティックを発見。\(characteristics)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("RSSI: " + String(describing: RSSI))
        if (error != nil) {
            print(error ?? "aaa")
        } else {
            self.peripheralRSSIs[peripheral]=RSSI
        }
        
        if (self.peripheralRSSIs.count >= 1) {
            self.userImage1.isHidden = false
        } else {
            self.userImage1.isHidden = true
        }
        if (self.peripheralRSSIs.count >= 2) {
            self.userImage2.isHidden = false
        } else {
            self.userImage2.isHidden = true
        }
        if (self.peripheralRSSIs.count >= 3) {
            self.userImage3.isHidden = false
        } else {
            self.userImage3.isHidden = true
        }
        if (self.peripheralRSSIs.count >= 4) {
            self.userImage4.isHidden = false
        } else {
            self.userImage4.isHidden = true
        }
        if (self.peripheralRSSIs.count >= 5) {
            self.userImage5.isHidden = false
        } else {
            self.userImage5.isHidden = true
        }
        if (self.peripheralRSSIs.count >= 6) {
            self.userImage6.isHidden = false
        } else {
            self.userImage6.isHidden = true
        }
        
        var index = 1
        self.textView.text = ""
        for (key,val) in self.peripheralRSSIs {
//            print("val: " + String(describing: val))
//            let per = CGFloat(100.0 - Float(abs(Int32(truncating: val)))) / 100.0 + 0.1
//            print("val: " + String(describing: per))
//            if (index == 1) {
//                self.userImage1.alpha = per
//            }
//            if (index == 2) {
//                self.userImage2.alpha = per
//            }
//            if (index == 3) {
//                self.userImage3.alpha = per
//            }
//            if (index == 4) {
//                self.userImage4.alpha = per
//            }
//            if (index == 5) {
//                self.userImage5.alpha = per
//            }
//            if (index == 6) {
//                self.userImage6.alpha = per
//            }
            self.textView.text.append("\(String(describing: key.name)) truncating: : \(abs(Int32(truncating: val))) \n")
            index = index + 1
        }
    }
    
    @IBAction func pushUserIcon(_ sender: Any) {
        targetUserImage.isHidden = !targetUserImage.isHidden
        targetUserProfile.isHidden = !targetUserProfile.isHidden
        targetUserMessage.isHidden = !targetUserMessage.isHidden
        
    }
    
    @IBAction func pushMessageIcon(_ sender: Any) {
        
        let storyboard: UIStoryboard = self.storyboard!
        let vc = storyboard.instantiateViewController(withIdentifier: "MessageViewController")
        vc.modalPresentationStyle = .overCurrentContext
        vc.view.backgroundColor = UIColor.clear
        present(vc, animated: true, completion: nil)
        
    }
    
}
