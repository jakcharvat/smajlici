//
//  ContentView.swift
//  Predictions
//
//  Created by Jakub Charvat on 24.11.2020.
//

import SwiftUI
import UniformTypeIdentifiers
import CoreML
import SWCompression

struct ContentView: View {
    @StateObject private var data = ContentViewData()
    @State private var hasStarted = false
    
    var body: some View {
        Group {
            if !hasStarted {
                Button("Start") {
                    DispatchQueue.global().async {
                        data.runPredictions()
                    }
                    hasStarted = true
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if data.smajlici.isEmpty {
                Text("Predicting...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical) {
                    HStack(spacing: 0) {
                        Spacer(minLength: 4)
                        VStack {
                            ItemsGrid(sets: $data.smajlici, itemsFilter: { $0.isSmajlik })
                            Divider()
                                .padding(20)
                            ItemsGrid(sets: $data.smajlici, itemsFilter: { !$0.isSmajlik })
                            Button("Save") {
                                data.save()
                            }
                        }
                        Spacer(minLength: 4)
                    }
                    .padding(.vertical)
                }
            }
        }
        .background(BlurView().edgesIgnoringSafeArea(.all))
    }
}


struct ItemsGrid: View {
    @Binding var sets: [ItemSet]
    let itemsFilter: (Item) -> Bool
    
    let itemsAcross = 6
    
    var body: some View {
        ForEach(rows, id: \.first!.id) { row in
            HStack {
                ForEach(row, id: \.id) { item in
                    Image(nsImage: item.image)
                        .cornerRadius(6)
                        .onTapGesture {
                            sets[item.setIdx].rows[item.rowIdx].items[item.itemIdx].isSmajlik.toggle()
                            sets[item.setIdx].rows[item.rowIdx].items[item.itemIdx].moved = true
                        }
                        .padding(4)
                        .opacity(item.moved ? 0.7 : 1)
                        .overlay(Color.gray.opacity(item.moved ? 0.3 : 0))
                }
                
                if row.count < itemsAcross {
                    ForEach(0 ..< itemsAcross - row.count, id: \.self) { _ in
                        Spacer().frame(width: 120, height: 120).padding(4)
                    }
                }
            }
        }
    }
    
    
    var rows: [[Item]] {
        let flat = sets.flatMap({ $0.rows.flatMap({ $0.items }) })
        let filtered = flat.filter(itemsFilter)
        let chunked = filtered.chunked(into: itemsAcross)
        return chunked
    }
}


//MARK: - Item
struct Item: Identifiable {
    let id = UUID()
    let image: NSImage
    var isSmajlik: Bool
    var moved: Bool = false
    let setIdx: Int
    let rowIdx: Int
    let itemIdx: Int
    
    var smajlik: String {
        isSmajlik ? ":)" : ":("
    }
}


//MARK: - ItemRow
struct ItemRow: Identifiable {
    let id = UUID()
    var items: [Item]
}


//MARK: - Set
struct ItemSet: Identifiable {
    let id = UUID()
    let name: String
    var rows: [ItemRow]
}


//MARK: - Data
class ContentViewData: ObservableObject {
    @Published var inputAccessible = false
    @Published var outputText = ""
    @Published var smajlici: [ItemSet] = []
    
    let fm = FileManager.default
    let dir = URL(fileURLWithPath: "/Users/jakcharvat/Desktop/input")
    let smajlik = ":)"
    let mracoun = ":("
    
    
    init() {
        checkInputAccessible()
    }
    
    
    func checkInputAccessible() {
        inputAccessible = fm.fileExists(atPath: dir.path)
    }
    
    
    func unzip() throws -> [TarEntry] {
        let txt = try Data(contentsOf: URL(fileURLWithPath: "/Users/jakcharvat/Downloads/input.txt"))
        let tar = try GzipArchive.unarchive(archive: txt)
        let folder = try TarContainer.open(container: tar)
        return folder
    }
    
    func runPredictions() {
        do {
            let entries = try unzip()
            
            let config = MLModelConfiguration()
            let model = try Smajlici(configuration: config)
            
            var sets = [String : ItemSet]()
            DispatchQueue.concurrentPerform(iterations: entries.count) { imgIdx in
                do {
                    let entry = entries[imgIdx]
                    let imgName = entry.info.name.replacingOccurrences(of: "input/", with: "")
                    if !imgName.hasSuffix(".pbm") { return }
                    let img = NSImage(data: entry.data!)!
                    
                    let setIdx = Int(imgName.replacingOccurrences(of: ".pbm", with: ""))!
                    
//                    guard let img = NSImage(contentsOf: dir.appendingPathComponent(imgName)) else { throw ImgError.cantOpenImage }
                    let smajlici = try ImageTools.createCroppedImages(from: img)
                    
                    var rows = [ItemRow]()
                    var lastRow = [Item]()
                    for (idx, smajlikImg) in smajlici.enumerated() {
                        var rect = CGRect(origin: .zero, size: smajlikImg.size)
                        guard let cgImg = smajlikImg.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { throw ImgError.cantMakeCGImage }
                        let input = try SmajliciInput(imageWith: cgImg)
                        let prediction = try model.prediction(input: input)
                        let isSmajlik = prediction.classLabel == "smajlik"
                        
                        let item = Item(image: smajlikImg, isSmajlik: isSmajlik, setIdx: setIdx, rowIdx: Int(floor(Double(idx) / 4)), itemIdx: idx % 4)
                        lastRow.append(item)
                        if idx % 4 == 3 {
                            rows.append(ItemRow(items: lastRow))
                            lastRow = []
                        }
                    }
                    
                    let set = ItemSet(name: imgName, rows: rows)
//                    DispatchQueue.main.async {
                    sets[imgName] = set
//                    }
                } catch {
                    print("Error: \(error)")
                }
            }
            
            DispatchQueue.main.async { [unowned self] in
                smajlici = sets.sorted(by: { $0.key < $1.key }).map(\.value)
            }
        } catch {
            print("Execution error: \(error)")
            outputText = "Error"
        }
    }
    
    
    func save() {
        do {
            let output = smajlici.map({ set -> String in
                let rows = set.rows.map({ row -> String in
                    let row = row.items.map(\.smajlik)
                    return row.joined(separator: " ")
                })
                
                return "\(set.name)\n\(rows.joined(separator: "\n"))"
            }).joined(separator: "\n")
            try output.write(to: URL(fileURLWithPath: "/Users/jakcharvat/Desktop").appendingPathComponent("output.txt"), atomically: false, encoding: .utf8)
        } catch {
            print("Error: \(error)")
        }
    }
}


//MARK: - Error
enum ImgError: Error {
    case cantOpenImage
    case cantMakeCGImage
}


//MARK: - Prediction Editor
struct PredictionTextEditor: View {
    @Binding var text: String
    
    var body: some View {
        TextEditor(text: $text)
            .padding(4)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding()
    }
}


//MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
