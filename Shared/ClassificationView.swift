//
//  ClassificationView.swift
//  Images
//
//  Created by Jakub Charvat on 22.11.2020.
//

import SwiftUI
import Combine


struct ClassificationView: View {
    @StateObject private var data = ContentViewData()
    @EnvironmentObject var keystrokes: Keystrokes
    @Environment(\.undoManager) var undoManager
    @Namespace private var namespace
    
    //MARK: - Body
    var body: some View {
        Group {
            if let bigImage = data.bigImage, let smajlik = data.smajlikImage {
                HStack(spacing: 0) {
                    VStack(spacing: 0) {
                        BadgedText("\(data.smajlikCount)", badge: ":)")
                        BadgedText("\(data.mracounCount)", badge: ":(")
                            .mainBackgroundColor(.purple)
                            .badgeBackgroundColor(.red)
                        Spacer()
                        
                        if !data.a {
                            imageView(smajlik)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(8)
                                .matchedGeometryEffect(id: "smajlik", in: namespace)
                                .padding(.horizontal)
                        }
                        
                        imageView(bigImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                            .padding()
                    }
                    .frame(width: 100)
                    .background(BlurView().edgesIgnoringSafeArea(.top))
                    
                    ZStack {
                        imageView(smajlik)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .edgesIgnoringSafeArea(.top)
                        
                        if data.a {
                            imageView(smajlik)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .edgesIgnoringSafeArea(.top)
                                .matchedGeometryEffect(id: "smajlik", in: namespace)
                        }
                    }
                }
            } else {
                Text("no image")
                    .frame(minWidth: 300, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
                    .background(BlurView().edgesIgnoringSafeArea(.all))
            }
        }
        .onAppear {
            data.setup(keystrokes: keystrokes, undoManager: undoManager)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                data.animate()
            }
        }
    }
    
    
    //MARK: - Image View
    @ViewBuilder
    func imageView(_ image: SystemImage) -> Image {
        #if os(macOS)
        Image(nsImage: image)
        #else
        Image(uiImage: bigImage)
        #endif
    }
}


//MARK: - Data
class ContentViewData: ObservableObject {
    @Published var bigImage: SystemImage?
    @Published var smajlikImage: SystemImage?
    @Published private var smajlici = [NSImage]()
    @Published private var mracouni = [NSImage]()
    
    var smajlikCount: Int { smajlici.count }
    var mracounCount: Int { mracouni.count }
    
    @Published var a = false
    
    private let fm = FileManager.default
    private let dir = URL(fileURLWithPath: "/Users/jakcharvat/Downloads/input/")
    
    private var smajlikQueue = LazyQueue<NSImage>()
    private var cancellable: AnyCancellable?
    private var keystrokes: Keystrokes?
    private var undoManager: UndoManager?
}


//MARK: - Setup
extension ContentViewData {
    func setup(keystrokes: Keystrokes, undoManager: UndoManager?) {
        cancellable = keystrokes.publisher
            .sink { [unowned self] key in
                switch key {
                case .s: markSmajlik()
                case .m: markMracoun()
                }
            }
        
        self.keystrokes = keystrokes
        self.undoManager = undoManager
        
        smajlikQueue.getNextItems = getSmajliky
//        smajlikQueue.noNextItems =
        
        showNextSmajlik()
    }
}


//MARK: - Animate
extension ContentViewData {
    func animate() {
        withAnimation {
            a.toggle()
        }
    }
}
    

//MARK: - Get Smajliky
extension ContentViewData {
    func getSmajliky() -> [NSImage] {
        do {
            guard let bigImage = try loadImage() else { throw ImageError.outOfImages }
            self.bigImage = bigImage
            let croppedImages = try ImageTools.createCroppedImages(from: bigImage)
            return croppedImages
        } catch {
            print("Error: \(error)")
            return []
        }
    }
}

    
//MARK: - Load Image
extension ContentViewData {
    func loadImage() throws -> SystemImage? {
        let images = try fm.contentsOfDirectory(atPath: dir.path)
            .filter { $0.lowercased().hasSuffix(".pbm") || $0.hasSuffix(".jpeg") }
            .sorted()
        guard let imgName = images.first else { return nil }
        let imageURL = dir.appendingPathComponent(imgName)
        
        guard let image = SystemImage(contentsOf: imageURL) else { return nil }
        let targetDir = dir.appendingPathComponent("loaded")
        let targetImageURL = targetDir.appendingPathComponent(imgName)
        if !fm.fileExists(atPath: targetDir.path) {
            try fm.createDirectory(at: targetDir, withIntermediateDirectories: true, attributes: nil)
        }
        try fm.moveItem(at: imageURL, to: targetImageURL)
        return image
    }
}

    
//MARK: - Show Next Smajlik
extension ContentViewData {
    func showNextSmajlik() {
        guard let smajlik = smajlikQueue.dequeueFirst() else { return }
        smajlikImage = smajlik
        keystrokes?.enabled = true
    }
}


//MARK: - Image Classification
extension ContentViewData {
    func markSmajlik() {
        guard let smajlik = smajlikImage else { return }
        smajlici.append(smajlik)
        showNextSmajlik()
        
        save(smajlik: smajlik, to: dir.appendingPathComponent("smajlici"))
    }
    
    
    func markMracoun() {
        guard let smajlik = smajlikImage else { return }
        mracouni.append(smajlik)
        showNextSmajlik()
        
        save(smajlik: smajlik, to: dir.appendingPathComponent("mracouni"))
    }
    
    
    private func save(smajlik: NSImage, to dir: URL) {
        do {
            let imageName = try ImageTools.getNextFileName(in: dir)
            try ImageTools.saveImage(smajlik, at: dir, named: imageName)
        } catch {
            print("Error: \(error)")
        }
    }
}

//        undoManager?.registerUndo(withTarget: self) { target in
//            if let smajlikImage = target.smajlikImage { target.smajlikQueue.shoveToFirstPlace(smajlikImage) }
//            target.smajlikImage = smajlik
//        }


//MARK: - Previews
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ClassificationView()
            .environmentObject(Keystrokes())
    }
}
