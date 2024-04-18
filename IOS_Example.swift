/*
**iOS Swift**
build a native app that captures video & audio from the camera
adds mustache to the user' face using ARKit
user should be able to change mustache style on the fly (embed a few mustache images)
session video/duration should be saved into ORM


Video screen
recordings button (leads to Recording screen)
Mustaches list. On tap currently selected mustaches get replaced
Stop button. It stops recording and presenting a popup to a user. A popup contains a ‘tag’ text field. Once the user enters a ‘tag’, data gets saved(video / duration / ‘tag’) into ORM or DB


Recording list screen
A grid of the recordings
Each row in the grid includes:
Preview for a video
video duration
Tag
New recording button(leads to the Video screen)


Nice to have:
Editing a tag on Recording list screen
*/


import ARKit
import AVFoundation
import CoreData 
import UIKit
class VideoViewController: UIViewController, ARSCNViewDelegate {
    var sceneView: ARSCNView!
    var mustacheNode: SCNNode!
    var mustacheImages: [UIImage]!
    var currentMustacheIndex: Int = 0
    var videoOutput: AVCaptureVideoDataOutput!
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initialize ARSCNView
        sceneView = ARSCNView(frame: view.frame)
        view.addSubview(sceneView)
        // Set the delegate to self
        sceneView.delegate = self
        // Initialize AVCaptureSession
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("Failed to get the camera device")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Add the input to the session
            captureSession?.addInput(input)
            
            // Initialize AVCaptureVideoPreviewLayer and add it to the view
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            view.layer.addSublayer(videoPreviewLayer!)
            
            // Start video capture
            captureSession?.startRunning()
            
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        // Load mustache images
        mustacheImages = [UIImage(named: "mustache1"), UIImage(named: "mustache2"), UIImage(named: "mustache3")]
    }

    func startRecording() {
        // Start AR session
        let configuration = ARFaceTrackingConfiguration()
        sceneView.session.run(configuration)

        // Start video capture
        captureSession?.startRunning()

        // Add mustache node to ARSCNView
        sceneView.scene.rootNode.addChildNode(mustacheNode)
    }
    func stopRecording() {
    // Stop AR session
    sceneView.session.pause()

    // Stop video capture
    captureSession?.stopRunning()

    // Present popup for user to enter a tag
    let alertController = UIAlertController(title: "Enter Tag", message: "", preferredStyle: .alert)
    alertController.addTextField { (textField) in
        textField.placeholder = "Tag"
    }
    let saveAction = UIAlertAction(title: "Save", style: .default) { [unowned alertController] _ in
        let tag = alertController.textFields![0].text
        // Save video, duration, and tag to ORM
        let video = Video()
        video.tag = tag
        // Set video and duration properties
        let videoData = NSData() 
        video.videoData = videoData
        let duration = 0.0 // Replace this with your actual video duration
        video.duration = duration
        // Save video object to ORM
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext

        do {
            try context.save()
        } catch {
            print("Failed saving")
        }
    }
    alertController.addAction(saveAction)
    present(alertController, animated: true)

    // Save video, duration, and tag to ORM
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let context = appDelegate.persistentContainer.viewContext

    let entity = NSEntityDescription.entity(forEntityName: "Video", in: context)
    let newVideo = NSManagedObject(entity: entity!, insertInto: context)

    newVideo.setValue(videoData, forKey: "videoData") // videoData is your NSData object
    newVideo.setValue(duration, forKey: "duration") // duration is a Double or Int
    newVideo.setValue(tag, forKey: "tag") // tag is a String

    do {
        try context.save()
    } catch {
        print("Failed saving")
    }

}

    func switchMustache() {
        // Remove current mustache node from ARSCNView
        mustacheNode.removeFromParentNode()

        // Increment currentMustacheIndex
        currentMustacheIndex += 1

        // If currentMustacheIndex is out of bounds, reset it to 0
        if currentMustacheIndex >= mustacheImages.count {
            currentMustacheIndex = 0
        }

        // Create new mustache node with the next mustache image
        let mustacheImage = mustacheImages[currentMustacheIndex]
        let mustacheGeometry = SCNPlane(width: 0.1, height: 0.1) // Adjust width and height as needed
        mustacheGeometry.firstMaterial?.diffuse.contents = mustacheImage
        mustacheNode = SCNNode(geometry: mustacheGeometry)

        // Add new mustache node to ARSCNView
        sceneView.scene.rootNode.addChildNode(mustacheNode)
    }

}



class RecordingsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    var collectionView: UICollectionView!
    var recordings: [Recording]! // Recording is a custom model class

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize UICollectionView
        let layout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        view.addSubview(collectionView)

        // Fetch recordings from ORM
        // Assuming you have a method in your ORM to fetch all recordings
        recordings = ORM.shared.fetchRecordings()
    }


    func fetchRecordings() {
        // Fetch recordings from ORM
        recordings = ORM.shared.fetchRecordings()

        // Reload collection view
        collectionView.reloadData()
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recordings.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Dequeue a cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)

        // Get the recording for this index
        let recording = recordings[indexPath.row]

        // Configure the cell
        cell.configure(with: recording)

        return cell
    }

}
